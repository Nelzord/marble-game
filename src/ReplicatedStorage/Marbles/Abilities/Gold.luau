-- Gold marble ability: 5x coin multiplier
local Ability = {}

-- Services
local Players = game:GetService("Players")

function Ability.Description()
	return "Gold: Multiplies all coins collected by 5x while active."
end

function Ability.Cooldown()
	return 0 -- No cooldown - passive ability
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("GOLD ABILITY: Activating for player:", player.Name)
	print("GOLD ABILITY: Character:", character and character.Name or "nil")
	
	-- Check if gold multiplier is already active
	local prev = character:GetAttribute("GoldMultiplier")
	print("GOLD ABILITY: Previous multiplier:", prev)
	if typeof(prev) == "number" and prev > 1 then 
		print("GOLD ABILITY: Already active")
		return 
	end
	
	-- Set gold multiplier to 5.0 (5x coins)
	character:SetAttribute("GoldMultiplier", 5.0)
	print("GOLD ABILITY: Set GoldMultiplier attribute to 5.0")
	
	-- Set gold glow attribute to true for visual effect
	character:SetAttribute("GoldGlowActive", true)
	print("GOLD ABILITY: Set GoldGlowActive attribute to true")
	
	print("GOLD ABILITY: Gold multiplier activated - 5x coins")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("GOLD ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("GoldMultiplier", nil)
		character:SetAttribute("GoldGlowActive", false)
		print("GOLD ABILITY: Gold multiplier deactivated")
	end
end

return Ability
