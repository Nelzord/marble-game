-- PowerButton.luau
-- Power button with cooldown functionality for the Marble Game

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))
local ActivateAbility: RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ActivateAbility")

-- State variables
local powerCooldownTime = 0
local powerCooldownDuration = 0
local isPowerOnCooldown = false
local pendingCooldown: { duration: number, startTime: number }? = nil

-- UI element variables
local powerButton: TextButton? = nil
local powerCooldown: Frame? = nil
local cooldownText: TextLabel? = nil
local textShadow: TextLabel? = nil

-- Cooldown connection
local cooldownConnection: RBXScriptConnection? = nil

local PowerButton = {}

-- Function to check if UI is ready
function PowerButton:isReady()
	return powerButton and powerButton.Parent and powerCooldown and powerCooldown.Parent and cooldownText and cooldownText.Parent and textShadow and textShadow.Parent
end

-- Function to process any pending cooldowns when UI becomes ready
function PowerButton:processPendingCooldown()
	if pendingCooldown and self:isReady() then
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
		self:updateCooldown()
	end
end

-- Function to update power button based on equipped marble
function PowerButton:updateForMarble(equippedId)
	print("updatePowerButtonForMarble - start")
	
	-- Safety check: only run if UI elements exist
	if not self:isReady() then
		print("updatePowerButtonForMarble: UI not ready, skipping...")
		return
	end
	
	print("updatePowerButtonForMarble: UI elements ready")
	
	-- Process any pending cooldowns now that UI is ready
	self:processPendingCooldown()
	
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
	
	-- Check if equipped marble has abilities (Spider, Red, etc.)
	if equippedMarble and equippedMarble.abilityModule and equippedMarble.abilityModule ~= "Default" then
		print("Setting power button to ENABLED")
		powerButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
		powerButton.Text = "Power (E)"
		powerButton.TextColor3 = Color3.new(1, 1, 1)
	else
		print("Setting power button to DISABLED")
		-- No ability or default marble
		powerButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		powerButton.Text = "Power (None)"
		powerButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	end
end

-- Function to check if cooldown should still be active based on time
function PowerButton:shouldCooldownBeActive()
	if not isPowerOnCooldown then
		return false
	end
	
	local remaining = powerCooldownTime + powerCooldownDuration - tick()
	return remaining > 0.1 -- Use the same buffer as other checks
end

-- Function to check if cooldown should be preserved when UI is unavailable
function PowerButton:shouldPreserveCooldown()
	return self:shouldCooldownBeActive() and (powerCooldownTime > 0 or powerCooldownDuration > 0)
end

-- Function to safely reset cooldown state (only when appropriate)
function PowerButton:safeResetCooldown()
	if self:shouldPreserveCooldown() then
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
function PowerButton:validateCooldownState()
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
			if self:isReady() then
				self:updateCooldown()
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

-- Function to update power button cooldown display
function PowerButton:updateCooldown()
	-- Safety check: only run if UI elements exist
	if not self:isReady() then
		-- If UI elements are not available but cooldown should be active, preserve the state
		if self:shouldPreserveCooldown() then
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
		self:validateCooldownState()
		
		-- Hide cooldown UI elements
		powerCooldown.Visible = false
		cooldownText.Visible = false
		textShadow.Visible = false
		
		-- Update button to normal state
		-- Note: This will be handled by the calling function
		return
	end
	
	-- Safety check: prevent infinite recursion
	if not isPowerOnCooldown then
		print("COOLDOWN LOG: No cooldown active, hiding cooldown UI elements")
		
		-- Final safety check before accessing UI elements
		powerCooldown.Visible = false
		cooldownText.Visible = false
		textShadow.Visible = false
		
		-- Clean up connection
		if cooldownConnection then
			print("COOLDOWN LOG: Cleaning up cooldown connection (no cooldown active)")
			cooldownConnection:Disconnect()
			cooldownConnection = nil
		end
		
		-- Validate cooldown state consistency
		self:validateCooldownState()
		
		-- Check if equipped marble has an ability
		-- Note: This will be handled by the calling function
		return
	end
	
	local progress = remaining / powerCooldownDuration
	powerCooldown.Size = UDim2.new(1, 0, progress, 0)
	powerCooldown.Position = UDim2.new(0, 0, 1 - progress, 0)
	powerCooldown.AnchorPoint = Vector2.new(0, 1)
	
	local timeText = string.format("%.1fs", remaining)
	cooldownText.Text = timeText
	cooldownText.Visible = true
	textShadow.Text = timeText
	textShadow.Visible = true
	
	-- Set cooldown state for button
	powerCooldown.Visible = true
	powerButton.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
	powerButton.Text = timeText -- Show countdown on button instead of just "Cooldown"
end

-- Function to start power cooldown
function PowerButton:startCooldown(duration)
	print("startPowerCooldown called with duration:", duration)
	print("COOLDOWN LOG: Starting cooldown - Duration:", duration, "Current Time:", tick())
	
	-- If UI is not ready, queue the cooldown instead of waiting
	if not self:isReady() then
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
	self:validateCooldownState()
	
	print("COOLDOWN LOG: Cooldown state set - Duration:", powerCooldownDuration, "Start Time:", powerCooldownTime, "Is On Cooldown:", isPowerOnCooldown)
	
	-- Additional safety check before calling updateCooldown
	if not self:isReady() then
		print("startPowerCooldown: UI became unavailable after setting cooldown state, resetting")
		isPowerOnCooldown = false
		return
	end
	
	self:updateCooldown()
	
	-- Only create heartbeat connection if UI elements are still ready
	if self:isReady() then
		print("COOLDOWN LOG: Creating heartbeat connection for cooldown updates")
		-- Update cooldown every frame
		cooldownConnection = RunService.Heartbeat:Connect(function()
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
				if self:safeResetCooldown() then
					-- Update the UI
					self:updateCooldown()
					
					-- Validate cooldown state consistency
					self:validateCooldownState()
					
					return
				end
			end
			
			-- Update the cooldown display every frame
			self:updateCooldown()
			
			-- Validate cooldown state consistency
			self:validateCooldownState()
			
			-- If UI elements are not available but cooldown should be active, keep the connection alive
			if not self:isReady() then
				if self:shouldPreserveCooldown() then
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
		local shouldBeActive = self:shouldCooldownBeActive()
		
		if isPowerOnCooldown and shouldBeFinished and not shouldBeActive then
			print("Safety timeout: forcing cooldown reset - Expected end time:", expectedEndTime, "Current time:", currentTime)
			print("COOLDOWN LOG: Safety timeout triggered, forcing cooldown reset")
			
			-- Use safe reset function
			if self:safeResetCooldown() then
				-- Only update if UI elements still exist
				if self:isReady() then
					self:updateCooldown()
				else
					print("Safety timeout: UI not ready, skipping update")
				end
				
				-- Validate cooldown state consistency
				self:validateCooldownState()
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

-- Function to activate ability
function PowerButton:activateAbility(equippedId)
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
end

-- Function to force reset cooldown
function PowerButton:forceResetCooldown()
	print("forceResetCooldown: forcing cooldown reset")
	print("COOLDOWN LOG: Force reset triggered - Current state - Is On Cooldown:", isPowerOnCooldown, "Duration:", powerCooldownDuration, "Start Time:", powerCooldownTime)
	
	isPowerOnCooldown = false
	powerCooldownTime = 0
	powerCooldownDuration = 0
	pendingCooldown = nil
	
	-- Validate cooldown state consistency
	self:validateCooldownState()
	
	if cooldownConnection then
		print("COOLDOWN LOG: Disconnecting cooldown connection during force reset")
		cooldownConnection:Disconnect()
		cooldownConnection = nil
	end
	
	-- Only update UI if elements exist
	if self:isReady() then
		self:updateCooldown()
	end
	
	print("forceResetCooldown: reset complete")
	print("COOLDOWN LOG: Force reset complete - All cooldown state reset to default values")
end

-- Function to initialize the power button
function PowerButton:init(screen)
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
	powerButton.Parent = screen
	
	local powerCorner = Instance.new("UICorner")
	powerCorner.CornerRadius = UDim.new(0, 8)
	powerCorner.Parent = powerButton
	
	-- Cooldown overlay for power button
	print("Creating cooldown overlay...")
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
	cooldownText.Parent = powerButton
	
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
	textShadow.Parent = powerButton
	textShadow.ZIndex = cooldownText.ZIndex - 1
	
	-- Connect the click handler
	powerButton.MouseButton1Click:Connect(function()
		self:activateAbility(nil) -- equippedId will be passed by the calling function
	end)
	
	print("=== Power Button UI Created ===")
end

return PowerButton
