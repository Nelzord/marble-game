-- Castle marble ability: Creates a castle structure and teleports the player to the top
local Ability = {}

-- Services
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Constants
local CASTLE_HEIGHT = 40 -- Height of the main castle structure
local CASTLE_BASE_SIZE = 20 -- Base width/depth of the castle
local CASTLE_DURATION = 20 -- How long the castle exists (seconds)
local TOWER_HEIGHT = 15 -- Height of corner towers
local TOWER_SIZE = 4 -- Size of corner towers
local WALL_THICKNESS = 2 -- Thickness of castle walls
local BATTLEMENT_HEIGHT = 3 -- Height of top battlements
local BATTLEMENT_THICKNESS = 1.5 -- Thickness of top battlements

function Ability.Description()
	return "Castle: Creates a majestic castle and teleports you to the top."
end

function Ability.Cooldown()
	return 25 -- 25 second cooldown
end

-- Helper: create a castle tower
local function createTower(position: Vector3, towerIndex: number, parent: Instance)
	local tower = Instance.new("Part")
	tower.Name = ("CastleTower_%d"):format(towerIndex)
	tower.Shape = Enum.PartType.Cylinder
	tower.Size = Vector3.new(TOWER_HEIGHT, TOWER_SIZE, TOWER_SIZE)
	tower.Material = Enum.Material.Brick
	tower.Color = Color3.fromRGB(139, 139, 122) -- Stone gray color
	tower.Anchored = true
	tower.CanCollide = true
	tower.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	tower.Parent = parent
	
	-- Add texture
	local texture = Instance.new("Texture")
	texture.Texture = "rbxasset://textures/terrain/rock.jpg"
	texture.StudsPerTileU = 2
	texture.StudsPerTileV = 2
	texture.Face = Enum.NormalId.Front
	texture.Parent = tower
	
	-- Add window to tower
	local windowHeight = position.Y + TOWER_HEIGHT / 2 - 3
	local windowAngle = math.rad(towerIndex * 90) -- Different angle for each tower
	local windowOffset = TOWER_SIZE / 2 + 0.1
	local windowPos = position + Vector3.new(
		math.cos(windowAngle) * windowOffset,
		windowHeight - position.Y,
		math.sin(windowAngle) * windowOffset
	)
	local towerWindow = Instance.new("Part")
	towerWindow.Name = "TowerWindow"
	towerWindow.Size = Vector3.new(0.2, 1.5, 1)
	towerWindow.Material = Enum.Material.Neon
	towerWindow.Color = Color3.fromRGB(100, 150, 255)
	towerWindow.Transparency = 0.3
	towerWindow.Anchored = true
	towerWindow.CanCollide = false
	towerWindow.CFrame = CFrame.new(windowPos) * CFrame.Angles(0, windowAngle, 0)
	towerWindow.Parent = parent
	
	local windowLight = Instance.new("PointLight")
	windowLight.Color = Color3.fromRGB(150, 200, 255)
	windowLight.Brightness = 1
	windowLight.Range = 4
	windowLight.Parent = towerWindow
	
	-- Add walkway ring at the top - CREATE THIS FIRST
	local walkwayRingY = position.Y + TOWER_HEIGHT / 2 + 0.15
	local walkwayRing = Instance.new("Part")
	walkwayRing.Name = "TowerWalkway"
	walkwayRing.Shape = Enum.PartType.Cylinder
	walkwayRing.Size = Vector3.new(0.3, TOWER_SIZE + 0.5, TOWER_SIZE + 0.5)
	walkwayRing.Material = Enum.Material.Brick
	walkwayRing.Color = Color3.fromRGB(130, 130, 115)
	walkwayRing.Anchored = true
	walkwayRing.CanCollide = true
	walkwayRing.CFrame = CFrame.new(position + Vector3.new(0, walkwayRingY - position.Y, 0)) * CFrame.Angles(0, 0, math.rad(90))
	walkwayRing.Parent = parent
	
	-- Add detailed battlements at the top (multiple merlons) - ON TOP OF WALKWAY
	local battlementTopY = walkwayRingY + 0.15 + 1 -- Position on top of walkway
	local merlonCount = 8 -- 8 merlons around the circular tower
	local merlonWidth = 0.8
	local merlonHeight = 2
	local merlonThickness = 0.8
	
	for i = 1, merlonCount do
		local angle = (i - 1) * (2 * math.pi / merlonCount)
		local merlonPos = position + Vector3.new(
			math.cos(angle) * (TOWER_SIZE / 2 + merlonThickness / 2),
			battlementTopY - position.Y,
			math.sin(angle) * (TOWER_SIZE / 2 + merlonThickness / 2)
		)
		
		local merlon = Instance.new("Part")
		merlon.Name = ("TowerBattlement_%d"):format(i)
		merlon.Size = Vector3.new(merlonThickness, merlonHeight, merlonWidth)
		merlon.Material = Enum.Material.Brick
		merlon.Color = Color3.fromRGB(139, 139, 122)
		merlon.Anchored = true
		merlon.CanCollide = true
		merlon.CFrame = CFrame.new(merlonPos) * CFrame.Angles(0, angle, 0)
		merlon.Parent = parent
	end
	
	-- Add point light for ambiance
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 200, 150)
	pointLight.Brightness = 1
	pointLight.Range = 10
	pointLight.Parent = tower
	
	return tower
end

-- Helper: create castle wall segment with battlements
local function createWall(position: Vector3, size: Vector3, wallIndex: number, parent: Instance)
	local wall = Instance.new("Part")
	wall.Name = ("CastleWall_%d"):format(wallIndex)
	wall.Size = size
	wall.Material = Enum.Material.Brick
	wall.Color = Color3.fromRGB(139, 139, 122) -- Stone gray
	wall.Anchored = true
	wall.CanCollide = true
	wall.Position = position
	wall.Parent = parent
	
	-- Add texture for stone appearance
	local texture = Instance.new("Texture")
	texture.Texture = "rbxasset://textures/terrain/rock.jpg"
	texture.StudsPerTileU = 2
	texture.StudsPerTileV = 2
	texture.Face = Enum.NormalId.Front
	texture.Parent = wall
	
	-- Battlements will be created after walkway
	local merlonWidth = 1.2
	local merlonGap = 0.8
	local merlonHeight = 2
	local merlonThickness = 0.8
	
	-- Determine wall length (either X or Z dimension)
	local wallLength = math.max(size.X, size.Z)
	local merlonCount = math.floor((wallLength - merlonGap) / (merlonWidth + merlonGap))
	
	-- Add walkway on top of wall - CREATE THIS FIRST
	local walkwayY = position.Y + size.Y / 2 + 0.15
	local walkway = Instance.new("Part")
	walkway.Name = ("WallWalkway_%d"):format(wallIndex)
	walkway.Size = Vector3.new(size.X, 0.3, size.Z)
	walkway.Material = Enum.Material.Brick
	walkway.Color = Color3.fromRGB(130, 130, 115)
	walkway.Anchored = true
	walkway.CanCollide = true
	walkway.Position = Vector3.new(position.X, walkwayY, position.Z)
	walkway.Parent = parent
	
	-- Fix battlement positioning to be on top of walkway
	local battlementTopY = walkwayY + 0.15 + merlonHeight / 2 -- Position on top of walkway
	
	-- Recreate merlons with correct positioning
	for i = 1, merlonCount do
		local merlonPos
		if size.X > size.Z then
			-- Horizontal wall (North/South)
			local xOffset = -wallLength / 2 + (i - 0.5) * (merlonWidth + merlonGap) + merlonGap / 2
			merlonPos = Vector3.new(position.X + xOffset, battlementTopY, position.Z)
		else
			-- Vertical wall (East/West)
			local zOffset = -wallLength / 2 + (i - 0.5) * (merlonWidth + merlonGap) + merlonGap / 2
			merlonPos = Vector3.new(position.X, battlementTopY, position.Z + zOffset)
		end
		
		local merlon = Instance.new("Part")
		merlon.Name = ("WallBattlement_%d_%d"):format(wallIndex, i)
		if size.X > size.Z then
			merlon.Size = Vector3.new(merlonWidth, merlonHeight, merlonThickness)
		else
			merlon.Size = Vector3.new(merlonThickness, merlonHeight, merlonWidth)
		end
		merlon.Material = Enum.Material.Brick
		merlon.Color = Color3.fromRGB(139, 139, 122)
		merlon.Anchored = true
		merlon.CanCollide = true
		merlon.Position = merlonPos
		merlon.Parent = parent
	end
	
	return wall
end

-- Helper: create a window
local function createWindow(position: Vector3, face: Enum.NormalId, parent: Instance)
	local window = Instance.new("Part")
	window.Name = "CastleWindow"
	window.Size = Vector3.new(0.2, 2, 1.5)
	window.Material = Enum.Material.Neon
	window.Color = Color3.fromRGB(100, 150, 255) -- Blue glow for window
	window.Transparency = 0.3
	window.Anchored = true
	window.CanCollide = false
	window.Position = position
	window.Parent = parent
	
	-- Add point light for window glow
	local windowLight = Instance.new("PointLight")
	windowLight.Color = Color3.fromRGB(150, 200, 255)
	windowLight.Brightness = 1.5
	windowLight.Range = 5
	windowLight.Parent = window
	
	return window
end

-- Helper: create a battlement segment (merlon)
local function createBattlement(position: Vector3, size: Vector3, parent: Instance)
	local merlon = Instance.new("Part")
	merlon.Name = "BattlementMerlon"
	merlon.Size = size
	merlon.Material = Enum.Material.Brick
	merlon.Color = Color3.fromRGB(139, 139, 122)
	merlon.Anchored = true
	merlon.CanCollide = true
	merlon.Position = position
	merlon.Parent = parent
	return merlon
end

-- Helper: create the main castle keep
local function createKeep(position: Vector3, size: Vector3, parent: Instance)
	local keep = Instance.new("Part")
	keep.Name = "CastleKeep"
	keep.Size = size
	keep.Material = Enum.Material.Brick
	keep.Color = Color3.fromRGB(120, 120, 105) -- Slightly darker stone
	keep.Anchored = true
	keep.CanCollide = true
	keep.Position = position
	keep.Parent = parent
	
	-- Add textures to all faces
	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right}) do
		local texture = Instance.new("Texture")
		texture.Texture = "rbxasset://textures/terrain/rock.jpg"
		texture.StudsPerTileU = 3
		texture.StudsPerTileV = 3
		texture.Face = face
		texture.Parent = keep
	end
	
	-- Add windows on each side
	local windowOffset = size.Y / 2 - 5 -- Windows at mid-height
	local windowDepth = size.X / 2 + 0.1
	
	-- Front window
	createWindow(
		position + Vector3.new(0, windowOffset, windowDepth),
		Enum.NormalId.Front,
		parent
	)
	-- Back window
	createWindow(
		position + Vector3.new(0, windowOffset, -windowDepth),
		Enum.NormalId.Back,
		parent
	)
	-- Left window
	createWindow(
		position + Vector3.new(-windowDepth, windowOffset, 0),
		Enum.NormalId.Left,
		parent
	)
	-- Right window
	createWindow(
		position + Vector3.new(windowDepth, windowOffset, 0),
		Enum.NormalId.Right,
		parent
	)
	
	-- Add a door at the front
	local door = Instance.new("Part")
	door.Name = "CastleDoor"
	door.Size = Vector3.new(0.3, 4, 2.5)
	door.Material = Enum.Material.Wood
	door.Color = Color3.fromRGB(80, 50, 30) -- Dark brown wood
	door.Anchored = true
	door.CanCollide = true
	door.Position = position + Vector3.new(0, -size.Y / 2 + 2, size.X / 2 + 0.15)
	door.Parent = parent
	
	-- Add door frame
	local doorFrame = Instance.new("Part")
	doorFrame.Name = "DoorFrame"
	doorFrame.Size = Vector3.new(0.5, 4.5, 3)
	doorFrame.Material = Enum.Material.Brick
	doorFrame.Color = Color3.fromRGB(100, 100, 90)
	doorFrame.Anchored = true
	doorFrame.CanCollide = true
	doorFrame.Position = position + Vector3.new(0, -size.Y / 2 + 2, size.X / 2 + 0.25)
	doorFrame.Parent = parent
	
	-- Add connecting wall at the top (walkway behind battlements) - CREATE THIS FIRST
	local walkwayY = position.Y + size.Y / 2 + 0.25
	local battlementSize = size.X - 1 -- Slightly smaller than keep
	
	local walkway = Instance.new("Part")
	walkway.Name = "TopWalkway"
	walkway.Size = Vector3.new(battlementSize, 0.5, battlementSize)
	walkway.Material = Enum.Material.Brick
	walkway.Color = Color3.fromRGB(130, 130, 115)
	walkway.Anchored = true
	walkway.CanCollide = true
	walkway.Position = Vector3.new(position.X, walkwayY, position.Z)
	walkway.Parent = parent
	
	-- Create top battlements (walls at the top) - ON TOP OF WALKWAY
	local topY = walkwayY + 0.25 + BATTLEMENT_HEIGHT / 2 -- Position on top of walkway
	local merlonWidth = 1.5
	local merlonGap = 1
	local merlonHeight = BATTLEMENT_HEIGHT
	local merlonThickness = BATTLEMENT_THICKNESS
	
	-- Calculate how many merlons fit on each side
	local merlonsPerSide = math.floor((battlementSize - merlonGap) / (merlonWidth + merlonGap))
	
	-- North side battlements
	for i = 1, merlonsPerSide do
		local xPos = position.X - battlementSize / 2 + (i - 0.5) * (merlonWidth + merlonGap) + merlonGap / 2
		createBattlement(
			Vector3.new(xPos, topY, position.Z + battlementSize / 2 + merlonThickness / 2),
			Vector3.new(merlonThickness, merlonHeight, merlonWidth),
			parent
		)
	end
	
	-- South side battlements
	for i = 1, merlonsPerSide do
		local xPos = position.X - battlementSize / 2 + (i - 0.5) * (merlonWidth + merlonGap) + merlonGap / 2
		createBattlement(
			Vector3.new(xPos, topY, position.Z - battlementSize / 2 - merlonThickness / 2),
			Vector3.new(merlonThickness, merlonHeight, merlonWidth),
			parent
		)
	end
	
	-- East side battlements
	for i = 1, merlonsPerSide do
		local zPos = position.Z - battlementSize / 2 + (i - 0.5) * (merlonWidth + merlonGap) + merlonGap / 2
		createBattlement(
			Vector3.new(position.X + battlementSize / 2 + merlonThickness / 2, topY, zPos),
			Vector3.new(merlonWidth, merlonHeight, merlonThickness),
			parent
		)
	end
	
	-- West side battlements
	for i = 1, merlonsPerSide do
		local zPos = position.Z - battlementSize / 2 + (i - 0.5) * (merlonWidth + merlonGap) + merlonGap / 2
		createBattlement(
			Vector3.new(position.X - battlementSize / 2 - merlonThickness / 2, topY, zPos),
			Vector3.new(merlonWidth, merlonHeight, merlonThickness),
			parent
		)
	end
	
	-- Add point light at the top
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 220, 180)
	pointLight.Brightness = 2
	pointLight.Range = 15
	pointLight.Parent = keep
	
	-- Add flag at the top (on top of battlements)
	local flagPoleY = walkwayY + 0.25 + BATTLEMENT_HEIGHT + 1.5
	local flagPole = Instance.new("Part")
	flagPole.Name = "FlagPole"
	flagPole.Size = Vector3.new(0.2, 3, 0.2)
	flagPole.Material = Enum.Material.Wood
	flagPole.Color = Color3.fromRGB(101, 67, 33) -- Brown
	flagPole.Anchored = true
	flagPole.CanCollide = false
	flagPole.CFrame = CFrame.new(position.X, flagPoleY, position.Z)
	flagPole.Parent = parent
	
	local flag = Instance.new("Part")
	flag.Name = "Flag"
	flag.Size = Vector3.new(0.1, 2, 1.5)
	flag.Material = Enum.Material.Fabric
	flag.Color = Color3.fromRGB(200, 0, 0) -- Red flag
	flag.Anchored = true
	flag.CanCollide = false
	flag.CFrame = CFrame.new(flagPole.Position + Vector3.new(0.75, 0, 0))
	flag.Parent = parent
	
	-- Add sparkle particles at the top
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, size.Y / 2 + 0.25 + BATTLEMENT_HEIGHT, 0)
	attachment.Parent = keep
	
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 100))
	})
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	sparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	sparkles.Rate = 15
	sparkles.Lifetime = NumberRange.new(2, 4)
	sparkles.Speed = NumberRange.new(1, 2)
	sparkles.SpreadAngle = Vector2.new(30, 30)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Parent = attachment
	
	return keep
end

-- Helper: get (or create) the folder that holds references to castle
local function getOrCreateCastleFolder(character: Model)
	local folder = character:FindFirstChild("CastleFolder")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CastleFolder"
		folder.Archivable = false
		folder.Parent = character
	end
	return folder
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("CASTLE ABILITY: Activating for player:", player.Name)
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("CASTLE ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local playerPosition = humanoidRootPart.Position
	
	-- Castle base position (below the player)
	local castleBasePosition = Vector3.new(
		playerPosition.X,
		playerPosition.Y - 2,
		playerPosition.Z
	)
	
	print("CASTLE ABILITY: Creating castle at position:", castleBasePosition)
	
	-- Create folder to store references
	local folder = getOrCreateCastleFolder(character)
	
	-- Create castle model to hold everything
	local castleModel = Instance.new("Model")
	castleModel.Name = ("Castle_%s"):format(tick())
	castleModel.Parent = workspace
	
	-- Create the main keep (center structure)
	local keepSize = Vector3.new(CASTLE_BASE_SIZE, CASTLE_HEIGHT, CASTLE_BASE_SIZE)
	local keepPosition = Vector3.new(
		castleBasePosition.X,
		castleBasePosition.Y + CASTLE_HEIGHT / 2,
		castleBasePosition.Z
	)
	local keep = createKeep(keepPosition, keepSize, castleModel)
	
	-- Create four corner towers
	local towerOffset = CASTLE_BASE_SIZE / 2 + TOWER_SIZE / 2
	local towerPositions = {
		Vector3.new(castleBasePosition.X - towerOffset, castleBasePosition.Y + TOWER_HEIGHT / 2, castleBasePosition.Z - towerOffset),
		Vector3.new(castleBasePosition.X + towerOffset, castleBasePosition.Y + TOWER_HEIGHT / 2, castleBasePosition.Z - towerOffset),
		Vector3.new(castleBasePosition.X - towerOffset, castleBasePosition.Y + TOWER_HEIGHT / 2, castleBasePosition.Z + towerOffset),
		Vector3.new(castleBasePosition.X + towerOffset, castleBasePosition.Y + TOWER_HEIGHT / 2, castleBasePosition.Z + towerOffset),
	}
	
	for i, towerPos in ipairs(towerPositions) do
		createTower(towerPos, i, castleModel)
	end
	
	-- Create foundation/base for the castle (after towerOffset is calculated)
	local foundationSize = CASTLE_BASE_SIZE + towerOffset * 2 + 2
	local foundation = Instance.new("Part")
	foundation.Name = "CastleFoundation"
	foundation.Size = Vector3.new(foundationSize, 1, foundationSize)
	foundation.Material = Enum.Material.Brick
	foundation.Color = Color3.fromRGB(100, 100, 90) -- Darker stone for foundation
	foundation.Anchored = true
	foundation.CanCollide = true
	foundation.Position = Vector3.new(
		castleBasePosition.X,
		castleBasePosition.Y - 0.5,
		castleBasePosition.Z
	)
	foundation.Parent = castleModel
	
	-- Add texture to foundation
	for _, face in ipairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
		local texture = Instance.new("Texture")
		texture.Texture = "rbxasset://textures/terrain/rock.jpg"
		texture.StudsPerTileU = 4
		texture.StudsPerTileV = 4
		texture.Face = face
		texture.Parent = foundation
	end
	
	-- Create connecting walls between towers
	local wallHeight = TOWER_HEIGHT * 0.6
	local wallLength = towerOffset * 2
	local wallPositions = {
		-- North wall
		Vector3.new(castleBasePosition.X, castleBasePosition.Y + wallHeight / 2, castleBasePosition.Z - towerOffset),
		-- South wall
		Vector3.new(castleBasePosition.X, castleBasePosition.Y + wallHeight / 2, castleBasePosition.Z + towerOffset),
		-- East wall
		Vector3.new(castleBasePosition.X + towerOffset, castleBasePosition.Y + wallHeight / 2, castleBasePosition.Z),
		-- West wall
		Vector3.new(castleBasePosition.X - towerOffset, castleBasePosition.Y + wallHeight / 2, castleBasePosition.Z),
	}
	
	local wallSizes = {
		Vector3.new(WALL_THICKNESS, wallHeight, wallLength),
		Vector3.new(WALL_THICKNESS, wallHeight, wallLength),
		Vector3.new(wallLength, wallHeight, WALL_THICKNESS),
		Vector3.new(wallLength, wallHeight, WALL_THICKNESS),
	}
	
	for i, wallPos in ipairs(wallPositions) do
		createWall(wallPos, wallSizes[i], i, castleModel)
	end
	
	-- Calculate top position (on the walkway surface at the top of the keep)
	-- Walkway is at: keepPosition.Y + CASTLE_HEIGHT/2 + 0.25
	-- Player should spawn on top of walkway (walkway top surface is at walkwayY + 0.25)
	local walkwayTopY = keepPosition.Y + CASTLE_HEIGHT / 2 + 0.25 + 0.25 -- Top surface of walkway
	local castleTopPosition = Vector3.new(
		castleBasePosition.X,
		walkwayTopY + 2, -- 2 studs above walkway surface for player spawn
		castleBasePosition.Z
	)
	
	-- Teleport player to the top
	humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(CFrame.new(castleTopPosition))
	print("CASTLE ABILITY: Teleported player to top of castle at:", castleTopPosition)
	
	-- Store castle model reference
	local castleRef = Instance.new("ObjectValue")
	castleRef.Name = ("CastleModel_%s"):format(tick())
	castleRef.Value = castleModel
	castleRef.Parent = folder
	
	-- Schedule automatic cleanup after CASTLE_DURATION
	task.delay(CASTLE_DURATION, function()
		-- Fade out effect
		for _, descendant in castleModel:GetDescendants() do
			if descendant:IsA("BasePart") then
				local tween = TweenService:Create(
					descendant,
					TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				)
				tween:Play()
			end
			if descendant:IsA("PointLight") then
				local tween = TweenService:Create(
					descendant,
					TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Brightness = 0 }
				)
				tween:Play()
			end
			if descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
			end
		end
		
		-- Destroy all after fade
		task.delay(2.1, function()
			if castleModel and castleModel.Parent then
				castleModel:Destroy()
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
	Debris:AddItem(castleModel, CASTLE_DURATION + 3)
	
	print("CASTLE ABILITY: Castle created, player teleported to top")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("CASTLE ABILITY: Deactivating for player:", player.Name)
	
	if not character then
		return
	end
	
	-- Remove all castle components immediately if they exist
	local folder = character:FindFirstChild("CastleFolder")
	if folder then
		for _, ref in pairs(folder:GetChildren()) do
			if ref:IsA("ObjectValue") and ref.Value then
				if ref.Value.Parent then
					print("CASTLE ABILITY: Removing castle immediately")
					ref.Value:Destroy()
				end
			end
		end
		folder:Destroy()
	end
end

return Ability
