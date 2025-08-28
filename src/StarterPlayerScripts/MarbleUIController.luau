-- MarbleUIController.luau
-- Main controller that orchestrates all UI modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Import modules
local UIComponents = require(script.Parent.UIComponents)
local CooldownSystem = require(script.Parent.CooldownSystem)
local InventorySystem = require(script.Parent.InventorySystem)
local BadgeSystem = require(script.Parent.BadgeSystem)
local RollAnimation = require(script.Parent.RollAnimation)

local MarbleUIController = {}

-- State variables
local localPlayer = Players.LocalPlayer
local playerGui: PlayerGui? = nil
local screen: ScreenGui? = nil

-- UI element references
local powerButton: TextButton? = nil
local powerCooldown: Frame? = nil
local cooldownText: TextLabel? = nil
local textShadow: TextLabel? = nil
local rollButton: TextButton? = nil
local inventoryButton: TextButton? = nil
local badgesButton: TextButton? = nil
local resultLabel: TextLabel? = nil
local invFrame: Frame? = nil
local invCloseButton: TextButton? = nil
local invList: ScrollingFrame? = nil
local invGrid: UIGridLayout? = nil
local badgesFrame: Frame? = nil
local badgesCloseButton: TextButton? = nil
local badgesList: ScrollingFrame? = nil
local badgesGrid: UIGridLayout? = nil
local invOpenSfx: Sound? = nil

-- Remote events
local RemotesFolder: Folder? = nil
local RollForMarble: RemoteEvent? = nil
local EquipMarble: RemoteEvent? = nil
local InventoryUpdate: RemoteEvent? = nil
local RollResult: RemoteEvent? = nil
local RequestInventory: RemoteEvent? = nil
local ActivateAbility: RemoteEvent? = nil
local AbilityCooldown: RemoteEvent? = nil

-- Marbles module
local Marbles: any? = nil

-- Roll animation callback
local currentRollCallback: (() -> ())? = nil

-- Function to wait for PlayerGui to be ready
local function waitForPlayerGui()
	print("Waiting for PlayerGui...")
	playerGui = localPlayer:WaitForChild("PlayerGui")
	print("PlayerGui found:", playerGui ~= nil)
	
	-- Wait a bit more to ensure PlayerGui is fully initialized
	task.wait(0.1)
	
	if not playerGui then
		error("PlayerGui not found after WaitForChild!")
	end
	
	return playerGui
end

-- Function to wait for remote events
local function waitForRemotes()
	RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	RollForMarble = RemotesFolder:WaitForChild("RollForMarble")
	EquipMarble = RemotesFolder:WaitForChild("EquipMarble")
	InventoryUpdate = RemotesFolder:WaitForChild("InventoryUpdate")
	RollResult = RemotesFolder:WaitForChild("RollResult")
	RequestInventory = RemotesFolder:WaitForChild("RequestInventory")
	ActivateAbility = RemotesFolder:WaitForChild("ActivateAbility")
	AbilityCooldown = RemotesFolder:WaitForChild("AbilityCooldown")
end

-- Function to wait for Marbles module
local function waitForMarblesModule()
	Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))
	
	-- Debug: Log all available marbles and their definitions
	print("=== Marble Definitions ===")
	local allMarbles = Marbles.getAll()
	for _, marble in ipairs(allMarbles) do
		print(string.format("Marble: %s, abilityModule: %s, rollable: %s", 
			marble.id, 
			marble.abilityModule or "nil", 
			tostring(marble.rollable)))
	end
	print("=== End Marble Definitions ===")
end

-- Function to create all UI elements
local function createUI()
	print("=== Starting UI Construction ===")
	
	-- Create main screen
	screen = UIComponents.createScreenGui()
	screen.Parent = playerGui
	print("ScreenGui created and parented")
	
	-- Create power button with cooldown
	powerButton, powerCooldown, cooldownText, textShadow = UIComponents.createPowerButton(screen)
	print("Power button created")
	
	-- Create roll button
	rollButton = UIComponents.createRollButton(screen)
	print("Roll button created")
	
	-- Create inventory button
	inventoryButton = UIComponents.createInventoryButton(screen)
	print("Inventory button created")
	
	-- Create badges button
	badgesButton = UIComponents.createBadgesButton(screen)
	print("Badges button created")
	
	-- Create result label
	resultLabel = UIComponents.createResultLabel(screen)
	print("Result label created")
	
	-- Create inventory frame
	invFrame, invCloseButton, invList, invGrid = UIComponents.createInventoryFrame(screen)
	print("Inventory frame created")
	
	-- Create badges frame
	badgesFrame, badgesCloseButton, badgesList, badgesGrid = UIComponents.createBadgesFrame(screen)
	print("Badges frame created")
	
	-- Create sound effects
	invOpenSfx = UIComponents.createSoundEffects(screen)
	print("Sound effects created")
	
	-- Set up grid canvas size refresh
	invGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		InventorySystem.refreshCanvasSize(invList, invGrid)
	end)
	
	-- Set up badges grid canvas size refresh
	badgesGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		BadgeSystem.refreshCanvasSize(badgesList, badgesGrid)
	end)
	
	print("=== UI Construction Complete ===")
end

-- Function to update power button based on equipped marble
local function updatePowerButtonForMarble()
	print("updatePowerButtonForMarble - start")
	
	-- Safety check: only run if UI elements exist
	if not (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		print("updatePowerButtonForMarble: UI not ready, skipping...")
		return
	end
	
	print("updatePowerButtonForMarble: UI elements ready")
	
	-- Process any pending cooldowns now that UI is ready
	CooldownSystem.processPendingCooldown(powerButton, powerCooldown, cooldownText, textShadow)
	
	-- Process any pending inventory updates now that UI is ready
	if InventorySystem.processPendingInventoryUpdate() then
		-- Update the power button
		updatePowerButtonForMarble()
		return
	end
	
	if CooldownSystem.isOnCooldown() then
		print("updatePowerButtonForMarble: on cooldown, returning")
		return -- Don't override cooldown state
	end
	
	print("updatePowerButtonForMarble: starting update")
	local equippedId = InventorySystem.getEquippedId()
	print("equippedId:", equippedId)
	
	-- Safety check: ensure Marbles module is available
	if not Marbles or not Marbles.getById then
		print("updatePowerButtonForMarble: Marbles module not available, skipping")
		return
	end
	
	local equippedMarble = equippedId and Marbles.getById(equippedId)
	print("equippedMarble:", equippedMarble)
	
	if equippedMarble then
		print("equippedMarble.id:", equippedMarble.id)
		print("equippedMarble.name:", equippedMarble.name)
		print("equippedMarble.abilityModule:", equippedMarble.abilityModule)
	end
	
	-- Check if equipped marble has abilities (Spider, Red, etc.)
	if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
		print("Setting power button to ENABLED")
		if powerButton and powerButton.Parent then
			powerButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
			powerButton.Text = "Power (E)"
			powerButton.TextColor3 = Color3.new(1, 1, 1)
		end
	else
		print("Setting power button to DISABLED")
		if powerButton and powerButton.Parent then
			powerButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			powerButton.Text = "Power (None)"
			powerButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end
end

-- Function to check if UI is fully ready
local function isUIReady()
	local powerButtonReady = powerButton and powerButton.Parent
	local powerCooldownReady = powerCooldown and powerCooldown.Parent
	local cooldownTextReady = cooldownText and cooldownText.Parent
	local textShadowReady = textShadow and textShadow.Parent
	
	-- Debug output for troubleshooting
	if not powerButtonReady or not powerCooldownReady or not cooldownTextReady or not textShadowReady then
		print("isUIReady check failed:")
		print("  powerButton:", powerButton ~= nil, "Parent:", powerButton and powerButton.Parent ~= nil)
		print("  powerCooldown:", powerCooldown ~= nil, "Parent:", powerCooldown and powerCooldown.Parent ~= nil)
		print("  cooldownText:", cooldownText ~= nil, "Parent:", cooldownText and cooldownText.Parent ~= nil)
		print("  textShadow:", textShadow ~= nil, "Parent:", textShadow and textShadow.Parent ~= nil)
	end
	
	return powerButtonReady and powerCooldownReady and cooldownTextReady and textShadowReady
end

-- Function to wait for UI to be ready
local function waitForUIReady()
	local maxAttempts = 50 -- Wait up to 5 seconds
	local attempts = 0
	
	print("waitForUIReady: Starting wait loop...")
	
	while not isUIReady() and attempts < maxAttempts do
		attempts = attempts + 1
		print("Waiting for UI to be ready, attempt:", attempts, "/", maxAttempts)
		task.wait(0.1)
	end
	
	if isUIReady() then
		print("UI is now ready!")
		return true
	else
		print("UI failed to become ready after", maxAttempts, "attempts")
		return false
	end
end

-- Function to set up event handlers
local function setupEventHandlers()
	-- Power button click handler
	powerButton.MouseButton1Click:Connect(function()
		if not CooldownSystem.isOnCooldown() then
			print("Power button clicked - checking for ability")
			local equippedId = InventorySystem.getEquippedId()
			local equippedMarble = equippedId and Marbles.getById(equippedId)
			if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
				print("Activating ability for marble:", equippedMarble.id, "Ability module:", equippedMarble.abilityModule)
				ActivateAbility:FireServer()
			else
				print("Power button clicked but no ability available")
			end
		else
			print("Power button clicked but on cooldown")
		end
	end)
	
	-- Roll button click handler
	rollButton.MouseButton1Click:Connect(function()
		currentRollCallback = RollAnimation.startRollAnimation(screen, Marbles, RollForMarble)
	end)
	
	-- Inventory button click handler
	inventoryButton.MouseButton1Click:Connect(function()
		local newVisible = not invFrame.Visible
		invFrame.Visible = newVisible
		-- Hide badges frame when opening inventory
		if newVisible then
			badgesFrame.Visible = false
			pcall(function()
				invOpenSfx:Play()
			end)
		end
	end)
	
	-- Inventory close button handler
	invCloseButton.MouseButton1Click:Connect(function()
		invFrame.Visible = false
	end)
	
	-- Badges button click handler
	badgesButton.MouseButton1Click:Connect(function()
		local newVisible = not badgesFrame.Visible
		badgesFrame.Visible = newVisible
		-- Hide inventory frame when opening badges
		if newVisible then
			invFrame.Visible = false
			-- Build badges UI when opening
			BadgeSystem.rebuildBadgesUI(badgesList, badgesGrid)
			pcall(function()
				invOpenSfx:Play()
			end)
		end
	end)
	
	-- Badges close button handler
	badgesCloseButton.MouseButton1Click:Connect(function()
		badgesFrame.Visible = false
	end)
	
	-- Inventory update handler
	InventoryUpdate.OnClientEvent:Connect(function(payload)
		print("InventoryUpdate received")
		
		-- If UI is not ready, store the update for later processing
		if not isUIReady() then
			InventorySystem.queueInventoryUpdate(payload)
			return
		end
		
		-- UI is ready, process the update immediately
		print("InventoryUpdate: UI is ready, processing update immediately")
		InventorySystem.updateInventory(payload)
		InventorySystem.rebuildInventoryUI(invList, invGrid, Marbles, EquipMarble)
		updatePowerButtonForMarble()
	end)
	
	-- Roll result handler
	RollResult.OnClientEvent:Connect(function(result)
		print("RollResult received:", result.success, result.marbleName or result.marbleId or "nil")
		
		-- Call the roll callback to complete the animation
		if currentRollCallback then
			print("Calling roll callback to complete animation")
			currentRollCallback()
			currentRollCallback = nil
		else
			print("No roll callback found - animation may have already completed")
		end
		
		-- Handle the result in the roll animation system
		RollAnimation.handleRollResult(result)
	end)
	
	-- Ability cooldown handler
	AbilityCooldown.OnClientEvent:Connect(function(cooldownData)
		print("AbilityCooldown received:", cooldownData.duration, "seconds")
		CooldownSystem.startPowerCooldown(cooldownData.duration, powerButton, powerCooldown, cooldownText, textShadow)
	end)
	
	-- E key handler for ability activation
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		
		if input.KeyCode == Enum.KeyCode.E then
			if not CooldownSystem.isOnCooldown() then
				local equippedId = InventorySystem.getEquippedId()
				local equippedMarble = equippedId and Marbles.getById(equippedId)
				if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
					print("Activating ability via E key for marble:", equippedMarble.id, "Ability module:", equippedMarble.abilityModule)
					ActivateAbility:FireServer()
				else
					print("E key pressed but no ability available")
				end
			else
				-- Check if cooldown should actually be finished
				local remaining = CooldownSystem.getRemainingTime()
				if remaining <= 0.1 then
					print("Cooldown time expired but state not reset, forcing reset")
					CooldownSystem.forceResetCooldown(powerButton, powerCooldown, cooldownText, textShadow)
					
					-- Now try to activate the ability
					local equippedId = InventorySystem.getEquippedId()
					local equippedMarble = equippedId and Marbles.getById(equippedId)
					if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
						print("Activating ability after cooldown reset for marble:", equippedMarble.id, "Ability module:", equippedMarble.abilityModule)
						ActivateAbility:FireServer()
					end
				else
					print("E key pressed but on cooldown - Remaining time:", remaining, "seconds")
				end
			end
		end
		
		-- Debug: Force reset cooldown with R key
		if input.KeyCode == Enum.KeyCode.R then
			print("R key pressed - forcing cooldown reset")
			CooldownSystem.forceResetCooldown(powerButton, powerCooldown, cooldownText, textShadow)
		end
	end)
end

-- Function to set up periodic UI health check
local function setupHealthCheck()
	task.spawn(function()
		while true do
			task.wait(5) -- Check every 5 seconds
			
			-- Only check if we're supposed to have UI elements
			if isUIReady() then
				-- If cooldown should be active but UI is not showing it, restore it
				if CooldownSystem.shouldPreserveCooldown() then
					local remaining = CooldownSystem.getRemainingTime()
					if remaining > 0.1 then
						print("UI health check: Cooldown should be preserved, restoring UI display")
						CooldownSystem.updatePowerButtonCooldown(powerButton, powerCooldown, cooldownText, textShadow)
					end
				end
			end
		end
	end)
end

-- Function to initialize the UI controller
function MarbleUIController.init()
	print("=== MarbleUIController Initialization ===")
	
	-- Wait for dependencies
	waitForPlayerGui()
	waitForRemotes()
	waitForMarblesModule()
	
	-- Create UI
	createUI()
	
	-- Set up event handlers
	setupEventHandlers()
	
	-- Wait for UI to be ready
	if waitForUIReady() then
		print("UI is fully ready and initialized!")
		-- Now that UI is ready, process any pending updates
		CooldownSystem.processPendingCooldown(powerButton, powerCooldown, cooldownText, textShadow)
		if InventorySystem.processPendingInventoryUpdate() then
			updatePowerButtonForMarble()
		end
	else
		print("WARNING: UI failed to become ready!")
	end
	
	-- Set up health check
	setupHealthCheck()
	
	-- Request initial inventory
	RequestInventory:FireServer()
	
	-- Initialize badges UI
	BadgeSystem.rebuildBadgesUI(badgesList, badgesGrid)
	
	print("=== MarbleUIController Initialization Complete ===")
end

return MarbleUIController
