-- HazardTest: Creates a test hazard part for testing the hazard system
-- This script creates a red hazard part that players will be teleported from when touched

local workspace = game:GetService("Workspace")

-- Create a test hazard part
local function createTestHazard()
	local hazard = Instance.new("Part")
	hazard.Name = "hazard"
	hazard.Size = Vector3.new(10, 2, 10)
	hazard.Position = Vector3.new(0, 1, 50) -- Place it away from spawn
	hazard.Color = Color3.fromRGB(255, 0, 0) -- Red color to indicate danger
	hazard.Material = Enum.Material.Neon
	hazard.CanCollide = true
	hazard.Anchored = true
	hazard.Parent = workspace
	
	-- Add a warning sign
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.Parent = hazard
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "HAZARD - DO NOT TOUCH!"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	
	print("[HazardTest] Created test hazard at position:", hazard.Position)
end

-- Create the test hazard
createTestHazard()
