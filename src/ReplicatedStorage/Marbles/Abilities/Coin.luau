-- Coin marble ability: drops coins behind the player as they move
local Ability = {}

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Constants
local COIN_DROP_INTERVAL = 0.5 -- Drop a coin every 0.5 seconds
local COIN_DROP_DISTANCE = 3 -- Distance behind player to drop coins
local COIN_LIFETIME = 30 -- Coins despawn after 30 seconds

function Ability.Description()
	return "Coin: Drops coins behind you as you move."
end

function Ability.Cooldown()
	return 0 -- No cooldown - passive ability
end

-- Helper function to create a coin
local function createCoin(position: Vector3)
	local coin = Instance.new("Model")
	coin.Name = "Coin"
	coin.Parent = workspace

	local root = Instance.new("Part")
	root.Name = "CoinRoot"
	root.Shape = Enum.PartType.Cylinder
	root.Size = Vector3.new(0.5, 3, 3)
	root.Color = Color3.fromRGB(255, 215, 0) -- Gold color
	root.Material = Enum.Material.Metal
	root.Anchored = true
	root.CanCollide = false
	root.Parent = coin

	coin:PivotTo(CFrame.new(position))

	-- Touch collect sensor (anchored, invisible)
	local sensor = Instance.new("Part")
	sensor.Name = "CoinSensor"
	sensor.Size = Vector3.new(4, 4, 4)
	sensor.Transparency = 1
	sensor.CanCollide = false
	sensor.Anchored = true
	sensor.CFrame = CFrame.new(position)
	sensor.Parent = coin

	-- Collection logic (similar to CoinService)
	sensor.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		if not model then return end
		local player = Players:GetPlayerFromCharacter(model)
		if not player then return end
		
		-- Get CoinService to add coins
		local CoinService = require(game:GetService("ServerScriptService"):WaitForChild("CoinService"))
		if CoinService then
			-- Check for multipliers
			local goldMultiplier = model:GetAttribute("GoldMultiplier")
			local diamondMultiplier = model:GetAttribute("DiamondMultiplier")
			
			local coinAmount = 1
			local activeMultiplier = 1
			
			-- Check Diamond multiplier first (higher priority)
			if typeof(diamondMultiplier) == "number" and diamondMultiplier > 1 then
				activeMultiplier = diamondMultiplier
			-- Check Gold multiplier if no Diamond multiplier
			elseif typeof(goldMultiplier) == "number" and goldMultiplier > 1 then
				activeMultiplier = goldMultiplier
			end
			
			if activeMultiplier > 1 then
				coinAmount = math.floor(coinAmount * activeMultiplier)
			end
			
			CoinService:AddCoins(player, coinAmount)
			
			-- Play pickup sound
			local sfxPart = Instance.new("Part")
			sfxPart.Name = "CoinSFX"
			sfxPart.Anchored = true
			sfxPart.CanCollide = false
			sfxPart.CanQuery = false
			sfxPart.CanTouch = false
			sfxPart.Transparency = 1
			sfxPart.Size = Vector3.new(1, 1, 1)
			sfxPart.CFrame = CFrame.new(position)
			sfxPart.Parent = workspace
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://6792279908"
			sound.Volume = 0.8
			sound.RollOffMaxDistance = 100
			sound.RollOffMode = Enum.RollOffMode.Inverse
			sound.Parent = sfxPart
			sound:Play()
			task.delay(3, function()
				if sfxPart then sfxPart:Destroy() end
			end)
		end
		
		coin:Destroy()
	end)

	-- Animate coin (hover + rotate)
	local phase = math.random() * math.pi * 2
	local basePos = position
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not coin or not coin.Parent then
			connection:Disconnect()
			return
		end
		local t = os.clock()
		local y = math.sin((t + phase) * 2) * 0.5
		local rot = CFrame.Angles(0, (t * 2) % (math.pi * 2), 0)
		coin:PivotTo(CFrame.new(basePos + Vector3.new(0, y, 0)) * rot)
	end)

	-- Despawn after lifetime
	task.delay(COIN_LIFETIME, function()
		if coin and coin.Parent then
			coin:Destroy()
		end
		if connection then
			connection:Disconnect()
		end
	end)
end

-- Track active coin droppers
local activeDroppers: { [Player]: RBXScriptConnection } = {}

function Ability.ActivateAbility(player: Player, character: Model)
	print("COIN ABILITY: Activating for player:", player.Name)
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("COIN ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Check if coin dropping is already active
	if activeDroppers[player] then
		print("COIN ABILITY: Already active")
		return
	end
	
	-- Set coin attribute to true
	character:SetAttribute("CoinDroppingActive", true)
	
	-- Track last position and time
	local lastPosition = humanoidRootPart.Position
	local lastDropTime = tick()
	
	-- Start dropping coins
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not character or not character.Parent then
			if connection then
				connection:Disconnect()
			end
			activeDroppers[player] = nil
			return
		end
		
		local currentPosition = humanoidRootPart.Position
		local currentTime = tick()
		
		-- Check if enough time has passed and player has moved
		local distanceMoved = (currentPosition - lastPosition).Magnitude
		if currentTime - lastDropTime >= COIN_DROP_INTERVAL and distanceMoved > 0.5 then
			-- Calculate position behind player
			local direction = (currentPosition - lastPosition).Unit
			if direction.Magnitude == 0 then
				-- If not moving, drop behind based on current facing (use CFrame)
				local cf = humanoidRootPart.CFrame
				direction = -cf.LookVector
			else
				direction = -direction -- Behind player
			end
			
			local dropPosition = currentPosition + direction * COIN_DROP_DISTANCE
			dropPosition = Vector3.new(dropPosition.X, currentPosition.Y, dropPosition.Z) -- Keep same Y level
			
			-- Create coin
			createCoin(dropPosition)
			
			lastPosition = currentPosition
			lastDropTime = currentTime
		end
	end)
	
	activeDroppers[player] = connection
	print("COIN ABILITY: Coin dropping activated")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("COIN ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("CoinDroppingActive", false)
	end
	
	-- Stop dropping coins
	if activeDroppers[player] then
		activeDroppers[player]:Disconnect()
		activeDroppers[player] = nil
	end
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if activeDroppers[player] then
		activeDroppers[player]:Disconnect()
		activeDroppers[player] = nil
	end
end)

return Ability
