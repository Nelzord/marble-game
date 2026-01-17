-- Flash marble ability: 7x speed boost for 5 seconds
local Ability = {}

function Ability.Description()
	return "Flash: Temporarily increases movement speed by 7x for 5 seconds."
end

function Ability.Cooldown()
	return 12 -- 12 second cooldown
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("FLASH ABILITY: Activating for player:", player.Name)
	
	-- Check if speed boost is already active
	local prev = character:GetAttribute("SpeedMultiplier")
	if typeof(prev) == "number" and prev > 1 then 
		print("FLASH ABILITY: Already active")
		return 
	end
	
	-- Set speed multiplier to 7.0 (7x speed)
	character:SetAttribute("SpeedMultiplier", 7.0)
	
	-- Set flash glow attribute to true for visual effect
	character:SetAttribute("FlashGlowActive", true)
	
	-- Duration: 5 seconds
	local speedTimer = task.delay(5, function()
		if character then
			character:SetAttribute("SpeedMultiplier", nil)
			character:SetAttribute("FlashGlowActive", false)
			print("FLASH ABILITY: Speed boost ended")
		end
	end)
	
	-- Store the timer reference so we can cancel it if needed
	character:SetAttribute("FlashSpeedTimer", speedTimer)
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("FLASH ABILITY: Deactivating for player:", player.Name)
	
	if character then
		-- Cancel the speed timer if it's still running
		local timerRef = character:GetAttribute("FlashSpeedTimer")
		if timerRef then
			-- Cancel the actual timer thread
			pcall(function()
				task.cancel(timerRef)
			end)
			character:SetAttribute("FlashSpeedTimer", nil)
		end
		
		character:SetAttribute("SpeedMultiplier", nil)
		character:SetAttribute("FlashGlowActive", false)
	end
end

return Ability
