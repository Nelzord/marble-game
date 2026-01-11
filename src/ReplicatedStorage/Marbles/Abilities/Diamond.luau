-- Diamond marble ability: Creates a massive diamond tower and rains coins
local Ability = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Constants
local TOWER_HEIGHT = 150 -- Massive height in studs
local TOWER_BASE_SIZE = 30 -- Base width/depth in studs
local TOWER_TOP_SIZE = 5 -- Top width/depth in studs
local TOWER_SEGMENTS = 20 -- Number of segments for smooth tapering
local COIN_RAIN_DURATION = 10 -- Seconds to rain coins
local COIN_RAIN_INTERVAL = 0.2 -- Spawn a coin every 0.2 seconds
local COIN_RAIN_AREA = 50 -- Area around tower to spawn coins
local TOWER_DURATION = 15 -- How long the tower exists (seconds)

function Ability.Description()
	return "Diamond: Creates a massive diamond tower, teleports you to the top, and rains coins for 10 seconds."
end

function Ability.Cooldown()
	return 30 -- 30 second cooldown
end

-- Helper: create a single coin that falls
local function createFallingCoin(position: Vector3, player: Player)
	local coin = Instance.new("Model")
	coin.Name = "DiamondTowerCoin"
	coin.Parent = workspace

	local root = Instance.new("Part")
	root.Name = "CoinRoot"
	root.Shape = Enum.PartType.Cylinder
	root.Size = Vector3.new(0.5, 3, 3)
	root.Color = Color3.fromRGB(255, 215, 0) -- Gold color
	root.Material = Enum.Material.Metal
	root.Anchored = false -- Not anchored so it falls
	root.CanCollide = true
	root.Massless = false
	root.Parent = coin

	coin:PivotTo(CFrame.new(position))

	-- Touch collect sensor (anchored, invisible, follows coin)
	local sensor = Instance.new("Part")
	sensor.Name = "CoinSensor"
	sensor.Size = Vector3.new(4, 4, 4)
	sensor.Transparency = 1
	sensor.CanCollide = false
	sensor.Anchored = false
	sensor.Massless = true
	sensor.CFrame = CFrame.new(position)
	sensor.Parent = coin
	
	-- Weld sensor to coin so it follows
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = sensor
	weld.Parent = root

	-- Collection logic
	sensor.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		if not model then return end
		local collectingPlayer = Players:GetPlayerFromCharacter(model)
		if not collectingPlayer then return end
		
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
			
			CoinService:AddCoins(collectingPlayer, coinAmount)
			
			-- Play pickup sound
			local sfxPart = Instance.new("Part")
			sfxPart.Name = "CoinSFX"
			sfxPart.Anchored = true
			sfxPart.CanCollide = false
			sfxPart.CanQuery = false
			sfxPart.CanTouch = false
			sfxPart.Transparency = 1
			sfxPart.Size = Vector3.new(1, 1, 1)
			sfxPart.CFrame = CFrame.new(root.Position)
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

	-- Auto-destroy after falling for a while
	Debris:AddItem(coin, 15)
end

-- Helper: create diamond tower segment
local function createTowerSegment(position: Vector3, size: Vector3, segmentIndex: number)
	local segment = Instance.new("Part")
	segment.Name = ("DiamondTowerSegment_%d"):format(segmentIndex)
	segment.Size = size
	segment.Color = Color3.fromRGB(185, 242, 255) -- Light blue/cyan diamond color
	segment.Material = Enum.Material.Neon -- Glowing material
	segment.Anchored = true
	segment.CanCollide = true
	segment.Transparency = 0.3 -- Slightly transparent
	segment.Position = position
	segment.Parent = workspace
	
	-- Add point light for glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(185, 242, 255)
	pointLight.Brightness = 2
	pointLight.Range = 15
	pointLight.Parent = segment
	
	-- Create diamond particles
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, size.Y / 2, 0)
	attachment.Parent = segment
	
	local diamondParticles = Instance.new("ParticleEmitter")
	diamondParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	diamondParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), -- White
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(185, 242, 255)), -- Light blue
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255)) -- Blue
	})
	diamondParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	diamondParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	diamondParticles.Rate = 20
	diamondParticles.Lifetime = NumberRange.new(1.5, 3)
	diamondParticles.Speed = NumberRange.new(1, 2)
	diamondParticles.SpreadAngle = Vector2.new(30, 30)
	diamondParticles.EmissionDirection = Enum.NormalId.Top
	diamondParticles.Parent = attachment
	
	return segment
end

-- Helper: get (or create) the folder that holds references to tower
local function getOrCreateTowerFolder(character: Model)
	local folder = character:FindFirstChild("DiamondTowerFolder")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "DiamondTowerFolder"
		folder.Archivable = false
		folder.Parent = character
	end
	return folder
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("DIAMOND ABILITY: Activating for player:", player.Name)
	print("DIAMOND ABILITY: Character:", character and character.Name or "nil")
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("DIAMOND ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local playerPosition = humanoidRootPart.Position
	
	-- Tower base position (at player's current position)
	local towerBasePosition = Vector3.new(playerPosition.X, playerPosition.Y - 2, playerPosition.Z)
	
	print("DIAMOND ABILITY: Creating massive diamond tower at position:", towerBasePosition)
	
	-- Create folder to store references
	local folder = getOrCreateTowerFolder(character)
	
	-- Create tower model to hold everything
	local towerModel = Instance.new("Model")
	towerModel.Name = ("DiamondTower_%s"):format(tick())
	towerModel.Parent = workspace
	
	-- Calculate segment dimensions (tapering from base to top)
	local segments = {}
	local segmentHeight = TOWER_HEIGHT / TOWER_SEGMENTS
	
	for i = 1, TOWER_SEGMENTS do
		-- Calculate size (taper from base to top)
		local progress = (i - 1) / (TOWER_SEGMENTS - 1) -- 0 to 1
		local currentSize = TOWER_BASE_SIZE * (1 - progress) + TOWER_TOP_SIZE * progress
		
		-- Calculate position
		local segmentY = towerBasePosition.Y + (i - 0.5) * segmentHeight
		local segmentPosition = Vector3.new(towerBasePosition.X, segmentY, towerBasePosition.Z)
		
		-- Create segment
		local segment = createTowerSegment(
			segmentPosition,
			Vector3.new(currentSize, segmentHeight, currentSize),
			i
		)
		segment.Parent = towerModel
		table.insert(segments, segment)
		
		-- Store reference
		local segmentRef = Instance.new("ObjectValue")
		segmentRef.Name = ("DiamondTowerSegment_%d_%s"):format(i, tick())
		segmentRef.Value = segment
		segmentRef.Parent = folder
	end
	
	-- Calculate top position (above the tower)
	local towerTopPosition = Vector3.new(
		towerBasePosition.X,
		towerBasePosition.Y + TOWER_HEIGHT + 5, -- 5 studs above tower
		towerBasePosition.Z
	)
	
	-- Teleport player to the top
	humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(CFrame.new(towerTopPosition))
	print("DIAMOND ABILITY: Teleported player to top of tower at:", towerTopPosition)
	
	-- Store tower model reference
	local towerRef = Instance.new("ObjectValue")
	towerRef.Name = ("DiamondTowerModel_%s"):format(tick())
	towerRef.Value = towerModel
	towerRef.Parent = folder
	
	-- Start coin rain
	local coinRainStartTime = tick()
	local lastCoinSpawnTime = 0
	local coinRainConnection
	
	coinRainConnection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		local elapsed = currentTime - coinRainStartTime
		
		-- Stop after duration
		if elapsed >= COIN_RAIN_DURATION then
			if coinRainConnection then
				coinRainConnection:Disconnect()
			end
			return
		end
		
		-- Spawn coins at intervals
		if currentTime - lastCoinSpawnTime >= COIN_RAIN_INTERVAL then
			-- Spawn coin in random position above tower
			local coinX = towerBasePosition.X + (math.random() - 0.5) * COIN_RAIN_AREA
			local coinZ = towerBasePosition.Z + (math.random() - 0.5) * COIN_RAIN_AREA
			local coinY = towerTopPosition.Y + 20 + math.random() * 10 -- Spawn 20-30 studs above top
			
			createFallingCoin(Vector3.new(coinX, coinY, coinZ), player)
			lastCoinSpawnTime = currentTime
		end
	end)
	
	-- Schedule automatic cleanup after TOWER_DURATION
	task.delay(TOWER_DURATION, function()
		-- Disconnect coin rain
		if coinRainConnection then
			coinRainConnection:Disconnect()
		end
		
		-- Fade out effect
		for _, segment in ipairs(segments) do
			if segment and segment.Parent then
				local tween = TweenService:Create(segment, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Transparency = 1
				})
				tween:Play()
			end
		end
		
		-- Destroy all after fade
		task.delay(2.1, function()
			if towerModel and towerModel.Parent then
				towerModel:Destroy()
			end
			
			-- Clean up references
			if folder then
				for _, ref in pairs(folder:GetChildren()) do
					if ref:IsA("ObjectValue") and (ref.Value == nil or not ref.Value.Parent) then
						ref:Destroy()
					end
				end
			end
		end)
	end)
	
	-- Also use Debris as safety net
	Debris:AddItem(towerModel, TOWER_DURATION + 3)
	
	print("DIAMOND ABILITY: Massive diamond tower created, player teleported to top, coins raining for", COIN_RAIN_DURATION, "seconds")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("DIAMOND ABILITY: Deactivating for player:", player.Name)
	
	if not character then
		return
	end
	
	-- Remove all tower components immediately if they exist
	local folder = character:FindFirstChild("DiamondTowerFolder")
	if folder then
		for _, ref in pairs(folder:GetChildren()) do
			if ref:IsA("ObjectValue") and ref.Value then
				if ref.Value.Parent then
					print("DIAMOND ABILITY: Removing tower component immediately")
					ref.Value:Destroy()
				end
			end
		end
		folder:Destroy()
	end
end

return Ability
