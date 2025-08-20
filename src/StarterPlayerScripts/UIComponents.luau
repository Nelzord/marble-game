-- UIComponents.luau
-- Handles creation and management of individual UI components

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIComponents = {}

-- Create a rounded corner for UI elements
function UIComponents.createCorner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

-- Create the main screen GUI
function UIComponents.createScreenGui()
	local screen = Instance.new("ScreenGui")
	screen.Name = "MarbleUI"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = false
	return screen
end

-- Create the power button with all its components
function UIComponents.createPowerButton(screen: ScreenGui)
	local powerButton = Instance.new("TextButton")
	powerButton.Name = "PowerButton"
	powerButton.Text = "Power (E)"
	powerButton.TextScaled = true
	powerButton.Size = UDim2.fromOffset(200, 56)
	powerButton.Position = UDim2.new(0.5, -110, 1, -24)
	powerButton.AnchorPoint = Vector2.new(0.5, 1)
	powerButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
	powerButton.TextColor3 = Color3.new(1, 1, 1)
	powerButton.Font = Enum.Font.GothamBold
	powerButton.Parent = screen
	
	UIComponents.createCorner(powerButton, 8)
	
	-- Create cooldown overlay
	local powerCooldown = Instance.new("Frame")
	powerCooldown.Name = "CooldownOverlay"
	powerCooldown.Size = UDim2.new(1, 0, 1, 0)
	powerCooldown.Position = UDim2.new(0, 0, 0, 0)
	powerCooldown.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
	powerCooldown.BackgroundTransparency = 0.4
	powerCooldown.Visible = false
	powerCooldown.Parent = powerButton
	
	UIComponents.createCorner(powerCooldown, 8)
	
	-- Create cooldown text
	local cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.Size = UDim2.new(1, 0, 1, 0)
	cooldownText.Position = UDim2.new(0, 0, 0, 0)
	cooldownText.BackgroundTransparency = 1
	cooldownText.Text = ""
	cooldownText.TextScaled = true
	cooldownText.TextColor3 = Color3.new(1, 1, 1)
	cooldownText.Font = Enum.Font.GothamBold
	cooldownText.Visible = false
	cooldownText.Parent = powerButton
	
	-- Create text shadow
	local textShadow = Instance.new("TextLabel")
	textShadow.Name = "TextShadow"
	textShadow.Size = UDim2.new(1, 0, 1, 0)
	textShadow.Position = UDim2.new(0, 1, 0, 1)
	textShadow.BackgroundTransparency = 1
	textShadow.Text = ""
	textShadow.TextScaled = true
	textShadow.TextColor3 = Color3.new(0, 0, 0)
	textShadow.Font = Enum.Font.GothamBold
	textShadow.Visible = false
	textShadow.Parent = powerButton
	textShadow.ZIndex = cooldownText.ZIndex - 1
	
	return powerButton, powerCooldown, cooldownText, textShadow
end

-- Create the roll button
function UIComponents.createRollButton(screen: ScreenGui)
	local rollButton = Instance.new("TextButton")
	rollButton.Name = "RollButton"
	rollButton.Text = "Roll for Marble"
	rollButton.TextScaled = true
	rollButton.Size = UDim2.fromOffset(200, 56)
	rollButton.Position = UDim2.new(0.5, 110, 1, -24)
	rollButton.AnchorPoint = Vector2.new(0.5, 1)
	rollButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	rollButton.TextColor3 = Color3.new(1, 1, 1)
	rollButton.Font = Enum.Font.GothamBold
	rollButton.Parent = screen
	
	UIComponents.createCorner(rollButton, 8)
	
	return rollButton
end

-- Create the inventory button
function UIComponents.createInventoryButton(screen: ScreenGui)
	local inventoryButton = Instance.new("TextButton")
	inventoryButton.Name = "InventoryButton"
	inventoryButton.Text = "Inventory"
	inventoryButton.TextScaled = true
	inventoryButton.Size = UDim2.fromOffset(160, 40)
	inventoryButton.Position = UDim2.new(0, 16, 0, 16)
	inventoryButton.AnchorPoint = Vector2.new(0, 0)
	inventoryButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	inventoryButton.TextColor3 = Color3.new(1, 1, 1)
	inventoryButton.Font = Enum.Font.GothamBold
	inventoryButton.Parent = screen
	
	UIComponents.createCorner(inventoryButton, 8)
	
	return inventoryButton
end

-- Create the result label
function UIComponents.createResultLabel(screen: ScreenGui)
	local resultLabel = Instance.new("TextLabel")
	resultLabel.Name = "ResultLabel"
	resultLabel.Text = ""
	resultLabel.TextScaled = true
	resultLabel.BackgroundTransparency = 1
	resultLabel.TextColor3 = Color3.new(1, 1, 1)
	resultLabel.Size = UDim2.fromOffset(480, 40)
	resultLabel.Position = UDim2.new(0.5, 0, 1, -88)
	resultLabel.AnchorPoint = Vector2.new(0.5, 1)
	resultLabel.Parent = screen
	
	return resultLabel
end

-- Create the inventory frame
function UIComponents.createInventoryFrame(screen: ScreenGui)
	local invFrame = Instance.new("Frame")
	invFrame.Name = "InventoryFrame"
	invFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	invFrame.BackgroundTransparency = 0.2
	invFrame.BorderSizePixel = 0
	invFrame.Size = UDim2.new(0, 720, 0, 520)
	invFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	invFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	invFrame.Visible = false
	invFrame.Parent = screen
	
	UIComponents.createCorner(invFrame, 8)
	
	-- Create header
	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, -24, 0, 40)
	header.Position = UDim2.new(0, 12, 0, 10)
	header.Font = Enum.Font.GothamBold
	header.TextXAlignment = Enum.TextXAlignment.Center
	header.Text = "Inventory"
	header.TextColor3 = Color3.new(1, 1, 1)
	header.TextSize = 24
	header.Parent = invFrame
	
	-- Create close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextScaled = true
	closeButton.Size = UDim2.fromOffset(36, 36)
	closeButton.Position = UDim2.new(1, -12, 0, 12)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Parent = invFrame
	
	UIComponents.createCorner(closeButton, 8)
	
	-- Create scrolling list
	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Size = UDim2.new(1, -24, 1, -80)
	list.Position = UDim2.new(0, 12, 0, 60)
	list.ScrollBarThickness = 8
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.BackgroundTransparency = 1
	list.Parent = invFrame
	
	-- Create grid layout
	local grid = Instance.new("UIGridLayout")
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.FillDirectionMaxCells = 3
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.CellSize = UDim2.fromOffset(200, 200)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = list
	
	return invFrame, closeButton, list, grid
end

-- Create sound effects
function UIComponents.createSoundEffects(screen: ScreenGui)
	local invOpenSfx = Instance.new("Sound")
	invOpenSfx.Name = "InventoryOpenSfx"
	invOpenSfx.SoundId = "rbxassetid://127877437691780"
	invOpenSfx.Volume = 0.6
	invOpenSfx.Parent = screen
	
	return invOpenSfx
end

return UIComponents
