-- Marble UI LocalScript
-- Builds a simple UI with:
-- - Roll for Marble button
-- - Power button with cooldown
-- - Inventory toggle button and grid of marbles to equip

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
print("LocalPlayer found:", localPlayer ~= nil)

-- Wait for PlayerGui to be ready
print("Waiting for PlayerGui...")
local playerGui = localPlayer:WaitForChild("PlayerGui")
print("PlayerGui found:", playerGui ~= nil)
print("PlayerGui Parent:", playerGui and playerGui.Parent ~= nil)

-- Additional safety check for PlayerGui
if not playerGui then
	error("PlayerGui not found after WaitForChild!")
end

-- Wait a bit more to ensure PlayerGui is fully initialized
task.wait(0.1)
print("PlayerGui after delay:", playerGui ~= nil, "Parent:", playerGui and playerGui.Parent ~= nil)

-- Check if PlayerGui is in the right place
print("PlayerGui ClassName:", playerGui and playerGui.ClassName)
print("PlayerGui Name:", playerGui and playerGui.Name)
print("PlayerGui Parent ClassName:", playerGui and playerGui.Parent and playerGui.Parent.ClassName)
print("PlayerGui Parent Name:", playerGui and playerGui.Parent and playerGui.Parent.Name)

-- Check if we're in the right context
print("Current script context:", script.ClassName)
print("Script Parent:", script.Parent and script.Parent.Name)
print("Script Parent ClassName:", script.Parent and script.Parent.ClassName)

-- Verify StarterGui service
local starterGui = game:GetService("StarterGui")
print("StarterGui service found:", starterGui ~= nil)
print("StarterGui Parent:", starterGui and starterGui.Parent ~= nil)

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RollForMarble: RemoteEvent = RemotesFolder:WaitForChild("RollForMarble")
local EquipMarble: RemoteEvent = RemotesFolder:WaitForChild("EquipMarble")
local InventoryUpdate: RemoteEvent = RemotesFolder:WaitForChild("InventoryUpdate")
local RollResult: RemoteEvent = RemotesFolder:WaitForChild("RollResult")
local RequestInventory: RemoteEvent = RemotesFolder:WaitForChild("RequestInventory")
local ActivateAbility: RemoteEvent = RemotesFolder:WaitForChild("ActivateAbility")
local AbilityCooldown: RemoteEvent = RemotesFolder:WaitForChild("AbilityCooldown")

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))

-- State variables
local ownedSet: { [string]: boolean } = {}
local equippedId: string? = nil
local powerCooldownTime = 0
local powerCooldownDuration = 0
local isPowerOnCooldown = false
local pendingCooldown: { duration: number, startTime: number }? = nil -- Queue for cooldowns that arrive before UI is ready
local pendingInventoryUpdate: { owned: {string}, equipped: string }? = nil -- Queue for inventory updates that arrive before UI is ready
local updatePowerButtonCooldown_lastLogTime: number? = nil -- For throttling cooldown log messages

-- UI element variables (declared early to fix scope issues)
local screen: ScreenGui? = nil
local powerButton: TextButton? = nil
local powerCooldown: Frame? = nil
local cooldownText: TextLabel? = nil
local textShadow: TextLabel? = nil
local rollButton: TextButton? = nil
local inventoryButton: TextButton? = nil
local resultLabel: TextLabel? = nil
local invFrame: Frame? = nil

-- Cooldown connection
local cooldownConnection: RBXScriptConnection? = nil

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

-- Function to process any pending cooldowns when UI becomes ready
local function processPendingCooldown()
	if pendingCooldown and (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		print("Processing pending cooldown:", pendingCooldown.duration, "seconds")
		local duration = pendingCooldown.duration
		local startTime = pendingCooldown.startTime
		pendingCooldown = nil
		
		-- Start the cooldown with the stored values
		powerCooldownDuration = duration
		powerCooldownTime = startTime
		isPowerOnCooldown = true
		
		print("COOLDOWN LOG: Processing pending cooldown - Duration:", duration, "Start Time:", startTime, "Current Time:", tick())
		
		-- Update the UI to show the cooldown
		updatePowerButtonCooldown()
	end
end

-- Function to process any pending inventory updates when UI becomes ready
local function processPendingInventoryUpdate()
	if pendingInventoryUpdate and (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		print("Processing pending inventory update for equipped marble:", pendingInventoryUpdate.equipped)
		
		-- Apply the pending inventory update
		ownedSet = {}
		for _, id in ipairs(pendingInventoryUpdate.owned) do
			ownedSet[id] = true
			print("Added to ownedSet:", id)
		end
		equippedId = pendingInventoryUpdate.equipped
		print("equippedId set to:", equippedId)
		
		-- Note: rebuildInventoryUI is defined later, skipping for now
		print("Note: Skipping inventory UI rebuild due to scope issues")
		
		-- Update the power button
		updatePowerButtonForMarble()
		
		-- Clear the pending update
		pendingInventoryUpdate = nil
	end
end

-- Function to update power button based on equipped marble (defined early to avoid nil errors)
local function updatePowerButtonForMarble()
	print("updatePowerButtonForMarble - start")
	
	-- Safety check: only run if UI elements exist
	if not (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		print("updatePowerButtonForMarble: UI not ready, skipping...")
		return
	end
	
	print("updatePowerButtonForMarble: UI elements ready, powerButton exists:", powerButton ~= nil)
	print("updatePowerButtonForMarble: powerCooldown exists:", powerCooldown ~= nil)
	print("updatePowerButtonForMarble: cooldownText exists:", cooldownText ~= nil)
	print("updatePowerButtonForMarble: textShadow exists:", textShadow ~= nil)
	
	-- Process any pending cooldowns now that UI is ready
	-- Use the local function directly instead of checking if it exists
	processPendingCooldown()
	
	-- Process any pending inventory updates now that UI is ready
	-- Use the local function directly instead of checking if it exists
	processPendingInventoryUpdate()
	
	if isPowerOnCooldown then
		print("updatePowerButtonForMarble: on cooldown, returning")
		return -- Don't override cooldown state
	end
	
	print("updatePowerButtonForMarble: starting update")
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
		print("equippedMarble.abilityModule type:", typeof(equippedMarble.abilityModule))
		print("equippedMarble.abilityModule ~= 'Default':", equippedMarble.abilityModule ~= "Default")
		
		-- Check if it's exactly "Default" string
		if equippedMarble.abilityModule == "Default" then
			print("abilityModule is exactly 'Default' string")
		elseif equippedMarble.abilityModule == "Spider" then
			print("abilityModule is exactly 'Spider' string")
		elseif equippedMarble.abilityModule == "Red" then
			print("abilityModule is exactly 'Red' string")
		else
			print("abilityModule is something else:", equippedMarble.abilityModule)
		end
	else
		print("No equipped marble found")
	end
	
	-- Check if equipped marble has abilities (Spider, Red, etc.)
	if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
		print("Setting power button to ENABLED")
		-- Final safety check before accessing powerButton
		if powerButton and powerButton.Parent then
			powerButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
			powerButton.Text = "Power (E)"
			powerButton.TextColor3 = Color3.new(1, 1, 1)
		else
			print("updatePowerButtonForMarble: powerButton became invalid during execution")
		end
	else
		print("Setting power button to DISABLED")
		-- No ability or default marble
		-- Final safety check before accessing powerButton
		if powerButton and powerButton.Parent then
			powerButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			powerButton.Text = "Power (None)"
			powerButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		else
			print("updatePowerButtonForMarble: powerButton became invalid during execution")
		end
	end
	
end

-- Function to check if cooldown should still be active based on time
local function shouldCooldownBeActive()
	if not isPowerOnCooldown then
		return false
	end
	
	local remaining = powerCooldownTime + powerCooldownDuration - tick()
	return remaining > 0.1 -- Use the same buffer as other checks
end

-- Function to check if cooldown should be preserved when UI is unavailable
local function shouldPreserveCooldown()
	return shouldCooldownBeActive() and (powerCooldownTime > 0 or powerCooldownDuration > 0)
end

-- Function to safely reset cooldown state (only when appropriate)
local function safeResetCooldown()
	if shouldPreserveCooldown() then
		print("COOLDOWN LOG: Attempted to reset cooldown but it should be preserved, skipping reset")
		return false
	end
	
	print("COOLDOWN LOG: Safely resetting cooldown state")
	isPowerOnCooldown = false
	powerCooldownTime = 0
	powerCooldownDuration = 0
	if cooldownConnection then
		cooldownConnection:Disconnect()
		cooldownConnection = nil
	end
	return true
end

-- Function to validate cooldown state consistency
local function validateCooldownState()
	if isPowerOnCooldown then
		local remaining = powerCooldownTime + powerCooldownDuration - tick()
		if remaining <= 0 then
			print("COOLDOWN LOG: State validation failed - cooldown marked as active but time expired")
			print("COOLDOWN LOG: Forcing cooldown reset due to state inconsistency")
			isPowerOnCooldown = false
			powerCooldownTime = 0
			powerCooldownDuration = 0
			if cooldownConnection then
				cooldownConnection:Disconnect()
				cooldownConnection = nil
			end
			-- Only update UI if elements are available
			if (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
				updatePowerButtonCooldown()
			else
				print("COOLDOWN LOG: UI not ready during validation, skipping update")
			end
			return false
		end
		return true
	else
		if powerCooldownTime > 0 or powerCooldownDuration > 0 then
			print("COOLDOWN LOG: State validation failed - cooldown marked as inactive but has time values")
			print("COOLDOWN LOG: Resetting time values to maintain consistency")
			powerCooldownTime = 0
			powerCooldownDuration = 0
			return false
		end
		return true
	end
end

-- Function to update power button cooldown display (defined before startPowerCooldown)
local function updatePowerButtonCooldown()
	-- Safety check: only run if UI elements exist
	if not (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		-- If UI elements are not available but cooldown should be active, preserve the state
		if shouldPreserveCooldown() then
			print("COOLDOWN LOG: UI not ready but cooldown should be preserved, maintaining state")
			return
		end
		return
	end
	
	-- First, check if cooldown should actually be finished based on time
	local remaining = powerCooldownTime + powerCooldownDuration - tick()
	-- Add a small buffer (0.1 seconds) to prevent premature cooldown resets
	if remaining <= 0.1 and isPowerOnCooldown then
		print("Cooldown time expired, resetting state")
		print("COOLDOWN LOG: Cooldown time expired - Remaining time:", remaining, "seconds")
		print("COOLDOWN LOG: Cooldown duration was:", powerCooldownDuration, "seconds")
		print("COOLDOWN LOG: Cooldown start time was:", powerCooldownTime)
		print("COOLDOWN LOG: Current time is:", tick())
		
		isPowerOnCooldown = false
		powerCooldownTime = 0
		powerCooldownDuration = 0
		
		-- Clean up connection
		if cooldownConnection then
			print("COOLDOWN LOG: Cleaning up cooldown connection (cooldown expired)")
			cooldownConnection:Disconnect()
			cooldownConnection = nil
		end
		
		-- Validate cooldown state consistency
		validateCooldownState()
		
		-- Hide cooldown UI elements
		if powerCooldown and powerCooldown.Parent then
			powerCooldown.Visible = false
		end
		if cooldownText and cooldownText.Parent then
			cooldownText.Visible = false
		end
		if textShadow and textShadow.Parent then
			textShadow.Visible = false
		end
		
		-- Update button to normal state
		local equippedMarble = equippedId and Marbles.getById(equippedId)
		if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
			-- Final safety check before accessing powerButton
			if powerButton and powerButton.Parent then
				powerButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
				powerButton.Text = "Power (E)"
				powerButton.TextColor3 = Color3.new(1, 1, 1)
			end
		else
			-- No ability or default marble
			-- Final safety check before accessing powerButton
			if powerButton and powerButton.Parent then
				powerButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				powerButton.Text = "Power (None)"
				powerButton.TextColor3 = Color3.fromRGB(150, 150, 150)
			end
		end
		return
	end
	
	-- Safety check: prevent infinite recursion
	if not isPowerOnCooldown then
		print("COOLDOWN LOG: No cooldown active, hiding cooldown UI elements")
		print("COOLDOWN LOG: Debug info - powerCooldownTime:", powerCooldownTime, "powerCooldownDuration:", powerCooldownDuration, "Current time:", tick())
		-- Final safety check before accessing UI elements
		if powerCooldown and powerCooldown.Parent then
			powerCooldown.Visible = false
		end
		if cooldownText and cooldownText.Parent then
			cooldownText.Visible = false
		end
		if textShadow and textShadow.Parent then
			textShadow.Visible = false
		end
		
		-- Clean up connection
		if cooldownConnection then
			print("COOLDOWN LOG: Cleaning up cooldown connection (no cooldown active)")
			cooldownConnection:Disconnect()
			cooldownConnection = nil
		end
		
		-- Validate cooldown state consistency
		validateCooldownState()
		
		-- Check if equipped marble has an ability
		local equippedMarble = equippedId and Marbles.getById(equippedId)
		if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
			-- Final safety check before accessing powerButton
			if powerButton and powerButton.Parent then
				powerButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
				powerButton.Text = "Power (E)"
				powerButton.TextColor3 = Color3.new(1, 1, 1)
			end
		else
			-- No ability or default marble
			-- Final safety check before accessing powerButton
			if powerButton and powerButton.Parent then
				powerButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				powerButton.Text = "Power (None)"
				powerButton.TextColor3 = Color3.fromRGB(150, 150, 150)
			end
		end
		return
	end
	
	local progress = remaining / powerCooldownDuration
	-- Final safety check before accessing UI elements
	if powerCooldown and powerCooldown.Parent then
		powerCooldown.Size = UDim2.new(1, 0, progress, 0)
		powerCooldown.Position = UDim2.new(0, 0, 1 - progress, 0)
		powerCooldown.AnchorPoint = Vector2.new(0, 1)
	end
	
	local timeText = string.format("%.1fs", remaining)
	if cooldownText and cooldownText.Parent then
		cooldownText.Text = timeText
		cooldownText.Visible = true
	end
	if textShadow and textShadow.Parent then
		textShadow.Text = timeText
		textShadow.Visible = true
	end
	
	-- Set cooldown state for button
	if powerCooldown and powerCooldown.Parent then
		powerCooldown.Visible = true
	end
	if powerButton and powerButton.Parent then
		powerButton.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
		powerButton.Text = timeText -- Show countdown on button instead of just "Cooldown"
	end
	
	-- Log cooldown progress (only every 0.5 seconds to avoid spam)
	local currentTime = tick()
	-- Use a static variable for lastLogTime instead of trying to add it to the function
	if not updatePowerButtonCooldown_lastLogTime or (currentTime - updatePowerButtonCooldown_lastLogTime) >= 0.5 then
		print("COOLDOWN LOG: Progress update - Remaining:", string.format("%.1f", remaining), "seconds, Progress:", string.format("%.1f%%", progress * 100))
		updatePowerButtonCooldown_lastLogTime = currentTime
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

-- Function to recreate power button UI elements if they become invalid
local function recreatePowerButtonUI()
	print("recreatePowerButtonUI: Recreating power button UI elements...")
	
	-- Check if screen exists
	if not screen or not screen.Parent then
		print("recreatePowerButtonUI: Screen not available, cannot recreate UI")
		return false
	end
	
	-- Clean up old elements if they exist
	if powerButton then
		powerButton:Destroy()
		powerButton = nil
	end
	if powerCooldown then
		powerCooldown:Destroy()
		powerCooldown = nil
	end
	if cooldownText then
		cooldownText:Destroy()
		cooldownText = nil
	end
	if textShadow then
		textShadow:Destroy()
		textShadow = nil
	end
	
	-- Recreate power button
	print("Recreating power button...")
	powerButton = Instance.new("TextButton")
	powerButton.Name = "PowerButton"
	powerButton.Text = "Power (E)"
	powerButton.TextScaled = true
	powerButton.Size = UDim2.fromOffset(200, 56)
	powerButton.Position = UDim2.new(0.5, -110, 1, -24)
	powerButton.AnchorPoint = Vector2.new(0.5, 1)
	powerButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
	powerButton.TextColor3 = Color3.new(1,1,1)
	powerButton.Font = Enum.Font.GothamBold
	powerButton.Parent = screen
	
	local powerCorner = Instance.new("UICorner")
	powerCorner.CornerRadius = UDim.new(0, 8)
	powerCorner.Parent = powerButton
	
	-- Recreate cooldown overlay
	print("Recreating cooldown overlay...")
	powerCooldown = Instance.new("Frame")
	powerCooldown.Name = "CooldownOverlay"
	powerCooldown.Size = UDim2.new(1, 0, 1, 0)
	powerCooldown.Position = UDim2.new(0, 0, 0, 0)
	powerCooldown.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
	powerCooldown.BackgroundTransparency = 0.4
	powerCooldown.Visible = false
	powerCooldown.Parent = powerButton
	
	local cooldownCorner = Instance.new("UICorner")
	cooldownCorner.CornerRadius = UDim.new(0, 8)
	cooldownCorner.Parent = powerCooldown
	
	-- Recreate cooldown text
	print("Recreating cooldown text...")
	cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.Size = UDim2.new(1, 0, 1, 0)
	cooldownText.Position = UDim2.new(0, 0, 0, 0)
	cooldownText.BackgroundTransparency = 1
	cooldownText.Text = ""
	cooldownText.TextScaled = true
	cooldownText.TextColor3 = Color3.new(1, 1, 1)
	cooldownText.Font = Enum.Font.GothamBold
	cooldownText.Visible = false
	cooldownText.Parent = powerButton
	
	-- Recreate text shadow
	print("Recreating text shadow...")
	textShadow = Instance.new("TextLabel")
	textShadow.Name = "TextShadow"
	textShadow.Size = UDim2.new(1, 0, 1, 0)
	textShadow.Position = UDim2.new(0, 1, 0, 1)
	textShadow.BackgroundTransparency = 1
	textShadow.Text = ""
	textShadow.TextScaled = true
	textShadow.TextColor3 = Color3.new(0, 0, 0)
	textShadow.Font = Enum.Font.GothamBold
	textShadow.Visible = false
	textShadow.Parent = powerButton
	textShadow.ZIndex = cooldownText.ZIndex - 1
	
	-- Reconnect the click handler
	powerButton.MouseButton1Click:Connect(function()
		if not isPowerOnCooldown then
			print("COOLDOWN LOG: Power button clicked - No cooldown active, checking for ability")
			-- Check if equipped marble has an ability
			local equippedMarble = equippedId and Marbles.getById(equippedId)
			if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
				print("COOLDOWN LOG: Activating ability for marble:", equippedMarble.id, "Ability module:", equippedMarble.abilityModule)
				ActivateAbility:FireServer()
			else
				print("COOLDOWN LOG: Power button clicked but no ability available - Marble:", equippedId, "Ability module:", equippedMarble and equippedMarble.abilityModule or "nil")
			end
		else
			print("COOLDOWN LOG: Power button clicked but on cooldown - Remaining time:", powerCooldownTime + powerCooldownDuration - tick(), "seconds")
		end
	end)
	
	print("recreatePowerButtonUI: Power button UI elements recreated successfully")
	
	-- If there was an active cooldown, restore it
	if shouldPreserveCooldown() then
		print("COOLDOWN LOG: Restoring cooldown UI after recreation")
		updatePowerButtonCooldown()
	end
	
	return true
end

-- Function to wait for UI to be ready
local function waitForUIReady()
	local maxAttempts = 50 -- Wait up to 5 seconds
	local attempts = 0
	
	print("waitForUIReady: Starting wait loop...")
	
	while not isUIReady() and attempts < maxAttempts do
		attempts = attempts + 1
		print("Waiting for UI to be ready, attempt:", attempts, "/", maxAttempts)
		
		-- Check each element individually
		print("  powerButton:", powerButton ~= nil, "Parent:", powerButton and powerButton.Parent ~= nil)
		print("  powerCooldown:", powerCooldown ~= nil, "Parent:", powerCooldown and powerCooldown.Parent ~= nil)
		print("  cooldownText:", cooldownText ~= nil, "Parent:", cooldownText and cooldownText.Parent ~= nil)
		print("  textShadow:", textShadow ~= nil, "Parent:", textShadow and textShadow.Parent ~= nil)
		
		-- Additional debugging for the screen
		print("  screen:", screen ~= nil, "Parent:", screen and screen.Parent ~= nil)
		if screen then
			print("  screen.Parent:", screen.Parent)
			if screen.Parent then
				print("  screen.Parent.Name:", screen.Parent.Name)
				print("  screen.Parent.ClassName:", screen.Parent.ClassName)
			end
		end
		
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

-- UI construction
print("=== Starting UI Construction ===")
print("playerGui exists:", playerGui ~= nil)
print("playerGui Parent:", playerGui and playerGui.Parent ~= nil)

screen = Instance.new("ScreenGui")
screen.Name = "MarbleUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
print("ScreenGui created:", screen ~= nil)

print("Setting screen.Parent to playerGui...")
screen.Parent = playerGui
print("screen.Parent set:", screen.Parent ~= nil)
print("screen.Parent == playerGui:", screen.Parent == playerGui)

-- Inventory open SFX
local invOpenSfx = Instance.new("Sound")
invOpenSfx.Name = "InventoryOpenSfx"
invOpenSfx.SoundId = "rbxassetid://127877437691780"
invOpenSfx.Volume = 0.6
invOpenSfx.Parent = screen
print("Sound created and parented")

-- Power button with cooldown
print("Creating power button...")
powerButton = Instance.new("TextButton")
powerButton.Name = "PowerButton"
powerButton.Text = "Power (E)"
powerButton.TextScaled = true
powerButton.Size = UDim2.fromOffset(200, 56)
powerButton.Position = UDim2.new(0.5, -110, 1, -24)
powerButton.AnchorPoint = Vector2.new(0.5, 1)
powerButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
powerButton.TextColor3 = Color3.new(1,1,1)
powerButton.Font = Enum.Font.GothamBold
print("powerButton created:", powerButton ~= nil)

print("Setting powerButton.Parent to screen...")
powerButton.Parent = screen
print("powerButton.Parent set:", powerButton.Parent ~= nil)
print("powerButton.Parent == screen:", powerButton.Parent == screen)

local powerCorner = Instance.new("UICorner")
powerCorner.CornerRadius = UDim.new(0, 8)
powerCorner.Parent = powerButton
print("powerCorner created and parented")

-- Cooldown overlay for power button
print("Creating cooldown overlay...")
powerCooldown = Instance.new("Frame")
powerCooldown.Name = "CooldownOverlay"
powerCooldown.Size = UDim2.new(1, 0, 1, 0)
powerCooldown.Position = UDim2.new(0, 0, 0, 0)
powerCooldown.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
powerCooldown.BackgroundTransparency = 0.4
powerCooldown.Visible = false
print("powerCooldown created:", powerCooldown ~= nil)

print("Setting powerCooldown.Parent to powerButton...")
powerCooldown.Parent = powerButton
print("powerCooldown.Parent set:", powerCooldown.Parent ~= nil)
print("powerCooldown.Parent == powerButton:", powerCooldown.Parent == powerButton)

local cooldownCorner = Instance.new("UICorner")
cooldownCorner.CornerRadius = UDim.new(0, 8)
cooldownCorner.Parent = powerCooldown
print("cooldownCorner created and parented")

-- Cooldown text
print("Creating cooldown text...")
cooldownText = Instance.new("TextLabel")
cooldownText.Name = "CooldownText"
cooldownText.Size = UDim2.new(1, 0, 1, 0)
cooldownText.Position = UDim2.new(0, 0, 0, 0)
cooldownText.BackgroundTransparency = 1
cooldownText.Text = ""
cooldownText.TextScaled = true
cooldownText.TextColor3 = Color3.new(1, 1, 1)
cooldownText.Font = Enum.Font.GothamBold
cooldownText.Visible = false
print("cooldownText created:", cooldownText ~= nil)

print("Setting cooldownText.Parent to powerButton...")
cooldownText.Parent = powerButton
print("cooldownText.Parent set:", cooldownText.Parent ~= nil)
print("cooldownText.Parent == powerButton:", cooldownText.Parent == powerButton)

-- Add text shadow for better visibility
print("Creating text shadow...")
textShadow = Instance.new("TextLabel")
textShadow.Name = "TextShadow"
textShadow.Size = UDim2.new(1, 0, 1, 0)
textShadow.Position = UDim2.new(0, 1, 0, 1)
textShadow.BackgroundTransparency = 1
textShadow.Text = ""
textShadow.TextScaled = true
textShadow.TextColor3 = Color3.new(0, 0, 0)
textShadow.Font = Enum.Font.GothamBold
textShadow.Visible = false
print("textShadow created:", textShadow ~= nil)

print("Setting textShadow.Parent to powerButton...")
textShadow.Parent = powerButton
print("textShadow.Parent set:", textShadow.Parent ~= nil)
print("textShadow.Parent == powerButton:", textShadow.Parent == powerButton)

textShadow.ZIndex = cooldownText.ZIndex - 1
print("textShadow ZIndex set")

print("=== UI Construction Complete ===")

-- Debug: Confirm UI elements are created
print("UI elements created:")
print("  powerButton:", powerButton ~= nil)
print("  powerCooldown:", powerCooldown ~= nil)
print("  cooldownText:", cooldownText ~= nil)
print("  textShadow:", textShadow ~= nil)

-- Additional verification of parenting
print("=== Parenting Verification ===")
print("screen exists:", screen ~= nil, "Parent:", screen and screen.Parent ~= nil)
if screen and screen.Parent then
	print("screen.Parent.Name:", screen.Parent.Name)
	print("screen.Parent.ClassName:", screen.Parent.ClassName)
end

print("powerButton exists:", powerButton ~= nil, "Parent:", powerButton and powerButton.Parent ~= nil)
if powerButton and powerButton.Parent then
	print("powerButton.Parent.Name:", powerButton.Parent.Name)
	print("powerButton.Parent.ClassName:", powerButton.Parent.ClassName)
end

print("powerCooldown exists:", powerCooldown ~= nil, "Parent:", powerCooldown and powerCooldown.Parent ~= nil)
if powerCooldown and powerCooldown.Parent then
	print("powerCooldown.Parent.Name:", powerCooldown.Parent.Name)
	print("powerCooldown.Parent.ClassName:", powerCooldown.Parent.ClassName)
end

print("cooldownText exists:", cooldownText ~= nil, "Parent:", cooldownText and cooldownText.Parent ~= nil)
if cooldownText and cooldownText.Parent then
	print("cooldownText.Parent.Name:", cooldownText.Parent.Name)
	print("cooldownText.Parent.ClassName:", cooldownText.Parent.ClassName)
end

print("textShadow exists:", textShadow ~= nil, "Parent:", textShadow and textShadow.Parent ~= nil)
if textShadow and textShadow.Parent then
	print("textShadow.Parent.Name:", textShadow.Parent.Name)
	print("textShadow.Parent.ClassName:", textShadow.Parent.ClassName)
end

print("=== End Parenting Verification ===")

print("=== UI Construction Complete ===")

-- Power button cooldown system (now defined after UI elements are created)
local cooldownConnection: RBXScriptConnection? = nil

local function startPowerCooldown(duration: number)
	print("startPowerCooldown called with duration:", duration)
	print("COOLDOWN LOG: Starting cooldown - Duration:", duration, "Current Time:", tick())
	
	-- If UI is not ready, queue the cooldown instead of waiting
	if not (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		print("startPowerCooldown: UI not ready, queuing cooldown")
		print("COOLDOWN LOG: UI not ready, queuing cooldown for later processing")
		pendingCooldown = {
			duration = duration,
			startTime = tick()
		}
		return
	end
	
	print("startPowerCooldown: UI is ready, proceeding with cooldown")
	print("COOLDOWN LOG: UI ready, proceeding with cooldown initialization")
	
	-- Clean up any existing connection
	if cooldownConnection then
		print("COOLDOWN LOG: Cleaning up existing cooldown connection")
		cooldownConnection:Disconnect()
		cooldownConnection = nil
	end
	
	-- Reset cooldown state
	isPowerOnCooldown = false
	
	powerCooldownDuration = duration
	powerCooldownTime = tick()
	isPowerOnCooldown = true
	
	-- Validate cooldown state consistency
	validateCooldownState()
	
	print("COOLDOWN LOG: Cooldown state set - Duration:", powerCooldownDuration, "Start Time:", powerCooldownTime, "Is On Cooldown:", isPowerOnCooldown)
	
	-- Additional safety check before calling updatePowerButtonCooldown
	if not (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		print("startPowerCooldown: UI became unavailable after setting cooldown state, resetting")
		isPowerOnCooldown = false
		return
	end
	
	updatePowerButtonCooldown()
	
	-- Only create heartbeat connection if UI elements are still ready
	if (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		print("COOLDOWN LOG: Creating heartbeat connection for cooldown updates")
		-- Update cooldown every frame
		cooldownConnection = game:GetService("RunService").Heartbeat:Connect(function()
			if not isPowerOnCooldown then
				print("COOLDOWN LOG: Cooldown finished, disconnecting heartbeat")
				if cooldownConnection then
					cooldownConnection:Disconnect()
					cooldownConnection = nil
				end
				return
			end
			
			-- Check if cooldown time has actually expired
			local remaining = powerCooldownTime + powerCooldownDuration - tick()
			-- Add a small buffer (0.1 seconds) to prevent premature cooldown resets
			if remaining <= 0.1 then
				print("COOLDOWN LOG: Cooldown time expired in heartbeat, resetting state")
				
				-- Use safe reset function
				if safeResetCooldown() then
					-- Update the UI
					updatePowerButtonCooldown()
					
					-- Validate cooldown state consistency
					validateCooldownState()
					
					return
				end
			end
			
			-- Update the cooldown display every frame
			updatePowerButtonCooldown()
			
			-- Validate cooldown state consistency
			validateCooldownState()
			
			-- If UI elements are not available but cooldown should be active, keep the connection alive
			if not (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
				if shouldPreserveCooldown() then
					print("COOLDOWN LOG: UI not ready but cooldown should be preserved, keeping connection alive")
					return
				end
			end
		end)
	else
		print("UI elements disappeared during cooldown start, resetting state")
		print("COOLDOWN LOG: UI elements disappeared during cooldown start, resetting state")
		isPowerOnCooldown = false
		return
	end
	
	-- Safety timeout: force reset cooldown after expected end time + small buffer
	local expectedEndTime = powerCooldownTime + powerCooldownDuration
	task.delay(expectedEndTime - tick() + 0.5, function()
		-- Only trigger safety timeout if cooldown is still active AND should have finished by now
		local currentTime = tick()
		local shouldBeFinished = currentTime >= expectedEndTime
		local shouldBeActive = shouldCooldownBeActive()
		
		if isPowerOnCooldown and shouldBeFinished and not shouldBeActive then
			print("Safety timeout: forcing cooldown reset - Expected end time:", expectedEndTime, "Current time:", currentTime)
			print("COOLDOWN LOG: Safety timeout triggered, forcing cooldown reset")
			
			-- Use safe reset function
			if safeResetCooldown() then
				-- Only update if UI elements still exist
				if (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
					updatePowerButtonCooldown()
				else
					print("Safety timeout: UI not ready, skipping update")
				end
				
				-- Validate cooldown state consistency
				validateCooldownState()
			end
		elseif isPowerOnCooldown and shouldBeFinished and shouldBeActive then
			print("Safety timeout: Cooldown marked as finished but should still be active - Expected end time:", expectedEndTime, "Current time:", currentTime, "Remaining:", expectedEndTime - currentTime)
			print("COOLDOWN LOG: Safety timeout skipped - cooldown still valid, correcting state")
			-- The cooldown should still be active, so don't reset it
		elseif isPowerOnCooldown and not shouldBeFinished then
			print("Safety timeout: Cooldown still active and not expired yet - Expected end time:", expectedEndTime, "Current time:", currentTime, "Remaining:", expectedEndTime - currentTime)
			print("COOLDOWN LOG: Safety timeout skipped - cooldown still valid")
		end
	end)
	
	print("COOLDOWN LOG: Cooldown initialization complete - Duration:", duration, "Start Time:", powerCooldownTime, "Expected End Time:", powerCooldownTime + duration)
end

-- Cleanup function for cooldown system
local function cleanupCooldown()
	-- Safety check: only run if UI elements exist
	if not (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		print("cleanupCooldown: UI not ready, skipping")
		return
	end
	
	print("cleanupCooldown: cleaning up cooldown state")
	print("COOLDOWN LOG: Manual cleanup triggered - Current state - Is On Cooldown:", isPowerOnCooldown, "Duration:", powerCooldownDuration, "Start Time:", powerCooldownTime)
	
	if cooldownConnection then
		print("COOLDOWN LOG: Disconnecting cooldown connection during cleanup")
		cooldownConnection:Disconnect()
		cooldownConnection = nil
	end
	
	isPowerOnCooldown = false
	powerCooldown.Visible = false
	cooldownText.Visible = false
	textShadow.Visible = false
	
	-- Reset cooldown variables
	powerCooldownTime = 0
	powerCooldownDuration = 0
	
	-- Clear any pending cooldown
	pendingCooldown = nil
	
	-- Validate cooldown state consistency
	validateCooldownState()
	
	print("cleanupCooldown: cooldown state reset complete")
	print("COOLDOWN LOG: Cleanup complete - All cooldown state reset to default values")
end

-- Force reset function for debugging
local function forceResetCooldown()
	print("forceResetCooldown: forcing cooldown reset")
	print("COOLDOWN LOG: Force reset triggered - Current state - Is On Cooldown:", isPowerOnCooldown, "Duration:", powerCooldownDuration, "Start Time:", powerCooldownTime)
	
	isPowerOnCooldown = false
	powerCooldownTime = 0
	powerCooldownDuration = 0
	pendingCooldown = nil
	
	-- Validate cooldown state consistency
	validateCooldownState()
	
	if cooldownConnection then
		print("COOLDOWN LOG: Disconnecting cooldown connection during force reset")
		cooldownConnection:Disconnect()
		cooldownConnection = nil
	end
	
	-- Only update UI if elements exist
	if (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		updatePowerButtonCooldown()
	end
	
	print("forceResetCooldown: reset complete")
	print("COOLDOWN LOG: Force reset complete - All cooldown state reset to default values")
end

print("Creating roll button...")
rollButton = Instance.new("TextButton")
rollButton.Name = "RollButton"
rollButton.Text = "Roll for Marble"
rollButton.TextScaled = true
rollButton.Size = UDim2.fromOffset(200, 56)
rollButton.Position = UDim2.new(0.5, 110, 1, -24)
rollButton.AnchorPoint = Vector2.new(0.5, 1)
rollButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
rollButton.TextColor3 = Color3.new(1,1,1)
rollButton.Font = Enum.Font.GothamBold
print("rollButton created:", rollButton ~= nil)

print("Setting rollButton.Parent to screen...")
rollButton.Parent = screen
print("rollButton.Parent set:", rollButton.Parent ~= nil)
print("rollButton.Parent == screen:", rollButton.Parent == screen)

local rollCorner = Instance.new("UICorner")
rollCorner.CornerRadius = UDim.new(0, 8)
rollCorner.Parent = rollButton
print("rollCorner created and parented")

print("Creating inventory button...")
inventoryButton = Instance.new("TextButton")
inventoryButton.Name = "InventoryButton"
inventoryButton.Text = "Inventory"
inventoryButton.TextScaled = true
inventoryButton.Size = UDim2.fromOffset(160, 40)
inventoryButton.Position = UDim2.new(0, 16, 0, 16)
inventoryButton.AnchorPoint = Vector2.new(0, 0)
inventoryButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
inventoryButton.TextColor3 = Color3.new(1,1,1)
inventoryButton.Font = Enum.Font.GothamBold
print("inventoryButton created:", inventoryButton ~= nil)

print("Setting inventoryButton.Parent to screen...")
inventoryButton.Parent = screen
print("inventoryButton.Parent set:", inventoryButton.Parent ~= nil)
print("inventoryButton.Parent == screen:", inventoryButton.Parent == screen)

local invBtnCorner = Instance.new("UICorner")
invBtnCorner.CornerRadius = UDim.new(0, 8)
invBtnCorner.Parent = inventoryButton
print("invBtnCorner created and parented")

print("Creating result label...")
resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Text = ""
resultLabel.TextScaled = true
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = Color3.new(1,1,1)
resultLabel.Size = UDim2.fromOffset(480, 40)
resultLabel.Position = UDim2.new(0.5, 0, 1, -88)
resultLabel.AnchorPoint = Vector2.new(0.5, 1)
print("resultLabel created:", resultLabel ~= nil)

print("Setting resultLabel.Parent to screen...")
resultLabel.Parent = screen
print("resultLabel.Parent set:", resultLabel.Parent ~= nil)
print("resultLabel.Parent == screen:", resultLabel.Parent == screen)

print("Creating inventory frame...")
invFrame = Instance.new("Frame")
invFrame.Name = "InventoryFrame"
invFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
invFrame.BackgroundTransparency = 0.2 -- semi-transparent
invFrame.BorderSizePixel = 0
invFrame.Size = UDim2.new(0, 720, 0, 520)
invFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
invFrame.AnchorPoint = Vector2.new(0.5, 0.5)
invFrame.Visible = false
print("invFrame created:", invFrame ~= nil)

print("Setting invFrame.Parent to screen...")
invFrame.Parent = screen
print("invFrame.Parent set:", invFrame.Parent ~= nil)
print("invFrame.Parent == screen:", invFrame.Parent == screen)

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = invFrame

local header = Instance.new("TextLabel")
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, -24, 0, 40)
header.Position = UDim2.new(0, 12, 0, 10)
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Center
header.Text = "Inventory"
header.TextColor3 = Color3.new(1,1,1)
header.TextSize = 24
header.Parent = invFrame

-- Close button (top-right)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextScaled = true
closeButton.Size = UDim2.fromOffset(36, 36)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Parent = invFrame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton
closeButton.MouseButton1Click:Connect(function()
	invFrame.Visible = false
end)

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Size = UDim2.new(1, -24, 1, -80)
list.Position = UDim2.new(0, 12, 0, 60)
list.ScrollBarThickness = 8
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.BackgroundTransparency = 1
list.Parent = invFrame

local grid = Instance.new("UIGridLayout")
grid.FillDirection = Enum.FillDirection.Horizontal
grid.FillDirectionMaxCells = 3 -- 3 columns
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.CellSize = UDim2.fromOffset(200, 200)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = list

local function refreshCanvasSize()
	-- Safety check: ensure required UI elements exist
	if not list or not grid then
		print("refreshCanvasSize: Required UI elements (list or grid) not available, skipping")
		return
	end
	
	local abs = grid.AbsoluteContentSize
	list.CanvasSize = UDim2.new(0, 0, 0, abs.Y + 12)
end
grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvasSize)

-- Ability descriptions by module name (simple mapping for now)
local ABILITY_DESCRIPTIONS: { [string]: string } = {
	Default = "No special ability.",
	SpeedBoost = "Temporarily increases rolling speed.",
	Red = "Red: A fiery burst that briefly increases acceleration.",
	Blue = "Blue: A calming shield that reduces deceleration briefly.",
	Green = "Green: A rejuvenating pulse that boosts control for a moment.",
	Spider = "Spider: Shoot a web to grapple and swing toward targets.",
}

-- Texture fallbacks (should match controller)
local FALLBACK_DECALS: { [string]: string } = {
	Default = "rbxassetid://110926540048461",
	Red = "rbxassetid://99977275020564",
	Green = "rbxassetid://114474679212927",
	Blue = "rbxassetid://128223600665334",
	Spider = "rbxassetid://105354663033087",
}

local function applyTexturesToPart(part: BasePart, marbleId: string)
	-- Clear existing
	for _, ch in ipairs(part:GetChildren()) do
		if ch:IsA("Decal") or ch:IsA("Texture") then ch:Destroy() end
	end
	-- Preferred from ReplicatedStorage
	local texturesRoot = ReplicatedStorage:FindFirstChild("MarbleTextures")
	local folder = texturesRoot and texturesRoot:FindFirstChild(marbleId)
	local assets = {}
	if folder then
		for _, inst in ipairs(folder:GetChildren()) do
			if inst:IsA("Decal") or inst:IsA("Texture") then
				table.insert(assets, inst)
			end
		end
	end
	if #assets == 0 then
		local fallback = FALLBACK_DECALS[marbleId]
		if fallback then
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local d = Instance.new("Decal")
				d.Texture = fallback
				d.Face = face
				d.Parent = part
			end
		end
		return
	end
	if #assets == 1 then
		local src = assets[1]
		for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
			local clone = src:Clone()
			if clone:IsA("Decal") then
				(clone :: Decal).Face = face
			elseif clone:IsA("Texture") then
				(clone :: Texture).Face = face
			end
			clone.Parent = part
		end
		return
	end
	for _, src in ipairs(assets) do
		local clone = src:Clone()
		clone.Parent = part
	end
end

local function getRarityText(def): string
	if def and def.rollable and def.dropDenominator and def.dropDenominator > 0 then
		return string.format(" (1/%d)", def.dropDenominator)
	end
	return ""
end

local function getRarityOnly(def): string
	if def and def.rollable and def.dropDenominator and def.dropDenominator > 0 then
		return string.format("1/%d", def.dropDenominator)
	end
	return ""
end

local function createMarbleTile(def)
	local isOwned = ownedSet[def.id] == true
	local isEquipped = def.id == equippedId

	local tile = Instance.new("Frame")
	tile.Size = UDim2.fromOffset(200, 200)
	tile.BackgroundColor3 = isEquipped and Color3.fromRGB(38, 110, 180) or Color3.fromRGB(40, 40, 40)
	tile.BorderSizePixel = 0

	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 8)
	corner2.Parent = tile

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1, -16, 1, -56)
	viewport.Position = UDim2.new(0, 8, 0, 8)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Parent = tile

	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(6, 6, 6)
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.Parent = world

	if isOwned then
		applyTexturesToPart(sphere, def.id)
		if #sphere:GetChildren() == 0 and def.color then
			sphere.Color = def.color
		end
	else
		-- Locked appearance: dark swatch with big question mark
		sphere.Color = Color3.fromRGB(60,60,60)
		local q = Instance.new("BillboardGui")
		q.Size = UDim2.fromOffset(120, 120)
		q.AlwaysOnTop = true
		q.Adornee = sphere
		q.Parent = world
		local ql = Instance.new("TextLabel")
		ql.BackgroundTransparency = 1
		ql.Text = "?"
		ql.TextScaled = true
		ql.Font = Enum.Font.GothamBold
		ql.TextColor3 = Color3.new(1,1,1)
		ql.Size = UDim2.fromScale(1,1)
		ql.Parent = q
	end

	-- Camera
	local cam = Instance.new("Camera")
	viewport.CurrentCamera = cam
	cam.Parent = viewport
	local center = Vector3.new(0, 0, 0)
	sphere.Position = center
	cam.CFrame = CFrame.new(center + Vector3.new(0, 0, 12), center)

	-- Name or rarity label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, -16, 0, 16)
	nameLabel.Position = UDim2.new(0, 8, 1, -44)
	nameLabel.Text = isOwned and (def.name .. getRarityText(def)) or getRarityOnly(def)
	nameLabel.TextColor3 = Color3.new(1,1,1)
	nameLabel.TextScaled = true
	nameLabel.Parent = tile

	-- Status label
	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Size = UDim2.new(1, -16, 0, 20)
	status.Position = UDim2.new(0, 8, 1, -24)
	status.TextScaled = true
	status.TextColor3 = isOwned and (isEquipped and Color3.fromRGB(180, 255, 180) or Color3.fromRGB(220, 220, 220)) or Color3.fromRGB(220, 180, 180)
	status.Text = isOwned and (isEquipped and "Equipped" or "Not Equipped") or "Locked"
	status.Parent = tile

	-- Equip interaction (only if owned)
	if isOwned then
		local equipButton = Instance.new("TextButton")
		equipButton.BackgroundTransparency = 1
		equipButton.Size = UDim2.fromScale(1, 1)
		equipButton.Text = ""
		equipButton.Parent = tile
		equipButton.MouseButton1Click:Connect(function()
			if def.id ~= equippedId then
				EquipMarble:FireServer(def.id)
			end
		end)
	end

	return tile
end

local function rebuildInventoryUI()
	-- Safety check: ensure required UI elements exist
	if not list or not grid then
		print("rebuildInventoryUI: Required UI elements (list or grid) not available, skipping")
		return
	end
	
	-- Safety check: ensure Marbles module is available
	if not Marbles or not Marbles.getAll then
		print("rebuildInventoryUI: Marbles module not available, skipping")
		return
	end
	
	-- Clear existing tiles but keep grid
	for _, child in ipairs(list:GetChildren()) do
		if child ~= grid then
			child:Destroy()
		end
	end
	for _, def in ipairs(Marbles.getAll()) do
		local tile = createMarbleTile(def)
		tile.Parent = list
	end
	refreshCanvasSize()
end

-- CSGO-style rolling system
local isRolling = false
local rollAnimationFrame: Frame? = nil
local rollAnimationText: TextLabel? = nil
local rollAnimationShadow: TextLabel? = nil

local function createRollAnimationUI()
	if rollAnimationFrame then
		rollAnimationFrame:Destroy()
	end
	
	rollAnimationFrame = Instance.new("Frame")
	rollAnimationFrame.Name = "RollAnimationFrame"
	rollAnimationFrame.Size = UDim2.new(0, 600, 0, 120)
	rollAnimationFrame.Position = UDim2.new(0.5, 0, 0, -40)
	rollAnimationFrame.AnchorPoint = Vector2.new(0.5, 0)
	rollAnimationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	rollAnimationFrame.BackgroundTransparency = 0.2 -- semi-transparent like inventory and coins
	rollAnimationFrame.BorderSizePixel = 0
	rollAnimationFrame.Visible = false
	rollAnimationFrame.ZIndex = 10
	rollAnimationFrame.Parent = screen
	
	-- Add rounded corners to match inventory and coins style
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = rollAnimationFrame
	
	-- Create elements directly in the rollAnimationFrame
	local function createElementInFrame(elementType, properties)
		local element = Instance.new(elementType)
		for property, value in pairs(properties) do
			element[property] = value
		end
		element.Parent = rollAnimationFrame
		return element
	end
	
	-- Title (left side)
	local title = createElementInFrame("TextLabel", {
		Name = "Title",
		Text = "ROLLING FOR MARBLE...",
		TextScaled = true,
		Size = UDim2.new(0.4, 0, 0, 35),
		Position = UDim2.new(0, 20, 0, 15),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		ZIndex = 11
	})
	
	-- Ticket icon (center-right)
	local ticketIcon = createElementInFrame("TextLabel", {
		Name = "TicketIcon",
		Text = "🎫",
		TextScaled = true,
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(0.5, -15, 0, 15),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1), -- White color to match theme
		Font = Enum.Font.GothamBold,
		ZIndex = 11
	})
	
	-- Close button (top-right)
	local closeButton = createElementInFrame("TextButton", {
		Name = "CloseButton",
		Text = "X",
		TextScaled = true,
		Size = UDim2.new(0, 25, 0, 25),
		Position = UDim2.new(1, -35, 0, 15),
		BackgroundColor3 = Color3.fromRGB(255, 100, 100),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		ZIndex = 12
	})
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton
	
	-- Close button functionality - FIXED
	closeButton.MouseButton1Click:Connect(function()
		print("Close button clicked!")
		if rollAnimationFrame and rollAnimationFrame.Parent then
			print("Destroying roll animation frame")
			rollAnimationFrame:Destroy()
			isRolling = false
		else
			print("rollAnimationFrame not found or not parented")
		end
	end)
	
	-- Rolling text (main display - center)
	rollAnimationText = createElementInFrame("TextLabel", {
		Name = "RollingText",
		Text = "",
		TextScaled = true,
		Size = UDim2.new(0.6, 0, 0, 50),
		Position = UDim2.new(0.2, 0, 0.5, -25),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1), -- White color to match theme
		Font = Enum.Font.GothamBold,
		ZIndex = 11
	})
	
	-- Text shadow (thicker for better visibility on translucent background)
	rollAnimationShadow = createElementInFrame("TextLabel", {
		Name = "RollingTextShadow",
		Text = "",
		TextScaled = true,
		Size = UDim2.new(0.6, 0, 0, 50),
		Position = UDim2.new(0.2, 3, 0.5, -21),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(0, 0, 0),
		Font = Enum.Font.GothamBold,
		ZIndex = 10
	})
	
	-- Progress bar (bottom)
	local progressBar = createElementInFrame("Frame", {
		Name = "ProgressBar",
		Size = UDim2.new(0, 0, 0, 6),
		Position = UDim2.new(0, 20, 1, -30),
		BackgroundColor3 = Color3.fromRGB(100, 100, 100), -- Grey color to match theme
		BorderSizePixel = 0,
		ZIndex = 11
	})
	
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 3)
	progressCorner.Parent = progressBar
	
	-- Progress bar background
	local progressBg = createElementInFrame("Frame", {
		Name = "ProgressBackground",
		Size = UDim2.new(1, -40, 0, 6),
		Position = UDim2.new(0, 20, 1, -30),
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		BorderSizePixel = 0,
		ZIndex = 10
	})
	
	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(0, 3)
	progressBgCorner.Parent = progressBg
	
	-- Result display (same area as rolling text, will replace it)
	local resultDisplay = createElementInFrame("TextLabel", {
		Name = "ResultDisplay",
		Text = "",
		TextScaled = true,
		Size = UDim2.new(0.6, 0, 0, 50),
		Position = UDim2.new(0.2, 0, 0.5, -25),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(0, 255, 0),
		Font = Enum.Font.GothamBold,
		ZIndex = 11,
		Visible = false
	})
	
	return rollAnimationFrame, progressBar
end

local function startRollAnimation()
	if isRolling then return end
	isRolling = true
	
	local frame, progressBar = createRollAnimationUI()
	frame.Visible = true
	
	-- Frame reference for fade out
	
	-- Get all rollable marbles
	local rollableMarbles = Marbles.getRollable()
	if #rollableMarbles == 0 then
		frame:Destroy()
		isRolling = false
		return
	end
	
	-- Animation duration
	local totalDuration = 3.0 -- 3 seconds
	local startTime = tick()
	
	-- Rolling sound effect
	local rollSfx = Instance.new("Sound")
	rollSfx.Name = "RollSound"
	rollSfx.SoundId = "rbxassetid://127877437691780"
	rollSfx.Volume = 0.4
	rollSfx.Looped = true
	rollSfx.Parent = frame
	rollSfx:Play()
	
	-- Add particle effects for excitement
	local particles = Instance.new("Frame")
	particles.Name = "Particles"
	particles.Size = UDim2.new(1, 0, 1, 0)
	particles.Position = UDim2.new(0, 0, 0, 0)
	particles.BackgroundTransparency = 1
	particles.ZIndex = 9
	particles.Parent = frame
	
	-- Create floating particles (optimized for horizontal layout)
	for i = 1, 12 do -- Reduced particles for horizontal layout
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6)) -- Even smaller particles
		particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
		particle.BackgroundColor3 = Color3.fromRGB(
			math.random(200, 255),
			math.random(200, 255),
			math.random(200, 255)
		)
		particle.BorderSizePixel = 0
		particle.ZIndex = 9
		particle.Parent = particles
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3) -- Smaller corner radius
		corner.Parent = particle
		
		-- Animate particle (horizontal movement focus)
		local startPos = particle.Position
		local endPos = UDim2.new(math.random(), 0, math.random() * 0.5, 0) -- More horizontal movement
		local animStart = tick()
		local animDuration = math.random(1.5, 3) -- Faster animation
		
		game:GetService("RunService").Heartbeat:Connect(function()
			local elapsed = tick() - animStart
			local progress = math.min(elapsed / animDuration, 1)
			
			if progress >= 1 then
				particle:Destroy()
				return
			end
			
			-- Smooth movement
			local currentPos = UDim2.new(
				startPos.X.Scale + (endPos.X.Scale - startPos.X.Scale) * progress,
				startPos.X.Offset + (endPos.X.Offset - startPos.X.Offset) * progress,
				startPos.Y.Scale + (endPos.Y.Scale - startPos.Y.Scale) * progress,
				startPos.Y.Offset + (endPos.Y.Offset - startPos.Y.Offset) * progress
			)
			particle.Position = currentPos
			
			-- Fade out near the end
			if progress > 0.8 then
				particle.BackgroundTransparency = (progress - 0.8) * 5
			end
		end)
	end
	
	-- Animation loop
	local connection
	local lastChangeTime = 0
	local changeInterval = 0.1 -- Change odds display every 0.1 seconds
	local waitingForResult = false
	local resultReceived = false
	
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.min(elapsed / totalDuration, 1)
		local currentTime = tick()
		
		-- Update progress bar (cap at 100% to prevent going off-screen)
		-- Use the actual panel width minus margins (40px total) to ensure it fits
		local maxWidth = (frame.AbsoluteSize.X - 40) / frame.AbsoluteSize.X
		local clampedProgress = math.min(progress, maxWidth)
		progressBar.Size = UDim2.new(clampedProgress, 0, 0, 6)
		
		-- Show odds flying by with dynamic changes
		if progress < 0.8 then
			-- Change odds display at regular intervals for dynamic effect
			if currentTime - lastChangeTime >= changeInterval then
				local randomMarble = rollableMarbles[math.random(1, #rollableMarbles)]
				local oddsText = string.format("%s (1/%d)", randomMarble.name, randomMarble.dropDenominator or 1)
				
				if rollAnimationText then
					rollAnimationText.Text = oddsText
					-- Add some visual flair with color changes
					rollAnimationText.TextColor3 = Color3.fromRGB(
						math.random(200, 255),
						math.random(200, 255),
						math.random(200, 255)
					)
				end
				if rollAnimationShadow then
					rollAnimationShadow.Text = oddsText
				end
				
				lastChangeTime = currentTime
			end
		elseif progress < 1 then
			-- Final reveal phase with pulsing effect
			if rollAnimationText then
				rollAnimationText.Text = "REVEALING..."
				-- Pulsing white color
				local pulse = math.abs(math.sin(currentTime * 8)) * 0.3 + 0.7
				rollAnimationText.TextColor3 = Color3.fromRGB(255 * pulse, 255 * pulse, 255 * pulse)
			end
			if rollAnimationShadow then
				rollAnimationShadow.Text = "REVEALING..."
			end
		else
			-- Animation complete - but wait for server result
			if not waitingForResult then
				waitingForResult = true
				
				-- Change text to waiting for result
				if rollAnimationText then
					rollAnimationText.Text = "WAITING FOR RESULT..."
					rollAnimationText.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
				if rollAnimationShadow then
					rollAnimationShadow.Text = "WAITING FOR RESULT..."
				end
				
				-- Stop the rolling sound
				rollSfx:Stop()
				rollSfx:Destroy()
				
				-- Keep progress bar at max width (respecting margins)
				local maxWidth = (frame.AbsoluteSize.X - 40) / frame.AbsoluteSize.X
				progressBar.Size = UDim2.new(maxWidth, 0, 0, 6)
			end
		end
		
		-- If we have a result and animation is complete, show the result
		if waitingForResult and resultReceived then
			print("Animation complete - showing result and celebration")
			print("waitingForResult:", waitingForResult, "resultReceived:", resultReceived)
			connection:Disconnect()
			
			-- Hide rolling text
			if rollAnimationText then
				rollAnimationText.Visible = false
				print("Hidden rolling text")
			end
			if rollAnimationShadow then
				rollAnimationShadow.Visible = false
				print("Hidden rolling shadow")
			end
			
			-- Show result with celebration effect
			local resultDisplay = frame:FindFirstChild("ResultDisplay")
			if resultDisplay then
				print("Found resultDisplay, making it visible")
				print("ResultDisplay text:", resultDisplay.Text)
				resultDisplay.Visible = true
				-- Don't change the text - it should already contain the stored result from the server
				
				-- Celebration animation
				local celebrationStart = tick()
				local celebrationConnection
				celebrationConnection = game:GetService("RunService").Heartbeat:Connect(function()
					local celebrationElapsed = tick() - celebrationStart
					local celebrationProgress = math.min(celebrationElapsed / 1.5, 1)
					
					-- Bounce effect
					local bounce = math.sin(celebrationElapsed * 10) * (1 - celebrationProgress) * 10
					resultDisplay.Position = UDim2.new(0.2, 0, 0.5, -25 + bounce)
					
					if celebrationProgress >= 1 then
						celebrationConnection:Disconnect()
					end
				end)
			else
				print("ERROR: resultDisplay not found in frame")
			end
			
			-- Fade out after delay
			task.delay(2.0, function()
				if frame and frame.Parent then
					-- Fade out animation
					local fadeTime = 0.8
					local fadeStart = tick()
					local fadeConnection
					fadeConnection = game:GetService("RunService").Heartbeat:Connect(function()
						local fadeElapsed = tick() - fadeStart
						local fadeProgress = math.min(fadeElapsed / fadeTime, 1)
						
						frame.BackgroundTransparency = 0.2 + (fadeProgress * 0.8)
						
						if fadeProgress >= 1 then
							fadeConnection:Disconnect()
							frame:Destroy()
							isRolling = false
						end
					end)
				end
			end)
		end
	end)
	
	-- Actually trigger the roll
	RollForMarble:FireServer()
	
	-- Return a function that can be called when we get the result
	return function()
		print("Roll callback called - setting resultReceived to true")
		resultReceived = true
	end
end

-- Event wiring
local currentRollCallback: (() -> ())? = nil

rollButton.MouseButton1Click:Connect(function()
	currentRollCallback = startRollAnimation()
end)

inventoryButton.MouseButton1Click:Connect(function()
	local newVisible = not invFrame.Visible
	invFrame.Visible = newVisible
	if newVisible then
		pcall(function()
			invOpenSfx:Play()
		end)
	end
end)

InventoryUpdate.OnClientEvent:Connect(function(payload)
	print("InventoryUpdate received")
	print("payload.owned:", payload.owned)
	print("payload.equipped:", payload.equipped)
	
	-- If UI is not ready, store the update for later processing
	if not (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
		print("InventoryUpdate: UI not ready, storing update for later processing")
		pendingInventoryUpdate = {
			owned = payload.owned,
			equipped = payload.equipped
		}
		return
	end
	
	-- UI is ready, process the update immediately
	print("InventoryUpdate: UI is ready, processing update immediately")
	
	ownedSet = {}
	for _, id in ipairs(payload.owned :: {string}) do
		ownedSet[id] = true
		print("Added to ownedSet:", id)
	end
	equippedId = payload.equipped
	print("equippedId set to:", equippedId)
	
	-- Debug: Check what marble definition we get for Spider
	if equippedId == "Spider" then
		if Marbles and Marbles.getById then
			local spiderDef = Marbles.getById("Spider")
			print("Spider marble definition:", spiderDef)
			if spiderDef then
				print("Spider abilityModule:", spiderDef.abilityModule)
				print("Spider abilityModule ~= 'Default':", spiderDef.abilityModule ~= "Default")
			end
		else
			print("Marbles module not available for Spider debug check")
		end
	end
	
	rebuildInventoryUI()
	
	-- UI is ready, update the power button immediately
	print("InventoryUpdate: UI is ready, updating power button immediately")
	updatePowerButtonForMarble()
end)

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
	
		-- Store the result but don't show it yet - wait for animation to complete
	if rollAnimationFrame and rollAnimationFrame.Parent then
		local resultDisplay = rollAnimationFrame:FindFirstChild("ResultDisplay")
		if resultDisplay then
			-- Store the result text but keep it hidden
			if result.success then
				local suffix = result.new and " (NEW!)" or ""
				resultDisplay.Text = string.format("YOU GOT: %s%s", result.marbleName or result.marbleId or "?", suffix)
				resultDisplay.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green for success
				print("Stored result display text:", resultDisplay.Text)
			else
				resultDisplay.Text = result.message or "Roll failed"
				resultDisplay.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red for failure
				print("Stored result display text:", resultDisplay.Text)
			end
			-- Keep it hidden - it will be shown when the animation completes
			resultDisplay.Visible = false
		else
			print("ResultDisplay not found in rollAnimationFrame")
		end
	else
		print("rollAnimationFrame not found or not parented")
	end
	
	-- Remove the bottom result label since result is now shown in the panel
	-- resultLabel.Text = "" -- Clear any existing text
end)

-- Handle ability cooldown from server
AbilityCooldown.OnClientEvent:Connect(function(cooldownData)
	print("AbilityCooldown received:", cooldownData.duration, "seconds")
	print("COOLDOWN LOG: Server cooldown event received - Duration:", cooldownData.duration, "seconds, Current Time:", tick())
	print("COOLDOWN LOG: Current cooldown state - Is On Cooldown:", isPowerOnCooldown, "Current Duration:", powerCooldownDuration, "Current Start Time:", powerCooldownTime)
	
	startPowerCooldown(cooldownData.duration)
end)

-- Power button click handler
powerButton.MouseButton1Click:Connect(function()
	if not isPowerOnCooldown then
		print("COOLDOWN LOG: Power button clicked - No cooldown active, checking for ability")
		-- Check if equipped marble has an ability
		local equippedMarble = equippedId and Marbles.getById(equippedId)
		if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
			print("COOLDOWN LOG: Activating ability for marble:", equippedMarble.id, "Ability module:", equippedMarble.abilityModule)
			ActivateAbility:FireServer()
		else
			print("COOLDOWN LOG: Power button clicked but no ability available - Marble:", equippedId, "Ability module:", equippedMarble and equippedMarble.abilityModule or "nil")
		end
	else
		print("COOLDOWN LOG: Power button clicked but on cooldown - Remaining time:", powerCooldownTime + powerCooldownDuration - tick(), "seconds")
	end
end)

-- Ability activation keybind (E key)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.E then
		if not isPowerOnCooldown then
			local equippedMarble = equippedId and Marbles.getById(equippedId)
			if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
				print("COOLDOWN LOG: Activating ability via E key for marble:", equippedMarble.id, "Ability module:", equippedMarble.abilityModule)
				ActivateAbility:FireServer()
			else
				print("COOLDOWN LOG: E key pressed but no ability available - Marble:", equippedId, "Ability module:", equippedMarble and equippedMarble.abilityModule or "nil")
			end
		else
			-- Check if cooldown should actually be finished
			local remaining = powerCooldownTime + powerCooldownDuration - tick()
			-- Add a small buffer (0.1 seconds) to prevent premature cooldown resets
			if remaining <= 0.1 then
				print("COOLDOWN LOG: Cooldown time expired but state not reset, forcing reset")
				-- Force reset the cooldown state
				isPowerOnCooldown = false
				powerCooldownTime = 0
				powerCooldownDuration = 0
				if cooldownConnection then
					cooldownConnection:Disconnect()
					cooldownConnection = nil
				end
				-- Update the UI
				updatePowerButtonCooldown()
				
				-- Validate cooldown state consistency
				validateCooldownState()
				
				-- Now try to activate the ability
				local equippedMarble = equippedId and Marbles.getById(equippedId)
				if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
					print("COOLDOWN LOG: Activating ability after cooldown reset for marble:", equippedMarble.id, "Ability module:", equippedMarble.abilityModule)
					ActivateAbility:FireServer()
				end
			else
				print("COOLDOWN LOG: E key pressed but on cooldown - Remaining time:", remaining, "seconds")
			end
		end
	end
	
	-- Debug: Force reset cooldown with R key
	if input.KeyCode == Enum.KeyCode.R then
		print("R key pressed - forcing cooldown reset")
		print("COOLDOWN LOG: R key pressed - Manual cooldown reset triggered")
		forceResetCooldown()
	end
end)

-- Request initial inventory

-- Comprehensive UI element check and initialization
print("=== Comprehensive UI Element Check ===")
print("screen exists:", screen ~= nil, "Parent:", screen and screen.Parent ~= nil)
print("powerButton exists:", powerButton ~= nil, "Parent:", powerButton and powerButton.Parent ~= nil)
print("powerCooldown exists:", powerCooldown ~= nil, "Parent:", powerCooldown and powerCooldown.Parent ~= nil)
print("cooldownText exists:", cooldownText ~= nil, "Parent:", cooldownText and cooldownText.Parent ~= nil)
print("textShadow exists:", textShadow ~= nil, "Parent:", textShadow and textShadow.Parent ~= nil)
print("rollButton exists:", rollButton ~= nil, "Parent:", rollButton and rollButton.Parent ~= nil)
print("inventoryButton exists:", inventoryButton ~= nil, "Parent:", inventoryButton and inventoryButton.Parent ~= nil)
print("resultLabel exists:", resultLabel ~= nil, "Parent:", resultLabel and resultLabel.Parent ~= nil)
print("invFrame exists:", invFrame ~= nil, "Parent:", invFrame and invFrame.Parent ~= nil)

-- Check if elements are visible in the game
if screen and screen.Parent then
	print("✓ ScreenGui is properly parented to PlayerGui")
else
	print("✗ ScreenGui is NOT properly parented!")
end

if powerButton and powerButton.Parent then
	print("✓ Power button is properly parented")
else
	print("✗ Power button is NOT properly parented!")
end

if rollButton and rollButton.Parent then
	print("✓ Roll button is properly parented")
else
	print("✗ Roll button is NOT properly parented!")
end

print("=== End Comprehensive Check ===")

-- Wait for UI to be fully ready
print("Waiting for UI to be fully ready...")
if waitForUIReady() then
	print("UI is fully ready and initialized!")
	-- Now that UI is ready, process any pending updates
	processPendingCooldown()
	processPendingInventoryUpdate()
	-- Update the power button to process any pending updates
	updatePowerButtonForMarble()
else
	print("WARNING: UI failed to become ready!")
end

RequestInventory:FireServer()

-- Debug: Final check of UI elements
print("=== Final UI Element Check ===")
print("powerButton exists:", powerButton ~= nil)
print("powerCooldown exists:", powerCooldown ~= nil)
print("cooldownText exists:", cooldownText ~= nil)
print("textShadow exists:", textShadow ~= nil)
print("UI Ready:", isUIReady())
print("=== End Final Check ===")

-- Final verification that cooldown system is ready
if (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
	print("✓ Cooldown system is ready and initialized")
	print("✓ UI elements are properly created and parented")
	print("✓ Ready to handle ability cooldowns")
else
	print("✗ WARNING: Cooldown system is NOT ready!")
	print("✗ UI elements may not be properly initialized")
end

-- Set up periodic UI health check
task.spawn(function()
	while true do
		task.wait(5) -- Check every 5 seconds
		
		-- Only check if we're supposed to have UI elements
		if (powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent) then
			if not isUIReady() then
				print("UI health check: UI elements are invalid, skipping recreation...")
			end
			
			-- Validate cooldown state consistency
			validateCooldownState()
			
			-- If cooldown should be active but UI is not showing it, restore it
			if shouldPreserveCooldown() then
				local remaining = powerCooldownTime + powerCooldownDuration - tick()
				if remaining > 0.1 then
					print("UI health check: Cooldown should be preserved, restoring UI display")
					updatePowerButtonCooldown()
				end
			end
		end
	end
end)

-- Note: updatePowerButtonForMarble() will be called when InventoryUpdate is received
-- after the UI elements are created, so we don't need to call it here 