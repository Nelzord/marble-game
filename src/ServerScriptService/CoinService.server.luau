-- CoinService: spawns and manages collectible coins with persistence

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local MAX_COINS = 20
local SPAWN_INTERVAL = 10 -- seconds
local DESPAWN_AFTER = 120 -- seconds

local COIN_DEBUG = false
local function clog(...)
	if COIN_DEBUG then
		print("[CoinService]", ...)
	end
end

clog("initializing...")

-- Create/fetch remotes
local function getOrCreateRemotes()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	local function ensureEvent(name: string)
		local evt = folder:FindFirstChild(name)
		if not evt then
			evt = Instance.new("RemoteEvent")
			evt.Name = name
			evt.Parent = folder
		end
		return evt :: RemoteEvent
	end
	return {
		CoinCountUpdate = ensureEvent("CoinCountUpdate"),
	}
end

local Remotes = getOrCreateRemotes()

-- Persistence
local coinsStore = DataStoreService:GetDataStore("MarbleCoins")
local playerCoins: { [Player]: number } = {}

local function getCoins(player: Player): number
	return playerCoins[player] or 0
end

local function sendCoins(player: Player)
	Remotes.CoinCountUpdate:FireClient(player, getCoins(player))
end

local function setCoins(player: Player, amount: number)
	playerCoins[player] = amount
	sendCoins(player)
	-- Save async
	task.spawn(function()
		pcall(function()
			coinsStore:SetAsync("coins_" .. player.UserId, amount)
		end)
	end)
end

local function addCoins(player: Player, delta: number)
	setCoins(player, math.max(0, getCoins(player) + delta))
end

Players.PlayerAdded:Connect(function(player)
	local amount = 0
	local ok, err = pcall(function()
		amount = coinsStore:GetAsync("coins_" .. player.UserId) or 0
	end)
	if not ok then
		warn("[CoinService] DataStore GetAsync failed:", err)
	end
	playerCoins[player] = tonumber(amount) or 0
	sendCoins(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local amount = getCoins(player)
	local ok, err = pcall(function()
		coinsStore:SetAsync("coins_" .. player.UserId, amount)
	end)
	if not ok then
		warn("[CoinService] DataStore SetAsync failed:", err)
	end
	playerCoins[player] = nil
end)

-- Coin spawning & movement
export type CoinInfo = {
	model: Model,
	root: BasePart,
	spawnTime: number,
	basePos: Vector3,
	phase: number,
}

local activeCoins: { CoinInfo } = {}

local function getBaseplateBounds()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		local size = baseplate.Size
		local pos = baseplate.Position
		return pos, size
	end
	-- Fallback bounds
	return Vector3.new(0, 0, 0), Vector3.new(256, 1, 256)
end

local function randomSpawnOverBase(): Vector3
	local center, size = getBaseplateBounds()
	local rx = (math.random() - 0.5) * (size.X - 6)
	local rz = (math.random() - 0.5) * (size.Z - 6)
	return Vector3.new(center.X + rx, center.Y + 5, center.Z + rz)
end

local function createCoin(): CoinInfo
	local coin = Instance.new("Model")
	coin.Name = "Coin"
	coin.Parent = workspace

	local root = Instance.new("Part")
	root.Name = "CoinRoot"
	root.Shape = Enum.PartType.Cylinder
	root.Size = Vector3.new(0.5, 3, 3)
	root.Color = Color3.fromRGB(255, 215, 0)
	root.Material = Enum.Material.Metal
	root.Anchored = true
	root.CanCollide = false
	root.Parent = coin

	local basePos = randomSpawnOverBase()
	coin:PivotTo(CFrame.new(basePos))

	-- Touch collect sensor (anchored, invisible)
	local sensor = Instance.new("Part")
	sensor.Name = "CoinSensor"
	sensor.Size = Vector3.new(4,4,4)
	sensor.Transparency = 1
	sensor.CanCollide = false
	sensor.Anchored = true
	sensor.CFrame = CFrame.new(basePos)
	sensor.Parent = coin

	sensor.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		if not model then return end
		local player = Players:GetPlayerFromCharacter(model)
		if not player then return end
		addCoins(player, 1)
		clog(string.format("Collected by %s at (%.1f, %.1f, %.1f)", player.Name, basePos.X, basePos.Y, basePos.Z))
		for i = #activeCoins, 1, -1 do
			local info = activeCoins[i]
			if info.model == coin then
				coin:Destroy()
				table.remove(activeCoins, i)
				break
			end
		end
	end)

	local info: CoinInfo = {
		model = coin,
		root = root,
		spawnTime = os.clock(),
		basePos = basePos,
		phase = math.random() * math.pi * 2,
	}
	table.insert(activeCoins, info)
	clog(string.format("Spawned coin at (%.1f, %.1f, %.1f). Active=%d", basePos.X, basePos.Y, basePos.Z, #activeCoins))
	return info
end

-- Animate coins (hover + rotate)
RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()
	for _, info in ipairs(activeCoins) do
		local y = math.sin((t + info.phase) * 2) * 0.5
		local rot = CFrame.Angles(0, (t * 2) % (math.pi * 2), 0)
		info.model:PivotTo(CFrame.new(info.basePos + Vector3.new(0, y, 0)) * rot)
	end
end)

-- Maintenance loop: spawn and despawn
spawn(function()
	clog("maintenance loop started")
	while true do
		-- Despawn old
		local now = os.clock()
		for i = #activeCoins, 1, -1 do
			local info = activeCoins[i]
			if now - info.spawnTime > DESPAWN_AFTER then
				if info.model then info.model:Destroy() end
				table.remove(activeCoins, i)
				clog("Despawned old coin; Active=" .. #activeCoins)
			end
		end
		-- Spawn new up to cap
		while #activeCoins < MAX_COINS do
			createCoin()
		end
		-- Wait interval before next spawn attempt
		task.wait(SPAWN_INTERVAL)
	end
end) 