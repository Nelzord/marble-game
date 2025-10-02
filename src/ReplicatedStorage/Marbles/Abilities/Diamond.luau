-- Diamond marble ability: 3x coin multiplier
local Ability = {}

-- Services
local Players = game:GetService("Players")

function Ability.Description()
	return "Diamond: Triples all coins collected while active."
end

function Ability.Cooldown()
	return 0 -- No cooldown - passive ability
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("DIAMOND ABILITY: Activating for player:", player.Name)
	print("DIAMOND ABILITY: Character:", character and character.Name or "nil")
	
	-- Check if diamond multiplier is already active
	local prev = character:GetAttribute("DiamondMultiplier")
	print("DIAMOND ABILITY: Previous multiplier:", prev)
	if typeof(prev) == "number" and prev > 1 then 
		print("DIAMOND ABILITY: Already active")
		return 
	end
	
	-- Set diamond multiplier to 3.0 (3x coins)
	character:SetAttribute("DiamondMultiplier", 3.0)
	print("DIAMOND ABILITY: Set DiamondMultiplier attribute to 3.0")
	
	-- Set diamond glow attribute to true for visual effect
	character:SetAttribute("DiamondGlowActive", true)
	print("DIAMOND ABILITY: Set DiamondGlowActive attribute to true")
	
	print("DIAMOND ABILITY: Diamond multiplier activated - 3x coins")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("DIAMOND ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("DiamondMultiplier", nil)
		character:SetAttribute("DiamondGlowActive", false)
		print("DIAMOND ABILITY: Diamond multiplier deactivated")
	end
end

return Ability
