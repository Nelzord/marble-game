-- CooldownSystem.luau
-- Handles all cooldown-related functionality for the power button

local CooldownSystem = {}

-- Cooldown state variables
local isPowerOnCooldown = false
local powerCooldownTime = 0
local powerCooldownDuration = 0
local pendingCooldown: { duration: number, startTime: number }? = nil
local cooldownConnection: RBXScriptConnection? = nil
local updatePowerButtonCooldown_lastLogTime: number? = nil

-- Function to check if cooldown should still be active based on time
local function shouldCooldownBeActive()
	if not isPowerOnCooldown then
		return false
	end
	
	local remaining = powerCooldownTime + powerCooldownDuration - tick()
	return remaining > 0.1
end

-- Function to check if cooldown should be preserved when UI is unavailable
local function shouldPreserveCooldown()
	return shouldCooldownBeActive() and (powerCooldownTime > 0 or powerCooldownDuration > 0)
end

-- Function to safely reset cooldown state
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
function CooldownSystem.updatePowerButtonCooldown(powerButton, powerCooldown, cooldownText, textShadow)
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
		if powerButton and powerButton.Parent then
			powerButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Same as roll button
			powerButton.BackgroundTransparency = 0.4 -- Maintain transparency
			powerButton.Text = "Power (E)"
			powerButton.TextColor3 = Color3.new(1, 1, 1)
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
		if powerButton and powerButton.Parent then
			powerButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Same as roll button
			powerButton.BackgroundTransparency = 0.4 -- Maintain transparency
			powerButton.Text = "Power (E)"
			powerButton.TextColor3 = Color3.new(1, 1, 1)
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
		powerButton.BackgroundTransparency = 0.4 -- Maintain transparency
		powerButton.Text = timeText -- Show countdown on button instead of just "Cooldown"
	end
	
	-- Log cooldown progress (only every 0.5 seconds to avoid spam)
	local currentTime = tick()
	if not updatePowerButtonCooldown_lastLogTime or (currentTime - updatePowerButtonCooldown_lastLogTime) >= 0.5 then
		print("COOLDOWN LOG: Progress update - Remaining:", string.format("%.1f", remaining), "seconds, Progress:", string.format("%.1f%%", progress * 100))
		updatePowerButtonCooldown_lastLogTime = currentTime
	end
end

-- Function to start power cooldown
function CooldownSystem.startPowerCooldown(duration: number, powerButton, powerCooldown, cooldownText, textShadow)
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
	
	CooldownSystem.updatePowerButtonCooldown(powerButton, powerCooldown, cooldownText, textShadow)
	
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
					CooldownSystem.updatePowerButtonCooldown(powerButton, powerCooldown, cooldownText, textShadow)
					
					-- Validate cooldown state consistency
					validateCooldownState()
					
					return
				end
			end
			
			-- Update the cooldown display every frame
			CooldownSystem.updatePowerButtonCooldown(powerButton, powerCooldown, cooldownText, textShadow)
			
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
					CooldownSystem.updatePowerButtonCooldown(powerButton, powerCooldown, cooldownText, textShadow)
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

-- Function to process any pending cooldowns when UI becomes ready
function CooldownSystem.processPendingCooldown(powerButton, powerCooldown, cooldownText, textShadow)
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
		CooldownSystem.updatePowerButtonCooldown(powerButton, powerCooldown, cooldownText, textShadow)
	end
end

-- Function to check if cooldown should be preserved when UI is unavailable
function CooldownSystem.shouldPreserveCooldown()
	return shouldPreserveCooldown()
end

-- Function to check if cooldown is active
function CooldownSystem.isOnCooldown()
	return isPowerOnCooldown
end

-- Function to get remaining cooldown time
function CooldownSystem.getRemainingTime()
	if not isPowerOnCooldown then
		return 0
	end
	local remaining = powerCooldownTime + powerCooldownDuration - tick()
	return math.max(0, remaining)
end

-- Function to force reset cooldown (for debugging)
function CooldownSystem.forceResetCooldown(powerButton, powerCooldown, cooldownText, textShadow)
	print("forceResetCooldown: forcing cooldown reset")
	print("COOLDOWN LOG: Force reset triggered - Current state - Is On Cooldown:", isPowerOnCooldown, "Current Duration:", powerCooldownDuration, "Current Start Time:", powerCooldownTime)
	
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
		CooldownSystem.updatePowerButtonCooldown(powerButton, powerCooldown, cooldownText, textShadow)
	end
	
	print("forceResetCooldown: reset complete")
	print("COOLDOWN LOG: Force reset complete - All cooldown state reset to default values")
end

-- Function to cleanup cooldown system
function CooldownSystem.cleanup(powerButton, powerCooldown, cooldownText, textShadow)
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

return CooldownSystem
