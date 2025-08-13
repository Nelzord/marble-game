-- Gumball marble ability: jump/launch boost
local Ability = {}

function Ability.Description()
	return "Gumball: A bouncy marble that can launch high into the air with explosive force."
end

function Ability.Cooldown()
	return 4 -- 4 second cooldown
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("GUMBALL ABILITY: Activating for player:", player.Name)
	
	-- Check if jump boost is already active
	local prev = character:GetAttribute("JumpBoostActive")
	if typeof(prev) == "boolean" and prev then 
		print("GUMBALL ABILITY: Already active")
		return 
	end
	
	-- Set jump boost attribute to true for physics effect
	character:SetAttribute("JumpBoostActive", true)
	
	-- Set gumball glow attribute to true for visual effect
	character:SetAttribute("GumballGlowActive", true)
	
	-- Duration: 0.75 seconds (half the original duration for shorter air time)
	local jumpTimer = task.delay(0.35, function()
		if character then
			character:SetAttribute("JumpBoostActive", false)
			character:SetAttribute("GumballGlowActive", false)
			print("GUMBALL ABILITY: Jump boost ended")
		end
	end)
	
	-- Store the timer reference so we can cancel it if needed
	character:SetAttribute("GumballJumpTimer", jumpTimer)
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("GUMBALL ABILITY: Deactivating for player:", player.Name)
	
	if character then
		-- Cancel the jump timer if it's still running
		local timerRef = character:GetAttribute("GumballJumpTimer")
		if timerRef then
			-- Cancel the actual timer thread
			pcall(function()
				task.cancel(timerRef)
			end)
			character:SetAttribute("GumballJumpTimer", nil)
		end
		
		character:SetAttribute("JumpBoostActive", false)
		character:SetAttribute("GumballGlowActive", false)
	end
end

return Ability
