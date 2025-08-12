-- Red marble ability: speed boost
local Ability = {}

function Ability.Description()
	return "Red: A speed boost that quadruples movement speed."
end

function Ability.Cooldown()
	return 5 -- 5 second cooldown
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("RED ABILITY: Activating for player:", player.Name)
	
	-- Check if speed boost is already active
	local prev = character:GetAttribute("SpeedMultiplier")
	if typeof(prev) == "number" and prev > 1 then 
		print("RED ABILITY: Already active")
		return 
	end
	
	-- Set speed multiplier to 4.0 (300% increase - quadruple speed)
	character:SetAttribute("SpeedMultiplier", 4.0)
	
	-- Set red glow attribute to true for visual effect
	character:SetAttribute("RedGlowActive", true)
	
	-- Duration: 2.5 seconds (halfway through 5 second cooldown)
	local speedTimer = task.delay(2.5, function()
		if character then
			character:SetAttribute("SpeedMultiplier", nil)
			character:SetAttribute("RedGlowActive", false)
			print("RED ABILITY: Speed boost ended")
		end
	end)
	
	-- Store the timer reference so we can cancel it if needed
	character:SetAttribute("RedSpeedTimer", speedTimer)
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("RED ABILITY: Deactivating for player:", player.Name)
	
	if character then
		-- Cancel the speed timer if it's still running
		local timerRef = character:GetAttribute("RedSpeedTimer")
		if timerRef then
			-- Cancel the actual timer thread
			pcall(function()
				task.cancel(timerRef)
			end)
			character:SetAttribute("RedSpeedTimer", nil)
		end
		
		character:SetAttribute("SpeedMultiplier", nil)
		character:SetAttribute("RedGlowActive", false)
	end
end

return Ability 