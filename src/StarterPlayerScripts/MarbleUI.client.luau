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

-- Close button (top-right)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextScaled = true
closeButton.Size = UDim2.fromOffset(36, 36)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Parent = invFrame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton
closeButton.MouseButton1Click:Connect(function()
	invFrame.Visible = false
end)

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

local function formatOdds(def)
	local denom = def.dropDenominator
	local rollable = def.rollable and denom and denom > 0
	if not rollable then
		return "Not rollable"
	end
	local pct = 100 / denom
	local pctStr = string.format("%.1f%%", pct)
	return string.format("Odds: 1/%d (%s)", denom, pctStr)
end

local function createMarbleRow(def)
	local isOwned = ownedSet[def.id] == true
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 56)
	row.BackgroundColor3 = (def.id == equippedId and isOwned) and Color3.fromRGB(38, 110, 180) or Color3.fromRGB(50, 50, 50)
	row.BorderSizePixel = 0

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.fromOffset(36, 36)
	swatch.Position = UDim2.new(0, 6, 0.5, 0)
	swatch.AnchorPoint = Vector2.new(0, 0.5)
	swatch.BackgroundColor3 = isOwned and (def.color or Color3.fromRGB(230,230,230)) or Color3.fromRGB(80,80,80)
	swatch.BorderSizePixel = 0
	swatch.Parent = row

	local swCorner = Instance.new("UICorner")
	swCorner.CornerRadius = UDim.new(1, 0)
	swCorner.Parent = swatch

	if not isOwned then
		local q = Instance.new("TextLabel")
		q.BackgroundTransparency = 1
		q.Size = UDim2.fromScale(1,1)
		q.TextScaled = true
		q.Text = "?"
		q.Font = Enum.Font.GothamBold
		q.TextColor3 = Color3.new(1,1,1)
		q.Parent = swatch
	end

	local nameButton = Instance.new("TextButton")
	nameButton.Size = UDim2.new(1, -52, 0, 30)
	nameButton.Position = UDim2.new(0, 46, 0, 6)
	nameButton.BackgroundColor3 = Color3.fromRGB(0,0,0)
	nameButton.BackgroundTransparency = isOwned and 0.4 or 0.7
	nameButton.TextColor3 = isOwned and Color3.new(1,1,1) or Color3.fromRGB(200,200,200)
	nameButton.AutoButtonColor = isOwned
	nameButton.Text = (isOwned and (def.name .. (def.id == equippedId and "  (Equipped)" or "")) or "???  (Locked)")
	nameButton.Parent = row
	if isOwned then
		nameButton.MouseButton1Click:Connect(function()
			if def.id ~= equippedId then
				EquipMarble:FireServer(def.id)
			end
		end)
	end

	local odds = Instance.new("TextLabel")
	odds.BackgroundTransparency = 1
	odds.TextXAlignment = Enum.TextXAlignment.Left
	odds.Size = UDim2.new(1, -52, 0, 18)
	odds.Position = UDim2.new(0, 46, 0, 34)
	odds.TextColor3 = Color3.fromRGB(220,220,220)
	odds.TextScaled = true
	odds.Text = formatOdds(def)
	odds.Parent = row

	return row
end

local function rebuildInventoryUI()
	-- Remove existing items but keep the layout
	for _, child in ipairs(list:GetChildren()) do
		if child ~= layout then
			child:Destroy()
		end
	end
	for _, def in ipairs(Marbles.getAll()) do
		local row = createMarbleRow(def)
		row.Parent = list
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
		local suffix = result.new and "  (Unlocked!)" or ""
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