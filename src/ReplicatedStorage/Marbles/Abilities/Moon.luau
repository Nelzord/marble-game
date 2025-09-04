-- Moon marble ability: lower gravity for lunar-like movement
local Ability = {}

function Ability.Description()
	return "Moon: Lower gravity for slower falling and floating lunar-like movement."
end

function Ability.Cooldown()
	return 0 -- No cooldown - passive ability
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("MOON ABILITY: Activating for player:", player.Name)
	
	-- Check if moon effects are already active
	local prev = character:GetAttribute("MoonGravityActive")
	if typeof(prev) == "boolean" and prev then 
		print("MOON ABILITY: Already active")
		return 
	end
	
	-- Set moon gravity attribute to true for physics effect
	character:SetAttribute("MoonGravityActive", true)
	
	-- Set moon glow attribute to true for visual effect
	character:SetAttribute("MoonGlowActive", true)
	
	print("MOON ABILITY: Moon effects activated - lower gravity")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("MOON ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("MoonGravityActive", false)
		character:SetAttribute("MoonGlowActive", false)
	end
end

return Ability
