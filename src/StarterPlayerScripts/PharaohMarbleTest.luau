-- PharaohMarbleTest.luau
-- Test script to verify Pharaoh marble functionality
-- This can be used to test the Pharaoh marble ability

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for the MarblesModule to be available
local MarblesModule = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))

local function setupTestControls()
	-- Test controls for Pharaoh marble
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		
		-- P key: Test Pharaoh marble definition
		if input.KeyCode == Enum.KeyCode.P then
			local pharaohDef = MarblesModule.getById("Pharaoh")
			if pharaohDef then
				print("=== PHARAOH MARBLE TEST ===")
				print("ID:", pharaohDef.id)
				print("Name:", pharaohDef.name)
				print("Drop Denominator:", pharaohDef.dropDenominator)
				print("Rollable:", pharaohDef.rollable)
				print("Ability Module:", pharaohDef.abilityModule)
				print("Color:", pharaohDef.color)
				print("=========================")
			else
				print("ERROR: Pharaoh marble definition not found!")
			end
		end
		
		-- O key: Test Pharaoh ability module loading
		if input.KeyCode == Enum.KeyCode.O then
			local pharaohDef = MarblesModule.getById("Pharaoh")
			if pharaohDef then
				local ability = MarblesModule.getAbilityModule(pharaohDef)
				if ability then
					print("=== PHARAOH ABILITY TEST ===")
					print("Description:", ability.Description())
					print("Cooldown:", ability.Cooldown(), "seconds")
					print("ActivateAbility function:", type(ability.ActivateAbility))
					print("DeactivateAbility function:", type(ability.DeactivateAbility))
					print("===========================")
				else
					print("ERROR: Failed to load Pharaoh ability module!")
				end
			else
				print("ERROR: Pharaoh marble definition not found!")
			end
		end
		
		-- I key: List all marbles including Pharaoh
		if input.KeyCode == Enum.KeyCode.I then
			print("=== ALL MARBLES TEST ===")
			local allMarbles = MarblesModule.getAll()
			for _, marble in ipairs(allMarbles) do
				local isPharaoh = marble.id == "Pharaoh"
				local marker = isPharaoh and " *** PHARAOH ***" or ""
				print(string.format("%s: %s (1/%d)%s", marble.id, marble.name, marble.dropDenominator or 0, marker))
			end
			print("========================")
		end
		
		-- R key: Test rollable marbles
		if input.KeyCode == Enum.KeyCode.R then
			print("=== ROLLABLE MARBLES TEST ===")
			local rollableMarbles = MarblesModule.getRollable()
			for _, marble in ipairs(rollableMarbles) do
				local isPharaoh = marble.id == "Pharaoh"
				local marker = isPharaoh and " *** PHARAOH ***" or ""
				print(string.format("%s: %s (1/%d)%s", marble.id, marble.name, marble.dropDenominator, marker))
			end
			print("=============================")
		end
		
		-- T key: Test marble roll (should include Pharaoh)
		if input.KeyCode == Enum.KeyCode.T then
			print("=== MARBLE ROLL TEST ===")
			for i = 1, 10 do
				local rolledMarble = MarblesModule.roll()
				if rolledMarble then
					local isPharaoh = rolledMarble.id == "Pharaoh"
					local marker = isPharaoh and " *** PHARAOH ROLLED! ***" or ""
					print(string.format("Roll %d: %s%s", i, rolledMarble.name, marker))
				else
					print(string.format("Roll %d: No marble rolled", i))
				end
			end
			print("=======================")
		end
	end)
end

-- Initialize test controls
setupTestControls()

print("PharaohMarbleTest loaded!")
print("Test Controls:")
print("  P: Test Pharaoh marble definition")
print("  O: Test Pharaoh ability module loading")
print("  I: List all marbles (look for Pharaoh)")
print("  R: List rollable marbles (look for Pharaoh)")
print("  T: Test marble rolling (10 rolls, look for Pharaoh)")
print("")
print("The Pharaoh marble should:")
print("- Have ID 'Pharaoh' and name 'Pharaoh Marble'")
print("- Be rollable with 1/50 drop chance")
print("- Have ability module 'Pharaoh'")
print("- Have gold/yellow color (255, 215, 0)")
print("- Create a large scalable yellow pyramid (24x24 base, 16 studs tall) when activated")
print("- Have 15 second cooldown")
print("- Show red/gold trail effect when equipped")
print("- Use texture ID: rbxassetid://138858793251784")
