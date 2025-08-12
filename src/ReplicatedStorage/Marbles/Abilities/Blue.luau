-- Blue marble ability: calming shield (placeholder)
local Ability = {}

function Ability.Description()
	return "Blue: A calming shield that reduces deceleration briefly."
end

function Ability.Cooldown()
	return 4 -- 4 second cooldown
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("BLUE ABILITY LOG: Activating Blue marble ability for player:", player.Name)
	print("BLUE ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	print("BLUE ABILITY LOG: Cooldown duration:", Ability.Cooldown(), "seconds")
	
	-- Example: reduce friction effect by raising a multiplier the controller could interpret
	local prev = character:GetAttribute("FrictionReduction")
	print("BLUE ABILITY LOG: Previous FrictionReduction:", prev, "Type:", typeof(prev))
	
	if typeof(prev) == "number" and prev > 0 then 
		print("BLUE ABILITY LOG: FrictionReduction already active (", prev, "), skipping activation")
		return 
	end
	
	character:SetAttribute("FrictionReduction", 0.5)
	print("BLUE ABILITY LOG: FrictionReduction set to 0.5 for character:", character.Name)
	
	-- Store timer reference for cancellation
	local frictionTimer = task.delay(4, function()
		if character then
			print("BLUE ABILITY LOG: Removing FrictionReduction after 4 seconds for character:", character.Name)
			character:SetAttribute("FrictionReduction", nil)
		else
			print("BLUE ABILITY LOG: Character no longer exists, cannot remove FrictionReduction")
		end
	end)
	
	-- Store the timer reference so we can cancel it if needed
	character:SetAttribute("BlueFrictionTimer", frictionTimer)
	
	print("BLUE ABILITY LOG: Blue ability activation complete - Duration: 4 seconds, Cooldown: 4 seconds")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("BLUE ABILITY LOG: Deactivating Blue marble ability for player:", player.Name)
	print("BLUE ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	
	if character then
		-- Cancel the friction timer if it's still running
		local timerRef = character:GetAttribute("BlueFrictionTimer")
		if timerRef then
			-- Cancel the actual timer thread
			pcall(function()
				task.cancel(timerRef)
			end)
			character:SetAttribute("BlueFrictionTimer", nil)
		end
		
		character:SetAttribute("FrictionReduction", nil)
		print("BLUE ABILITY LOG: FrictionReduction removed for character:", character.Name)
	else
		print("BLUE ABILITY LOG: Character no longer exists, cannot remove FrictionReduction")
	end
end

return Ability 