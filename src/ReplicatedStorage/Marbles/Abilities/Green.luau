-- Green marble ability: rejuvenating pulse (placeholder)
local Ability = {}

function Ability.Description()
	return "Green: A rejuvenating pulse that boosts control for a moment."
end

function Ability.ActivateAbility(player: Player, character: Model)
	-- Example: tiny control benefit via speed multiplier
	local prev = character:GetAttribute("SpeedMultiplier")
	if typeof(prev) == "number" and prev > 1 then return end
	character:SetAttribute("SpeedMultiplier", 1.15)
	task.delay(5, function()
		if character then
			character:SetAttribute("SpeedMultiplier", nil)
		end
	end)
end

function Ability.DeactivateAbility(player: Player, character: Model)
	character:SetAttribute("SpeedMultiplier", nil)
end

return Ability 