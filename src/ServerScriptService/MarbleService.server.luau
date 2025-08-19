-- MarbleService: server-side game flow
-- - Manages inventories (session only)
-- - Handles rolling and equipping marbles via RemoteEvents
-- - Spawns a spherical character per equipped marble

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))

-- Debug helper
local DEBUG = false
local function dprint(...)
	if DEBUG then
		print("[MarbleServer]", ...)
	end
end

-- Debug flag: Give all marbles to players for testing
-- Set to false to disable this feature in production
local GIVE_ALL_MARBLES = true

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
		AbilityCooldown = ensureEvent("AbilityCooldown"),
	}
end

local Remotes = getOrCreateRemotes()

-- Debug: Log if the give-all-marbles flag is enabled
if GIVE_ALL_MARBLES then
	print("[MarbleService] DEBUG MODE: All marbles will be given to players automatically")
end

-- Per-player in-memory data (session only). Replace with DataStore for persistence across sessions.
export type PlayerData = {
	owned: { [string]: boolean },
	equipped: string,
}

local DEFAULT_ID = "Default"
local playerData: { [Player]: PlayerData } = {}
local spawningFlag: { [Player]: boolean } = {}

-- Ability cooldown tracking
local abilityCooldowns: { [Player]: number } = {}

local function getOrCreatePlayerData(player: Player): PlayerData
	local data = playerData[player]
	if not data then
		data = {
			owned = { [DEFAULT_ID] = true },
			equipped = DEFAULT_ID,
		}
		
		-- Debug flag: Give all marbles to players for testing
		if GIVE_ALL_MARBLES then
			local allMarbles = Marbles.getAll()
			for _, marble in ipairs(allMarbles) do
				data.owned[marble.id] = true
			end
			dprint("Gave all marbles to player:", player.Name)
		end
		
		playerData[player] = data
	end
	return data
end

local function canUseAbility(player: Player): boolean
	local lastUse = abilityCooldowns[player]
	if not lastUse then return true end
	
	local data = getOrCreatePlayerData(player)
	local def = Marbles.getById(data.equipped)
	if not def then return false end
	
	local ability = Marbles.getAbilityModule(def)
	local cooldown = ability.Cooldown and ability.Cooldown() or 0
	if cooldown <= 0 then return true end
	
	return (tick() - lastUse) >= cooldown
end

local function startAbilityCooldown(player: Player)
	local data = getOrCreatePlayerData(player)
	local def = Marbles.getById(data.equipped)
	if not def then return end
	
	local ability = Marbles.getAbilityModule(def)
	local cooldown = ability.Cooldown and ability.Cooldown() or 0
	if cooldown <= 0 then return end
	
	abilityCooldowns[player] = tick()
	
	-- Send cooldown info to client
	Remotes.AbilityCooldown:FireClient(player, {
		duration = cooldown,
		startTime = tick(),
	})
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

local function applyIcePhysics(part: BasePart)
	-- Low friction and ice material for long glide
	part.Material = Enum.Material.Ice
	-- PhysicalProperties.new(density, friction, elasticity, frictionWeight?, elasticityWeight?)
	part.CustomPhysicalProperties = PhysicalProperties.new(1, 0.02, 0, 0, 0)
end

local function ensureHRP(model: Model): BasePart
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		applyIcePhysics(hrp)
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
	applyIcePhysics(part)
	return part
end

local function applyMarbleVisual(model: Model, marbleId: string)
	local def = Marbles.getById(marbleId)
	if not def then return end
	-- If we are using the generated HRP, tint it
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") and def.color then
		hrp.Color = def.color
	end
	model:SetAttribute("EquippedMarbleId", marbleId)
end

local function clearHRPTextures(model: Model)
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then return end
	for _, child in ipairs(hrp:GetChildren()) do
		if child:IsA("Decal") or child:IsA("Texture") then
			child:Destroy()
		end
	end
end

local function getRarityText(def): string
	if def and def.rollable and def.dropDenominator and def.dropDenominator > 0 then
		return string.format("1/%d", def.dropDenominator)
	end
	return "Default"
end

local function ensureNameplate(character: Model, player: Player, marbleId: string)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then return end
	local def = Marbles.getById(marbleId)
	local text = string.format("%s (%s)", player.Name, getRarityText(def))

	local gui = character:FindFirstChild("Nameplate")
	if not gui or not gui:IsA("BillboardGui") then
		gui = Instance.new("BillboardGui")
		gui.Name = "Nameplate"
		gui.Size = UDim2.fromOffset(180, 36)
		gui.StudsOffset = Vector3.new(0, 3.5, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 250
		gui.Adornee = hrp
		gui.Parent = character
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.new(1,1,1)
		label.Parent = gui
	end
	local label = gui:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function muteFootsteps(character: Model)
	local function handleDescendant(descendant: Instance)
		if descendant:IsA("Sound") then
			local n = descendant.Name
			if n == "Running" or n == "Run" or n == "Footsteps" or n == "Jumping" or n == "Jump" then
				descendant.Volume = 0
				descendant.Playing = false
			end
		elseif (descendant:IsA("LocalScript") or descendant:IsA("Script")) and descendant.Name == "RbxCharacterSounds" then
			descendant:Destroy()
		end
	end
	for _, d in ipairs(character:GetDescendants()) do
		handleDescendant(d)
	end
	character.DescendantAdded:Connect(handleDescendant)
end

local function buildMarbleCharacter(player: Player, marbleId: string)
	dprint("buildMarbleCharacter", player.Name, marbleId)
	local model = Marbles.getModelClone(marbleId)
	local character: Model
	if model then
		character = model
	else
		character = Instance.new("Model")
	end
	character:SetAttribute("IsMarbleCharacter", true)
	character.Name = player.Name
	
	-- Initialize default attributes
	character:SetAttribute("SpeedMultiplier", 1)
	character:SetAttribute("JumpBoostActive", false)
	character:SetAttribute("FrictionReduction", 0)
	character:SetAttribute("EquippedMarbleId", marbleId)
	character:SetAttribute("RedGlowActive", false)
	character:SetAttribute("GumballGlowActive", false)
	
	character.Parent = workspace

	local hrp = ensureHRP(character)
	local hum = ensureHumanoid(character)
	character.PrimaryPart = hrp
	-- Make sure it can roll
	hrp.CanCollide = true
	hrp.Massless = false
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	-- Ensure no static decals on HRP
	clearHRPTextures(character)

	applyMarbleVisual(character, marbleId)
	ensureNameplate(character, player, marbleId)
	muteFootsteps(character)

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
	local old = player.Character
	if old then
		-- Deactivate current ability before destroying character
		local currentDef = Marbles.getById(data.equipped)
		if currentDef then
			local currentAbility = Marbles.getAbilityModule(currentDef)
			if currentAbility and currentAbility.DeactivateAbility then
				dprint("Deactivating ability before respawn:", currentDef.id)
				local success, error = pcall(function()
					currentAbility.DeactivateAbility(player, old)
				end)
				if not success then
					dprint("Failed to deactivate ability during respawn:", error)
				end
			end
		end
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
	dprint("EquipMarble", player.Name, marbleId)
	local data = getOrCreatePlayerData(player)
	if type(marbleId) ~= "string" then return end
	local def = Marbles.getById(marbleId)
	if not def then return end
	if not data.owned[marbleId] then return end
	if data.equipped == marbleId then return end
	
	-- Deactivate current ability before switching
	local character = player.Character
	if character and character.Parent then
		local currentDef = Marbles.getById(data.equipped)
		if currentDef then
			local currentAbility = Marbles.getAbilityModule(currentDef)
			if currentAbility and currentAbility.DeactivateAbility then
				dprint("Deactivating current ability:", currentDef.id)
				local success, error = pcall(function()
					currentAbility.DeactivateAbility(player, character)
				end)
				if not success then
					dprint("Failed to deactivate ability:", error)
				end
			end
		end
	end
	
	data.equipped = marbleId
	sendInventory(player)
	
	-- In-place switch: update current character instead of respawn
	if character and character.Parent then
		clearHRPTextures(character)
		applyMarbleVisual(character, marbleId)
		ensureNameplate(character, player, marbleId)
	end
end)

Remotes.RequestInventory.OnServerEvent:Connect(function(player: Player)
	sendInventory(player)
end)

Remotes.ActivateAbility.OnServerEvent:Connect(function(player: Player)
	print("[DEBUG] ActivateAbility called by player:", player.Name)
	
	-- Check cooldown
	if not canUseAbility(player) then
		print("[DEBUG] Player on cooldown, returning")
		return
	end
	
	local data = getOrCreatePlayerData(player)
	local def = Marbles.getById(data.equipped)
	print("[DEBUG] Equipped marble definition:", def and def.id or "nil")
	
	if not def then 
		print("[DEBUG] No marble definition found, returning")
		return 
	end
	
	local ability = Marbles.getAbilityModule(def)
	print("[DEBUG] Ability module:", ability and "loaded" or "failed to load")
	print("[DEBUG] Ability module type:", typeof(ability))
	
	local character = player.Character
	if character then
		print("[DEBUG] Character found, activating ability")
		-- Start cooldown before activating ability
		startAbilityCooldown(player)
		
		local success, error = pcall(function()
			ability.ActivateAbility(player, character)
		end)
		
		if not success then
			print("[DEBUG] Ability activation failed with error:", error)
		else
			print("[DEBUG] Ability activation successful")
		end
	else
		print("[DEBUG] No character found")
	end
end)

Players.PlayerAdded:Connect(function(player)
	local data = getOrCreatePlayerData(player)
	data.equipped = data.equipped or DEFAULT_ID
	sendInventory(player)
	
	-- Handle character added
	player.CharacterAdded:Connect(function(character)
		if character:GetAttribute("IsMarbleCharacter") then
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
	
	-- Handle character removal to deactivate abilities
	player.CharacterRemoving:Connect(function(character)
		local data = playerData[player]
		if data and data.equipped then
			local currentDef = Marbles.getById(data.equipped)
			if currentDef then
				local currentAbility = Marbles.getAbilityModule(currentDef)
				if currentAbility and currentAbility.DeactivateAbility then
					dprint("Deactivating ability due to character removal:", currentDef.id)
					local success, error = pcall(function()
						currentAbility.DeactivateAbility(player, character)
					end)
					if not success then
						dprint("Failed to deactivate ability during character removal:", error)
					end
				end
			end
		end
	end)
	
	respawnEquipped(player)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Deactivate any active ability before player leaves
	local character = player.Character
	if character and character.Parent then
		local data = playerData[player]
		if data and data.equipped then
			local currentDef = Marbles.getById(data.equipped)
			if currentDef then
				local currentAbility = Marbles.getAbilityModule(currentDef)
				if currentAbility and currentAbility.DeactivateAbility then
					dprint("Deactivating ability before player leaves:", currentDef.id)
					local success, error = pcall(function()
						currentAbility.DeactivateAbility(player, character)
					end)
					if not success then
						dprint("Failed to deactivate ability when player leaves:", error)
					end
				end
			end
		end
	end
	
	playerData[player] = nil
	spawningFlag[player] = nil
	abilityCooldowns[player] = nil
end) 