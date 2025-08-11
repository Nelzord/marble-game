-- Red marble ability: fiery burst (placeholder)
local Ability = {}

function Ability.Description()
	return "Red: A fiery burst that briefly increases acceleration."
end

function Ability.Cooldown()
	return 3 -- 3 second cooldown
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("RED ABILITY LOG: Activating Red marble ability for player:", player.Name)
	print("RED ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	
	-- Example: a short boost flag
	local prev = character:GetAttribute("SpeedMultiplier")
	print("RED ABILITY LOG: Previous SpeedMultiplier:", prev, "Type:", typeof(prev))
	
	if typeof(prev) == "number" and prev > 1 then 
		print("RED ABILITY LOG: SpeedMultiplier already active (", prev, "), skipping activation")
		return 
	end
	
	character:SetAttribute("SpeedMultiplier", 1.25)
	print("RED ABILITY LOG: SpeedMultiplier set to 1.25 for character:", character.Name)
	
	task.delay(3, function()
		if character then
			print("RED ABILITY LOG: Removing SpeedMultiplier after 3 seconds for character:", character.Name)
			character:SetAttribute("SpeedMultiplier", nil)
		else
			print("RED ABILITY LOG: Character no longer exists, cannot remove SpeedMultiplier")
		end
	end)
	
	print("RED ABILITY LOG: Red ability activation complete - Duration: 3 seconds, Cooldown: 3 seconds")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("RED ABILITY LOG: Deactivating Red marble ability for player:", player.Name)
	print("RED ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	
	if character then
		character:SetAttribute("SpeedMultiplier", nil)
		print("RED ABILITY LOG: SpeedMultiplier removed for character:", character.Name)
	else
		print("RED ABILITY LOG: Character no longer exists, cannot remove SpeedMultiplier")
	end
end

return Ability 