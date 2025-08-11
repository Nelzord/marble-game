-- Green marble ability: rejuvenating pulse (placeholder)
local Ability = {}

function Ability.Description()
	return "Green: A rejuvenating pulse that boosts control for a moment."
end

function Ability.Cooldown()
	return 5 -- 5 second cooldown
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("GREEN ABILITY LOG: Activating Green marble ability for player:", player.Name)
	print("GREEN ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	print("GREEN ABILITY LOG: Cooldown duration:", Ability.Cooldown(), "seconds")
	
	-- Example: tiny control benefit via speed multiplier
	local prev = character:GetAttribute("SpeedMultiplier")
	print("GREEN ABILITY LOG: Previous SpeedMultiplier:", prev, "Type:", typeof(prev))
	
	if typeof(prev) == "number" and prev > 1 then 
		print("GREEN ABILITY LOG: SpeedMultiplier already active (", prev, "), skipping activation")
		return 
	end
	
	character:SetAttribute("SpeedMultiplier", 1.15)
	print("GREEN ABILITY LOG: SpeedMultiplier set to 1.15 for character:", character.Name)
	
	task.delay(5, function()
		if character then
			print("GREEN ABILITY LOG: Removing SpeedMultiplier after 5 seconds for character:", character.Name)
			character:SetAttribute("SpeedMultiplier", nil)
		else
			print("GREEN ABILITY LOG: Character no longer exists, cannot remove SpeedMultiplier")
		end
	end)
	
	print("GREEN ABILITY LOG: Green ability activation complete - Duration: 5 seconds, Cooldown: 5 seconds")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("GREEN ABILITY LOG: Deactivating Green marble ability for player:", player.Name)
	print("GREEN ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	
	if character then
		character:SetAttribute("SpeedMultiplier", nil)
		print("GREEN ABILITY LOG: SpeedMultiplier removed for character:", character.Name)
	else
		print("GREEN ABILITY LOG: Character no longer exists, cannot remove SpeedMultiplier")
	end
end

return Ability 