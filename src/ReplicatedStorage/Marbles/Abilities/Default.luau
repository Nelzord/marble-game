-- Default ability module: does nothing. Keep this as a safe fallback.
local Ability = {}

function Ability.ActivateAbility(player: Player, character: Model)
	-- No-op: Default marble has no special ability
end

function Ability.DeactivateAbility(player: Player, character: Model)
	-- No-op
end

return Ability 