-- Sample ability placeholder. Replace with real effects later.
-- Suggested idea: temporarily increase rolling force/speed for a few seconds.
local Ability = {}

-- Example state cache (session-only)
local active: { [Player]: boolean } = {}

function Ability.ActivateAbility(player: Player, character: Model)
	if active[player] then return end
	active[player] = true
	-- Placeholder: insert your real ability logic here
	-- e.g., set an Attribute on the character the client controller can read (like "SpeedMultiplier")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		character:SetAttribute("SpeedMultiplier", 1.5)
	end
	task.delay(5, function()
		Ability.DeactivateAbility(player, character)
	end)
end

function Ability.DeactivateAbility(player: Player, character: Model)
	active[player] = nil
	if character then
		character:SetAttribute("SpeedMultiplier", nil)
	end
end

return Ability 