-- Marble UI LocalScript (Refactored)
-- Main entry point that coordinates all UI modules

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require all UI modules
local UIManager = require(ReplicatedStorage:WaitForChild("UIManager"))
local PowerButton = require(ReplicatedStorage:WaitForChild("PowerButton"))
local RollAnimation = require(ReplicatedStorage:WaitForChild("RollAnimation"))
local InventoryUI = require(ReplicatedStorage:WaitForChild("InventoryUI"))

-- Debug: Log all available marbles and their definitions
print("=== Marble Definitions ===")
local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))
local allMarbles = Marbles.getAll()
for _, marble in ipairs(allMarbles) do
	print(string.format("Marble: %s, abilityModule: %s, rollable: %s", 
		marble.id, 
		marble.abilityModule or "nil", 
		tostring(marble.rollable)))
end
print("=== End Marble Definitions ===")

-- Set up module references in UIManager
UIManager:setModules(PowerButton, RollAnimation, InventoryUI)

-- Initialize the UI system
UIManager:init()

print("=== MarbleUI Client Script Complete ===")