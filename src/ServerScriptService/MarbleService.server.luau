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
local positionRecordingInterval = 0.1 -- Record every 0.1 seconds (10fps) instead of every frame to reduce data ping
local lastPositionRecordTime: { [Player]: number } = {}

-- Debounce DataStore saves to prevent throttling during rapid changes
local saveDebounce: { [Player]: thread? } = {}
local SAVE_DEBOUNCE_TIME = 2 -- Save after 2 seconds of no changes

-- Function to immediately save player data to DataStore (used for player leave)
local function savePlayerDataImmediate(player: Player)
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

-- Function to save player data to DataStore (with debouncing to reduce data ping)
local function savePlayerData(player: Player)
	local data = playerData[player]
	if not data then return end
	
	-- Cancel previous save attempt for this player
	if saveDebounce[player] then
		task.cancel(saveDebounce[player])
		saveDebounce[player] = nil
	end
	
	-- Schedule new save after debounce time
	saveDebounce[player] = task.delay(SAVE_DEBOUNCE_TIME, function()
		saveDebounce[player] = nil
		savePlayerDataImmediate(player)
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
	-- Throttle recording based on interval
	local lastRecord = lastPositionRecordTime[player]
	local currentTime = tick()
	if lastRecord and (currentTime - lastRecord) < positionRecordingInterval then
		return -- Skip if not enough time has passed
	end
	lastPositionRecordTime[player] = currentTime
	
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

	-- Remove all existing nameplates to prevent duplicates
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "Nameplate" and child:IsA("BillboardGui") then
			child:Destroy()
		end
	end

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
	character:SetAttribute("FlashGlowActive", false)
	
	-- Set coin multipliers for Gold and Diamond marbles (passive effect)
	if marbleId == "Gold" then
		character:SetAttribute("GoldMultiplier", 5.0) -- 5x coins
		dprint("Set GoldMultiplier to 5.0 for Gold marble")
	elseif marbleId == "Diamond" then
		character:SetAttribute("DiamondMultiplier", 10.0) -- 10x coins
		dprint("Set DiamondMultiplier to 10.0 for Diamond marble")
	else
		-- Clear multipliers for other marbles
		character:SetAttribute("GoldMultiplier", nil)
		character:SetAttribute("DiamondMultiplier", nil)
	end
	
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

-- Launch pad system: Detects parts named "Launch", "Launch2", "Launch3", etc. and launches players upward
local function setupLaunchSystem()
	print("[LaunchSystem] Initializing launch pad system...")
	
	local BASE_JUMP_FORCE = 75 -- Base jump force (will be multiplied by launch number)
	
	-- Extract launch multiplier from part name (e.g., "Launch2" -> 2, "Launch" -> 1)
	local function getLaunchMultiplier(partName: string): number
		-- Check if name starts with "Launch"
		if not partName:match("^Launch") then
			return 0 -- Not a launch part
		end
		
		-- Extract number after "Launch" (e.g., "Launch2" -> 2, "Launch" -> 1)
		local numberStr = partName:match("^Launch(%d+)$")
		if numberStr then
			return tonumber(numberStr) or 1
		elseif partName == "Launch" then
			return 1 -- "Launch" with no number = multiplier of 1
		else
			return 0 -- Invalid format
		end
	end
	
	-- Find all parts named "Launch", "Launch2", "Launch3", etc. in workspace
	local function setupLaunchPart(part: Part)
		local multiplier = getLaunchMultiplier(part.Name)
		if multiplier > 0 and part:IsA("Part") then
			-- Ensure the part can be touched
			part.CanTouch = true
			part.CanCollide = true
			
			-- Track recent launches to prevent spam (per part, not global)
			local recentLaunches: { [Player]: number } = {}
			local LAUNCH_COOLDOWN = 0.5 -- 0.5 second cooldown between launches
			
			local launchForce = BASE_JUMP_FORCE * multiplier
			print("[LaunchSystem] Setting up Launch part:", part:GetFullName(), "Multiplier:", multiplier, "Force:", launchForce)
			
			part.Touched:Connect(function(hit)
				-- Debug: log that touch was detected
				print("[LaunchSystem] Launch part touched by:", hit:GetFullName(), "Type:", hit.ClassName)
				
				-- Find the character from the hit part
				local character = hit:FindFirstAncestorOfClass("Model")
				if not character then 
					print("[LaunchSystem] No character found for hit:", hit:GetFullName())
					return 
				end
				
				print("[LaunchSystem] Found character:", character.Name)
				
				local player = Players:GetPlayerFromCharacter(character)
				if not player then 
					print("[LaunchSystem] No player found for character:", character.Name)
					return 
				end
				
				print("[LaunchSystem] Found player:", player.Name)
				
				-- Check if this is a marble character
				local isMarble = character:GetAttribute("IsMarbleCharacter")
				print("[LaunchSystem] IsMarbleCharacter attribute:", isMarble)
				if not isMarble then 
					print("[LaunchSystem] Character is not a marble character:", character.Name)
					return 
				end
				
				-- Check cooldown to prevent spam
				local lastLaunch = recentLaunches[player]
				local currentTime = tick()
				if lastLaunch and (currentTime - lastLaunch) < LAUNCH_COOLDOWN then
					print("[LaunchSystem] Launch on cooldown for player:", player.Name, "Time remaining:", LAUNCH_COOLDOWN - (currentTime - lastLaunch))
					return
				end
				recentLaunches[player] = currentTime
				
				-- Set attribute to tell client to apply launch force (client handles velocity in RenderStepped)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp and hrp:IsA("BasePart") then
					local currentVel = hrp.AssemblyLinearVelocity
					
					print("[LaunchSystem] Applying launch to player:", player.Name, "Current Y velocity:", currentVel.Y, "Launch force:", launchForce, "Multiplier:", multiplier)
					
					-- Set attributes to tell client this is an intentional launch with specific force
					-- Client will handle the actual velocity application in RenderStepped (like jump boost)
					character:SetAttribute("LaunchActive", true)
					character:SetAttribute("LaunchForce", launchForce)
					
					-- Clear the attributes after launch completes (0.1 seconds - just enough for client to apply it)
					task.spawn(function()
						task.wait(0.1)
						if character and character.Parent then
							character:SetAttribute("LaunchActive", false)
							character:SetAttribute("LaunchForce", nil)
						end
					end)
					
					print("[LaunchSystem] SUCCESS: Player", player.Name, "touched launch pad", part.Name, "- LaunchActive attribute set with force", launchForce)
				else
					print("[LaunchSystem] ERROR: No HumanoidRootPart found for character:", character.Name, "HRP:", hrp)
				end
			end)
			
			print("[LaunchSystem] Launch part setup complete:", part:GetFullName())
		end
	end
	
	-- Setup existing launch parts
	local foundCount = 0
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("Part") then
			local multiplier = getLaunchMultiplier(part.Name)
			if multiplier > 0 then
				print("[LaunchSystem] Found Launch part:", part:GetFullName(), "Multiplier:", multiplier)
				setupLaunchPart(part)
				foundCount = foundCount + 1
			end
		end
	end
	print("[LaunchSystem] Found", foundCount, "Launch parts in workspace")
	
	-- Monitor for new launch parts
	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Part") then
			local multiplier = getLaunchMultiplier(descendant.Name)
			if multiplier > 0 then
				print("[LaunchSystem] New Launch part detected:", descendant:GetFullName(), "Multiplier:", multiplier)
				task.wait(0.1) -- Small delay to ensure part is fully loaded
				setupLaunchPart(descendant)
			end
		end
	end)
end

-- Initialize launch system
print("[MarbleService] Calling setupLaunchSystem()...")
setupLaunchSystem()
print("[MarbleService] setupLaunchSystem() completed")

-- Void detection system: Respawn players who fall below the map
local VOID_Y_THRESHOLD = -100 -- Players below this Y coordinate are considered "in the void"
local VOID_CHECK_INTERVAL = 0.5 -- Check every 0.5 seconds instead of every frame to reduce data ping

local function setupVoidDetection()
	-- Check all players periodically for void detection (throttled to reduce data ping)
	local lastVoidCheckTime = 0
	RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		if (currentTime - lastVoidCheckTime) < VOID_CHECK_INTERVAL then
			return -- Skip if not enough time has passed
		end
		lastVoidCheckTime = currentTime
		
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
		dropDenominator = rolled.dropDenominator,
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
	
	-- Clear cooldown when switching marbles
	abilityCooldowns[player] = nil
	dprint("Cleared ability cooldown for player:", player.Name, "when switching to marble:", marbleId)
	
	-- Notify client to clear cooldown
	Remotes.AbilityCooldown:FireClient(player, {
		duration = 0,
		startTime = 0,
		clear = true, -- Signal to clear cooldown
	})
	
	data.equipped = marbleId
	sendInventory(player)
	savePlayerData(player) -- Save to DataStore
	
	-- In-place switch: update current character instead of respawn
	if character and character.Parent then
		clearHRPTextures(character)
		applyMarbleVisual(character, marbleId)
		ensureNameplate(character, player, marbleId)
		
		-- Set coin multipliers for Gold and Diamond marbles (passive effect)
		if marbleId == "Gold" then
			character:SetAttribute("GoldMultiplier", 5.0) -- 5x coins
			character:SetAttribute("DiamondMultiplier", nil) -- Clear Diamond multiplier
			dprint("Set GoldMultiplier to 5.0 for Gold marble on equip")
		elseif marbleId == "Diamond" then
			character:SetAttribute("DiamondMultiplier", 10.0) -- 10x coins
			character:SetAttribute("GoldMultiplier", nil) -- Clear Gold multiplier
			dprint("Set DiamondMultiplier to 10.0 for Diamond marble on equip")
		else
			-- Clear multipliers for other marbles
			character:SetAttribute("GoldMultiplier", nil)
			character:SetAttribute("DiamondMultiplier", nil)
		end
		
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
	
	-- Wait 1 second before spawning character to let everything catch up
	task.wait(1)
	respawnEquipped(player)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Cancel any pending debounced save
	if saveDebounce[player] then
		task.cancel(saveDebounce[player])
		saveDebounce[player] = nil
	end
	
	-- Force immediate save before player leaves (no debounce)
	if playerData[player] then
		savePlayerDataImmediate(player)
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
	lastPositionRecordTime[player] = nil -- Clean up position recording time
	saveDebounce[player] = nil -- Clean up save debounce
end)

-- Start position recording loop for time travel ability
-- Use a throttled approach to reduce data ping
local lastPositionLoopTime = 0
RunService.Heartbeat:Connect(function()
	if not positionRecordingEnabled then return end
	
	-- Only run position recording at the specified interval
	local currentTime = tick()
	if (currentTime - lastPositionLoopTime) < positionRecordingInterval then
		return
	end
	lastPositionLoopTime = currentTime
	
	-- Only check players who might have TimeTravel equipped
	for player, _ in pairs(playerData) do
		if player and player.Parent then
			-- Quick check: only record if player has TimeTravel equipped
			local data = playerData[player]
			if data and data.equipped then
				local def = Marbles.getById(data.equipped)
				if def and def.abilityModule == "TimeTravel" then
					recordPlayerPosition(player)
				end
			end
		end
	end
end)

-- Export functions for other services
-- Store in global table so other scripts can access even if require fails
_G.MarbleService = MarbleService 