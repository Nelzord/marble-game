-- Blue marble ability: calming shield (placeholder)
local Ability = {}

function Ability.Description()
	return "Blue: A calming shield that reduces deceleration briefly."
end

function Ability.ActivateAbility(player: Player, character: Model)
	-- Example: reduce friction effect by raising a multiplier the controller could interpret
	local prev = character:GetAttribute("FrictionReduction")
	if typeof(prev) == "number" and prev > 0 then return end
	character:SetAttribute("FrictionReduction", 0.5)
	task.delay(4, function()
		if character then
			character:SetAttribute("FrictionReduction", nil)
		end
	end)
end

function Ability.DeactivateAbility(player: Player, character: Model)
	character:SetAttribute("FrictionReduction", nil)
end

return Ability 