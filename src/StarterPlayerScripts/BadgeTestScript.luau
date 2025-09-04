-- BadgeTestScript.luau
-- Test script to demonstrate badge unlocking functionality
-- This can be used to test the badges system

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Wait for the BadgeSystem to be available
local BadgeSystem = require(script.Parent.BadgeSystem)

local function setupTestControls()
	-- Test controls for unlocking badges
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		
		-- Number keys 1-8 unlock badges 1-8
		if input.KeyCode >= Enum.KeyCode.One and input.KeyCode <= Enum.KeyCode.Eight then
			local levelNumber = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
			if BadgeSystem.unlockBadge(levelNumber) then
				print("Badge unlocked for level", levelNumber)
			else
				print("Failed to unlock badge for level", levelNumber)
			end
		end
		
		-- R key resets all badges to locked
		if input.KeyCode == Enum.KeyCode.R then
			if BadgeSystem.resetAllBadges() then
				print("All badges reset to locked")
			else
				print("Failed to reset badges")
			end
		end
		
		-- I key shows badge info
		if input.KeyCode == Enum.KeyCode.I then
			local unlockedCount = BadgeSystem.getUnlockedCount()
			print("Badge Info - Unlocked:", unlockedCount, "/ 8")
			
			for _, badge in ipairs(BadgeSystem.getAllBadges()) do
				local status = badge.unlocked and "UNLOCKED" or "LOCKED"
				print(string.format("  %s: %s", badge.name, status))
			end
		end
	end)
end

-- Initialize test controls
setupTestControls()

print("BadgeTestScript loaded!")
print("Controls:")
print("  1-8: Unlock badges for levels 1-8")
print("  I: Show badge information")
print("  R: Reset all badges to locked")
