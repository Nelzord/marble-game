-- Marble UI LocalScript
-- Builds a simple UI with:
-- - Roll for Marble button
-- - Inventory toggle button and list of owned marbles to equip

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RollForMarble: RemoteEvent = RemotesFolder:WaitForChild("RollForMarble")
local EquipMarble: RemoteEvent = RemotesFolder:WaitForChild("EquipMarble")
local InventoryUpdate: RemoteEvent = RemotesFolder:WaitForChild("InventoryUpdate")
local RollResult: RemoteEvent = RemotesFolder:WaitForChild("RollResult")
local RequestInventory: RemoteEvent = RemotesFolder:WaitForChild("RequestInventory")
local ActivateAbility: RemoteEvent = RemotesFolder:WaitForChild("ActivateAbility")

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))

-- UI construction
local screen = Instance.new("ScreenGui")
screen.Name = "MarbleUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = playerGui

local rollButton = Instance.new("TextButton")
rollButton.Name = "RollButton"
rollButton.Text = "Roll for Marble"
rollButton.TextScaled = true
rollButton.Size = UDim2.fromOffset(200, 56)
rollButton.Position = UDim2.new(0.5, 0, 1, -24)
rollButton.AnchorPoint = Vector2.new(0.5, 1)
rollButton.BackgroundColor3 = Color3.fromRGB(28, 167, 76)
rollButton.TextColor3 = Color3.new(1,1,1)
rollButton.Parent = screen

local inventoryButton = Instance.new("TextButton")
inventoryButton.Name = "InventoryButton"
inventoryButton.Text = "Inventory"
inventoryButton.TextScaled = true
inventoryButton.Size = UDim2.fromOffset(160, 40)
inventoryButton.Position = UDim2.new(0, 16, 0, 16)
inventoryButton.AnchorPoint = Vector2.new(0, 0)
inventoryButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
inventoryButton.TextColor3 = Color3.new(1,1,1)
inventoryButton.Parent = screen

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Text = ""
resultLabel.TextScaled = true
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = Color3.new(1,1,1)
resultLabel.Size = UDim2.fromOffset(480, 40)
resultLabel.Position = UDim2.new(0.5, 0, 1, -88)
resultLabel.AnchorPoint = Vector2.new(0.5, 1)
resultLabel.Parent = screen

local invFrame = Instance.new("Frame")
invFrame.Name = "InventoryFrame"
invFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
invFrame.BackgroundTransparency = 0.2 -- semi-transparent
invFrame.BorderSizePixel = 0
invFrame.Size = UDim2.new(0, 640, 0, 420)
invFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
invFrame.AnchorPoint = Vector2.new(0.5, 0.5)
invFrame.Visible = false
invFrame.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = invFrame

local header = Instance.new("TextLabel")
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, -24, 0, 40)
header.Position = UDim2.new(0, 12, 0, 10)
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = "Inventory"
header.TextColor3 = Color3.new(1,1,1)
header.TextSize = 24
header.Parent = invFrame

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Size = UDim2.new(1, -24, 1, -64)
list.Position = UDim2.new(0, 12, 0, 52)
list.ScrollBarThickness = 8
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.BackgroundTransparency = 1
list.Parent = invFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function refreshCanvasSize()
	local abs = layout.AbsoluteContentSize
	list.CanvasSize = UDim2.new(0, 0, 0, abs.Y + 8)
end
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvasSize)

-- State
local ownedSet: { [string]: boolean } = {}
local equippedId: string? = nil

local function rebuildInventoryUI()
	-- Remove existing buttons but keep the layout
	for _, child in ipairs(list:GetChildren()) do
		if child ~= layout then
			child:Destroy()
		end
	end
	for _, def in ipairs(Marbles.getAll()) do
		if ownedSet[def.id] then
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, -8, 0, 44)
			button.BackgroundColor3 = def.id == equippedId and Color3.fromRGB(38, 110, 180) or Color3.fromRGB(50, 50, 50)
			button.TextColor3 = Color3.new(1,1,1)
			button.AutoButtonColor = true
			button.Text = (def.name .. (def.id == equippedId and "  (Equipped)" or ""))
			button.Parent = list
			button.MouseButton1Click:Connect(function()
				if def.id ~= equippedId then
					EquipMarble:FireServer(def.id)
				end
			end)
		end
	end
	refreshCanvasSize()
end

-- Event wiring
rollButton.MouseButton1Click:Connect(function()
	RollForMarble:FireServer()
end)

inventoryButton.MouseButton1Click:Connect(function()
	invFrame.Visible = not invFrame.Visible
end)

InventoryUpdate.OnClientEvent:Connect(function(payload)
	ownedSet = {}
	for _, id in ipairs(payload.owned :: {string}) do
		ownedSet[id] = true
	end
	equippedId = payload.equipped
	rebuildInventoryUI()
end)

RollResult.OnClientEvent:Connect(function(result)
	if result.success then
		local suffix = result.new and " (New!)" or ""
		resultLabel.Text = string.format("Rolled: %s%s", result.marbleName or result.marbleId or "?", suffix)
	else
		resultLabel.Text = result.message or "Roll failed"
	end
	task.delay(4, function()
		if resultLabel then resultLabel.Text = "" end
	end)
end)

-- Ability activation keybind (F)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F then
		ActivateAbility:FireServer()
	end
end)

-- Request initial inventory
RequestInventory:FireServer() 