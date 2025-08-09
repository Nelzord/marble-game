-- MarbleService: server-side game flow
-- - Manages inventories (session only)
-- - Handles rolling and equipping marbles via RemoteEvents
-- - Spawns a spherical character per equipped marble

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))

-- Ensure Remotes folder and events exist
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
		InventoryUpdate = ensureEvent("InventoryUpdate"),
		RollForMarble = ensureEvent("RollForMarble"),
		RollResult = ensureEvent("RollResult"),
		EquipMarble = ensureEvent("EquipMarble"),
		RequestInventory = ensureEvent("RequestInventory"),
		ActivateAbility = ensureEvent("ActivateAbility"),
	}
end

local Remotes = getOrCreateRemotes()

-- Per-player in-memory data (session only). Replace with DataStore for persistence across sessions.
export type PlayerData = {
	owned: { [string]: boolean },
	equipped: string,
}

local DEFAULT_ID = "Default"
local playerData: { [Player]: PlayerData } = {}
local spawningFlag: { [Player]: boolean } = {}

local function getOrCreatePlayerData(player: Player): PlayerData
	local data = playerData[player]
	if not data then
		data = {
			owned = { [DEFAULT_ID] = true },
			equipped = DEFAULT_ID,
		}
		playerData[player] = data
	end
	return data
end

local function sendInventory(player: Player)
	local data = getOrCreatePlayerData(player)
	local ownedIds = {}
	for id, has in pairs(data.owned) do
		if has then table.insert(ownedIds, id) end
	end
	table.sort(ownedIds)
	Remotes.InventoryUpdate:FireClient(player, {
		owned = ownedIds,
		equipped = data.equipped,
	})
end

local function ensureHumanoid(model: Model): Humanoid
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then
		hum = Instance.new("Humanoid")
		hum.RequiresNeck = false
		hum.NameDisplayDistance = 0
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.Parent = model
	end
	return hum
end

local function ensureHRP(model: Model): BasePart
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	local part = Instance.new("Part")
	part.Name = "HumanoidRootPart"
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.SmoothPlastic
	part.Size = Vector3.new(4, 4, 4)
	part.Color = Color3.fromRGB(230, 230, 230)
	part.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function buildMarbleCharacter(player: Player, marbleId: string)
	local model = Marbles.getModelClone(marbleId)
	local character: Model
	if model then
		character = model
	else
		character = Instance.new("Model")
	end
	character:SetAttribute("IsMarbleCharacter", true)
	character.Name = player.Name
	character.Parent = workspace

	local hrp = ensureHRP(character)
	local hum = ensureHumanoid(character)
	character.PrimaryPart = hrp
	-- Make sure it can roll
	hrp.CanCollide = true
	hrp.Massless = false
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	-- Position at a spawn if available
	local spawnPos = Vector3.new(0, 10, 0)
	local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawnLocation then
		spawnPos = (spawnLocation :: any).Position + Vector3.new(0, 5, 0)
	end
	character:PivotTo(CFrame.new(spawnPos))

	player.Character = character
	-- Give client physics ownership for responsive control
	pcall(function()
		hrp:SetNetworkOwner(player)
	end)
end

local function respawnEquipped(player: Player)
	if spawningFlag[player] then return end
	spawningFlag[player] = true
	local data = getOrCreatePlayerData(player)
	-- Destroy old character, then build a new one
	local old = player.Character
	if old then
		old:Destroy()
	end
	buildMarbleCharacter(player, data.equipped)
	spawningFlag[player] = nil
end

-- Remote connections
Remotes.RollForMarble.OnServerEvent:Connect(function(player: Player)
	local data = getOrCreatePlayerData(player)
	local rolled = Marbles.roll()
	if not rolled then
		Remotes.RollResult:FireClient(player, {
			success = false,
			message = "No marbles available to roll.",
		})
		return
	end
	local newlyUnlocked = not data.owned[rolled.id]
	data.owned[rolled.id] = true
	Remotes.RollResult:FireClient(player, {
		success = true,
		marbleId = rolled.id,
		marbleName = rolled.name,
		new = newlyUnlocked,
	})
	sendInventory(player)
end)

Remotes.EquipMarble.OnServerEvent:Connect(function(player: Player, marbleId: string)
	local data = getOrCreatePlayerData(player)
	if type(marbleId) ~= "string" then return end
	local def = Marbles.getById(marbleId)
	if not def then return end
	if not data.owned[marbleId] then return end
	if data.equipped == marbleId then return end
	data.equipped = marbleId
	sendInventory(player)
	respawnEquipped(player)
end)

Remotes.RequestInventory.OnServerEvent:Connect(function(player: Player)
	sendInventory(player)
end)

Remotes.ActivateAbility.OnServerEvent:Connect(function(player: Player)
	local data = getOrCreatePlayerData(player)
	local def = Marbles.getById(data.equipped)
	if not def then return end
	local ability = Marbles.getAbilityModule(def)
	local character = player.Character
	if character then
		-- Invoke placeholder ability; modules decide what to do
		pcall(function()
			ability.ActivateAbility(player, character)
		end)
	end
end)

Players.PlayerAdded:Connect(function(player)
	local data = getOrCreatePlayerData(player)
	data.equipped = data.equipped or DEFAULT_ID
	sendInventory(player)
	player.CharacterAdded:Connect(function(character)
		-- If this is not our marble character, replace it
		if character:GetAttribute("IsMarbleCharacter") then
			-- Reassert network ownership on spawn
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				pcall(function()
					hrp:SetNetworkOwner(player)
				end)
			end
			return
		end
		task.defer(function()
			respawnEquipped(player)
		end)
	end)
	-- Force first marble character
	respawnEquipped(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
	spawningFlag[player] = nil
end) 