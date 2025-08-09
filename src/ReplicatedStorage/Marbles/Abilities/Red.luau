-- Red marble ability: fiery burst (placeholder)
local Ability = {}

function Ability.Description()
	return "Red: A fiery burst that briefly increases acceleration."
end

function Ability.ActivateAbility(player: Player, character: Model)
	-- Example: a short boost flag
	local prev = character:GetAttribute("SpeedMultiplier")
	if typeof(prev) == "number" and prev > 1 then return end
	character:SetAttribute("SpeedMultiplier", 1.25)
	task.delay(3, function()
		if character then
			character:SetAttribute("SpeedMultiplier", nil)
		end
	end)
end

function Ability.DeactivateAbility(player: Player, character: Model)
	character:SetAttribute("SpeedMultiplier", nil)
end

return Ability 