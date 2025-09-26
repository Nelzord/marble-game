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
		
		-- Number keys 9-0 unlock badges 9-10, and Q-P unlock badges 11-12
		if input.KeyCode == Enum.KeyCode.Nine then
			if BadgeSystem.unlockBadge(9) then
				print("Badge unlocked for level 9")
			else
				print("Failed to unlock badge for level 9")
			end
		elseif input.KeyCode == Enum.KeyCode.Zero then
			if BadgeSystem.unlockBadge(10) then
				print("Badge unlocked for level 10")
			else
				print("Failed to unlock badge for level 10")
			end
		elseif input.KeyCode == Enum.KeyCode.Q then
			if BadgeSystem.unlockBadge(11) then
				print("Badge unlocked for level 11")
			else
				print("Failed to unlock badge for level 11")
			end
		elseif input.KeyCode == Enum.KeyCode.W then
			if BadgeSystem.unlockBadge(12) then
				print("Badge unlocked for level 12")
			else
				print("Failed to unlock badge for level 12")
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
			print("Badge Info - Unlocked:", unlockedCount, "/ 12")
			
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
print("  9-0: Unlock badges for levels 9-10")
print("  Q-W: Unlock badges for levels 11-12")
print("  I: Show badge information")
print("  R: Reset all badges to locked")
