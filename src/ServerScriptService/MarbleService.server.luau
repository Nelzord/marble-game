-- MarbleService: server-side game flow
-- - Manages inventories (session only)
-- - Handles rolling and equipping marbles via RemoteEvents
-- - Spawns a spherical character per equipped marble

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))

-- MarbleService module
local MarbleService = {}

-- DataStore for persistence
local marbleDataStore = DataStoreService:GetDataStore("MarblePlayerData")

-- Debug helper
local DEBUG = false
local function dprint(...)
	if DEBUG then
		print("[MarbleServer]", ...)
	end
end

-- Debug flag: Give all marbles to players for testing
-- Set to false to disable this feature in production
local GIVE_ALL_MARBLES = false

-- Special players who get all marbles (by username)
local SPECIAL_PLAYERS_ALL_MARBLES = {
	["Nelzord"] = true,
}

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

-- Per-player data with DataStore persistence
export type PlayerData = {
	owned: { [string]: boolean },
	equipped: string,
}

local DEFAULT_ID = "Default"
local playerData: { [Player]: PlayerData } = {}
local spawningFlag: { [Player]: boolean } = {}
local dataStoreCache: { [Player]: boolean } = {} -- Track if data has been loaded from DataStore

-- Ability cooldown tracking
local abilityCooldowns: { [Player]: number } = {}

-- Position recording for time travel ability
local positionRecordingEnabled = true
local positionRecordingInterval = 0.016 -- ~60fps

-- Function to save player data to DataStore
local function savePlayerData(player: Player)
	local data = playerData[player]
	if not data then return end
	
	task.spawn(function()
		local success, errorMsg = pcall(function()
			local saveData = {
				owned = {},
				equipped = data.equipped or DEFAULT_ID,
			}
			
			-- Convert owned table to array for DataStore
			for marbleId, isOwned in pairs(data.owned) do
				if isOwned then
					table.insert(saveData.owned, marbleId)
				end
			end
			
			marbleDataStore:SetAsync("marbles_" .. player.UserId, saveData)
			print("[MarbleService] Saved data for player:", player.Name)
		end)
		
		if not success then
			warn("[MarbleService] Failed to save data for " .. player.Name .. ": " .. tostring(errorMsg))
		end
	end)
end

-- Function to load player data from DataStore
local function loadPlayerData(player: Player)
	task.spawn(function()
		local success, loadedData = pcall(function()
			return marbleDataStore:GetAsync("marbles_" .. player.UserId)
		end)
		
		if success and loadedData then
			local data: PlayerData = {
				owned = {},
				equipped = loadedData.equipped or DEFAULT_ID,
			}
			
			-- Convert array back to owned table
			if loadedData.owned and type(loadedData.owned) == "table" then
				for _, marbleId in ipairs(loadedData.owned) do
					data.owned[marbleId] = true
				end
			end
			
			-- Ensure Default marble is always owned
			if not data.owned[DEFAULT_ID] then
				data.owned[DEFAULT_ID] = true
			end
			
			-- Special players get all marbles
			if SPECIAL_PLAYERS_ALL_MARBLES[player.Name] then
				local allMarbles = Marbles.getAll()
				for _, marble in ipairs(allMarbles) do
					data.owned[marble.id] = true
				end
				print("[MarbleService] Special player detected - gave all marbles to:", player.Name)
			end
			
			-- Ensure equipped marble is valid
			if not data.owned[data.equipped] then
				data.equipped = DEFAULT_ID
			end
			
			playerData[player] = data
			dataStoreCache[player] = true
			
			print("[MarbleService] Loaded data for player:", player.Name, "Owned:", #loadedData.owned or 0, "marbles")
			sendInventory(player)
		else
			-- No saved data, use defaults
			print("[MarbleService] No saved data for player:", player.Name, "using defaults")
			dataStoreCache[player] = true
		end
	end)
end

local function getOrCreatePlayerData(player: Player): PlayerData
	-- Wait for DataStore to load if not already loaded
	if not dataStoreCache[player] then
		-- Data is loading or hasn't started, use defaults temporarily
		if not playerData[player] then
			playerData[player] = {
				owned = { [DEFAULT_ID] = true },
				equipped = DEFAULT_ID,
			}
		end
		return playerData[player]
	end
	
	local data = playerData[player]
	if not data then
		-- Create default data if DataStore didn't return anything
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
		
		-- Special players get all marbles
		if SPECIAL_PLAYERS_ALL_MARBLES[player.Name] then
			local allMarbles = Marbles.getAll()
			for _, marble in ipairs(allMarbles) do
				data.owned[marble.id] = true
			end
			print("[MarbleService] Special player detected - gave all marbles to:", player.Name)
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

-- Record player positions for time travel ability
local function recordPlayerPosition(player: Player)
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then return end
	
	-- Check if player has time travel ability equipped
	local data = playerData[player]
	if data and data.equipped then
		local def = Marbles.getById(data.equipped)
		if def and def.abilityModule == "TimeTravel" then
			local ability = Marbles.getAbilityModule(def)
			if ability and ability.RecordPosition then
				ability.RecordPosition(player, hrp.Position)
			end
		end
	end
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

-- Function to grant a marble to a player (for Robux purchases, etc.)
local function grantMarble(player: Player, marbleId: string)
	print("[MarbleService] grantMarble called for player:", player.Name, "marbleId:", marbleId)
	local data = getOrCreatePlayerData(player)
	local def = Marbles.getById(marbleId)
	if not def then
		print("[MarbleService] Cannot grant marble - invalid ID:", marbleId)
		return false
	end
	print("[MarbleService] Marble definition found:", def.name)
	data.owned[marbleId] = true
	print("[MarbleService] Set owned[" .. marbleId .. "] = true")
	sendInventory(player)
	savePlayerData(player) -- Save to DataStore
	print("[MarbleService] Sent inventory update to player:", player.Name)
	print("[MarbleService] Granted marble", marbleId, "to player:", player.Name)
	return true
end

-- Function to check if player has a marble
local function hasMarble(player: Player, marbleId: string): boolean
	local data = getOrCreatePlayerData(player)
	return data.owned[marbleId] == true
end

-- Export functions for other services
MarbleService.GrantMarble = grantMarble
MarbleService.HasMarble = hasMarble

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

-- Function to determine rarity tier and styling
local function getRarityTier(def): { tier: string, font: Enum.Font, textColor: Color3, glowColor: Color3?, scale: number }
	if not def or not def.rollable or not def.dropDenominator or def.dropDenominator <= 0 then
		return {
			tier = "Common",
			font = Enum.Font.GothamBold,
			textColor = Color3.fromRGB(200, 200, 200),
			scale = 1.0
		}
	end
	
	local denominator = def.dropDenominator
	
	-- Rarity tiers based on drop chance (must match InventorySystem.luau)
	if denominator <= 2 then
		-- Common: 1/1, 1/2
		return {
			tier = "Common",
			font = Enum.Font.GothamBold,
			textColor = Color3.fromRGB(200, 200, 200),
			scale = 1.0
		}
	elseif denominator <= 5 then
		-- Uncommon: 1/3, 1/4, 1/5
		return {
			tier = "Uncommon",
			font = Enum.Font.SourceSansBold,
			textColor = Color3.fromRGB(100, 200, 100),
			glowColor = Color3.fromRGB(50, 150, 50),
			scale = 1.1
		}
	elseif denominator <= 9 then
		-- Rare: 1/6, 1/7, 1/8, 1/9
		return {
			tier = "Rare",
			font = Enum.Font.Antique,
			textColor = Color3.fromRGB(100, 150, 255),
			glowColor = Color3.fromRGB(50, 100, 200),
			scale = 1.2
		}
	elseif denominator <= 49 then
		-- Epic: 1/10 to 1/49
		return {
			tier = "Epic",
			font = Enum.Font.Fondamento,
			textColor = Color3.fromRGB(200, 100, 255),
			glowColor = Color3.fromRGB(150, 50, 200),
			scale = 1.3
		}
	elseif denominator <= 199 then
		-- Legendary: 1/50 to 1/199
		return {
			tier = "Legendary",
			font = Enum.Font.Highway,
			textColor = Color3.fromRGB(255, 200, 50),
			glowColor = Color3.fromRGB(255, 150, 0),
			scale = 1.4
		}
	else
		-- Mythic: 1/200+
		return {
			tier = "Mythic",
			font = Enum.Font.Highway,
			textColor = Color3.fromRGB(255, 50, 50),
			glowColor = Color3.fromRGB(255, 0, 0),
			scale = 1.5
		}
	end
end

local function ensureNameplate(character: Model, player: Player, marbleId: string)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then return end
	local def = Marbles.getById(marbleId)
	local rarityInfo = getRarityTier(def)
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
		label.Font = rarityInfo.font
		label.TextColor3 = rarityInfo.textColor
		label.Parent = gui
		
		-- Add rarity attributes for client-side styling
		character:SetAttribute("NameplateRarityTier", rarityInfo.tier)
		character:SetAttribute("NameplateFont", rarityInfo.font.Name)
		character:SetAttribute("NameplateTextColor", rarityInfo.textColor)
		character:SetAttribute("NameplateGlowColor", rarityInfo.glowColor)
		character:SetAttribute("NameplateScale", rarityInfo.scale)
	end
	
	local label = gui:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = text
		label.Font = rarityInfo.font
		label.TextColor3 = rarityInfo.textColor
	end
	
	-- Update rarity attributes
	character:SetAttribute("NameplateRarityTier", rarityInfo.tier)
	character:SetAttribute("NameplateFont", rarityInfo.font.Name)
	character:SetAttribute("NameplateTextColor", rarityInfo.textColor)
	character:SetAttribute("NameplateGlowColor", rarityInfo.glowColor)
	character:SetAttribute("NameplateScale", rarityInfo.scale)
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
	character:SetAttribute("MoonGravityActive", false)
	character:SetAttribute("MoonGlowActive", false)
	character:SetAttribute("PharaohGlowActive", false)
	
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
	
	-- Only activate PASSIVE abilities on spawn (cooldown = 0)
	-- Active abilities (cooldown > 0) should only be triggered by player input
	local ability = Marbles.getAbilityModule(marbleId)
	if ability and ability.ActivateAbility then
		local cooldown = ability.Cooldown and ability.Cooldown() or 0
		if cooldown == 0 then
			-- Passive ability - activate automatically on spawn
			dprint("Activating passive marble ability on spawn:", marbleId)
			local success, error = pcall(function()
				ability.ActivateAbility(player, character)
			end)
			if not success then
				dprint("Failed to activate passive marble ability on spawn:", error)
			end
		else
			dprint("Skipping active ability on spawn (requires manual activation):", marbleId)
		end
	end
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

-- Hazard system: Teleport players to SpawnLocation when they touch hazards
local function setupHazardSystem()
	-- Find all parts named "hazard" in workspace
	local function setupHazardPart(part: BasePart)
		if part.Name == "hazard" then
			part.Touched:Connect(function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				if not character then return end
				
				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end
				
				-- Check if this is a marble character
				if not character:GetAttribute("IsMarbleCharacter") then return end
				
				-- Teleport to SpawnLocation
				local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
				if spawnLocation then
					local spawnPos = spawnLocation.Position + Vector3.new(0, 5, 0)
					local hrp = character:FindFirstChild("HumanoidRootPart")
					if hrp and hrp:IsA("BasePart") then
						-- Stop any current velocity
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
						-- Teleport to spawn
						character:PivotTo(CFrame.new(spawnPos))
						dprint("Player", player.Name, "touched hazard and was teleported to spawn")
					end
				else
					-- Fallback: respawn the character
					dprint("No SpawnLocation found, respawning player", player.Name)
					respawnEquipped(player)
				end
			end)
		end
	end
	
	-- Setup existing hazard parts
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") then
			setupHazardPart(part)
		end
	end
	
	-- Monitor for new hazard parts
	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			setupHazardPart(descendant)
		end
	end)
end

-- Initialize hazard system
setupHazardSystem()

-- Void detection system: Respawn players who fall below the map
local VOID_Y_THRESHOLD = -100 -- Players below this Y coordinate are considered "in the void"

local function setupVoidDetection()
	-- Check all players periodically for void detection
	RunService.Heartbeat:Connect(function()
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if not character then continue end
			
			-- Check if this is a marble character
			if not character:GetAttribute("IsMarbleCharacter") then continue end
			
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp or not hrp:IsA("BasePart") then continue end
			
			-- Check if player has fallen below the void threshold
			if hrp.Position.Y < VOID_Y_THRESHOLD then
				dprint("Player", player.Name, "fell into the void at Y =", hrp.Position.Y)
				
				-- Find spawn location
				local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
				if spawnLocation then
					local spawnPos = spawnLocation.Position + Vector3.new(0, 5, 0)
					
					-- Stop any current velocity
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
					
					-- Teleport to spawn
					character:PivotTo(CFrame.new(spawnPos))
					dprint("Teleported player", player.Name, "back to spawn")
				else
					-- No spawn location found, respawn the character
					dprint("No SpawnLocation found, respawning player", player.Name)
					respawnEquipped(player)
				end
			end
		end
	end)
end

-- Initialize void detection system
setupVoidDetection()

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
	savePlayerData(player) -- Save to DataStore
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
	savePlayerData(player) -- Save to DataStore
	
	-- In-place switch: update current character instead of respawn
	if character and character.Parent then
		clearHRPTextures(character)
		applyMarbleVisual(character, marbleId)
		ensureNameplate(character, player, marbleId)
		
		-- Only activate PASSIVE abilities on equip (cooldown = 0)
		-- Active abilities (cooldown > 0) should only be triggered by player input
		local newAbility = Marbles.getAbilityModule(def)
		if newAbility and newAbility.ActivateAbility then
			local cooldown = newAbility.Cooldown and newAbility.Cooldown() or 0
			if cooldown == 0 then
				-- Passive ability - activate automatically on equip
				dprint("Activating passive marble ability on equip:", def.id)
				local success, error = pcall(function()
					newAbility.ActivateAbility(player, character)
				end)
				if not success then
					dprint("Failed to activate passive marble ability on equip:", error)
				end
			else
				dprint("Skipping active ability on equip (requires manual activation):", def.id)
			end
		end
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
	-- Load data from DataStore first
	loadPlayerData(player)
	
	-- Wait a moment for DataStore to load, then use the data
	task.wait(0.5)
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
	-- Save data before player leaves
	if playerData[player] then
		savePlayerData(player)
	end
	
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
	dataStoreCache[player] = nil
end)

-- Start position recording loop for time travel ability
RunService.Heartbeat:Connect(function()
	if not positionRecordingEnabled then return end
	
	for player, _ in pairs(playerData) do
		if player and player.Parent then
			recordPlayerPosition(player)
		end
	end
end)

-- Export functions for other services
-- Store in global table so other scripts can access even if require fails
_G.MarbleService = MarbleService 