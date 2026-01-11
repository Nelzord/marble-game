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
	powerButton.Size = UDim2.fromOffset(150, 56)
	powerButton.Position = UDim2.new(0.5, 80, 1, -24)
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
	rollButton.Size = UDim2.fromOffset(150, 56)
	rollButton.Position = UDim2.new(0.5, -80, 1, -24)
	rollButton.AnchorPoint = Vector2.new(0.5, 1)
	rollButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	rollButton.TextColor3 = Color3.new(1, 1, 1)
	rollButton.Font = Enum.Font.GothamBold
	rollButton.Parent = screen
	
	UIComponents.createCorner(rollButton, 8)
	
	return rollButton
end

-- Create the auto roll button (toggle for automatic rolling)
function UIComponents.createAutoRollButton(screen: ScreenGui)
	local autoButton = Instance.new("TextButton")
	autoButton.Name = "AutoRollButton"
	autoButton.Text = "Auto\nOFF"
	autoButton.TextScaled = true
	autoButton.Size = UDim2.fromOffset(56, 56)
	-- Position to the left of roll button: roll is at -80, width 150, so left edge is at -155
	-- Auto button (56 wide, anchor 0.5) center at -155 - 10 gap - 28 = -193
	autoButton.Position = UDim2.new(0.5, -193, 1, -24)
	autoButton.AnchorPoint = Vector2.new(0.5, 1)
	autoButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	autoButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	autoButton.Font = Enum.Font.GothamBold
	autoButton.Parent = screen
	
	UIComponents.createCorner(autoButton, 8)
	
	return autoButton
end

-- Create the inventory button
function UIComponents.createInventoryButton(screen: ScreenGui)
	local inventoryButton = Instance.new("TextButton")
	inventoryButton.Name = "InventoryButton"
	inventoryButton.Text = "Marbles"
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

-- Create the badges button
function UIComponents.createBadgesButton(screen: ScreenGui)
	local badgesButton = Instance.new("TextButton")
	badgesButton.Name = "BadgesButton"
	badgesButton.Text = "Badges"
	badgesButton.TextScaled = true
	badgesButton.Size = UDim2.fromOffset(160, 40)
	badgesButton.Position = UDim2.new(0, 16, 0, 64)
	badgesButton.AnchorPoint = Vector2.new(0, 0)
	badgesButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	badgesButton.TextColor3 = Color3.new(1, 1, 1)
	badgesButton.Font = Enum.Font.GothamBold
	badgesButton.Parent = screen
	
	UIComponents.createCorner(badgesButton, 8)
	
	return badgesButton
end

-- Create the shop button
function UIComponents.createShopButton(screen: ScreenGui)
	local shopButton = Instance.new("TextButton")
	shopButton.Name = "ShopButton"
	shopButton.Text = "Shop"
	shopButton.TextScaled = true
	shopButton.Size = UDim2.fromOffset(160, 40)
	shopButton.Position = UDim2.new(0, 16, 0, 112)
	shopButton.AnchorPoint = Vector2.new(0, 0)
	shopButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	shopButton.TextColor3 = Color3.new(1, 1, 1)
	shopButton.Font = Enum.Font.GothamBold
	shopButton.Parent = screen
	
	UIComponents.createCorner(shopButton, 8)
	
	-- "Sale!" banner in top-right corner
	local saleBanner = Instance.new("Frame")
	saleBanner.Name = "SaleBanner"
	saleBanner.Size = UDim2.new(0, 0, 0, 16)
	saleBanner.Position = UDim2.new(1, -5, 0, -3)
	saleBanner.AnchorPoint = Vector2.new(1, 0)
	saleBanner.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold/yellow
	saleBanner.BorderSizePixel = 0
	saleBanner.ZIndex = 10
	saleBanner.Parent = shopButton
	
	local saleBannerCorner = Instance.new("UICorner")
	saleBannerCorner.CornerRadius = UDim.new(0, 3)
	saleBannerCorner.Parent = saleBanner
	
	local saleBannerLabel = Instance.new("TextLabel")
	saleBannerLabel.Name = "SaleBannerLabel"
	saleBannerLabel.Size = UDim2.new(1, -6, 1, -4)
	saleBannerLabel.Position = UDim2.new(0, 3, 0, 2)
	saleBannerLabel.BackgroundTransparency = 1
	saleBannerLabel.Text = "Sale!"
	saleBannerLabel.TextColor3 = Color3.fromRGB(0, 0, 0) -- Black text
	saleBannerLabel.TextSize = 10
	saleBannerLabel.Font = Enum.Font.GothamBold
	saleBannerLabel.TextXAlignment = Enum.TextXAlignment.Center
	saleBannerLabel.ZIndex = 11
	saleBannerLabel.Parent = saleBanner
	
	-- Update banner width based on text
	saleBannerLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
		saleBanner.Size = UDim2.new(0, saleBannerLabel.TextBounds.X + 6, 0, 16)
	end)
	
	return shopButton
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
	invFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	invFrame.BackgroundTransparency = 0
	invFrame.BorderSizePixel = 0
	invFrame.Size = UDim2.new(0, 688, 0, 416)
	invFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	invFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	invFrame.Visible = false
	invFrame.Parent = screen
	
	UIComponents.createCorner(invFrame, 12)
	
	-- Create header
	local header = Instance.new("TextLabel")
	header.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1, 0, 0, 50)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.Font = Enum.Font.GothamBold
	header.TextXAlignment = Enum.TextXAlignment.Center
	header.Text = "INVENTORY"
	header.TextColor3 = Color3.new(1, 1, 1)
	header.TextScaled = true
	header.Parent = invFrame
	
	-- Add rounded corners to header
	UIComponents.createCorner(header, 12)
	
	-- Create close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextScaled = true
	closeButton.Size = UDim2.fromOffset(40, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 5)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Parent = header
	
	UIComponents.createCorner(closeButton, 8)
	
	-- Create scrolling list
	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Size = UDim2.new(1, -24, 1, -80)
	list.Position = UDim2.new(0, 12, 0, 60)
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	list.BorderSizePixel = 0
	list.Parent = invFrame
	
	-- Add rounded corners to the scrolling frame
	UIComponents.createCorner(list, 6)
	
	-- Create grid layout
	local grid = Instance.new("UIGridLayout")
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.FillDirectionMaxCells = 4
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.CellSize = UDim2.fromOffset(200, 200)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = list
	
	return invFrame, closeButton, list, grid
end

-- Create the badges frame
function UIComponents.createBadgesFrame(screen: ScreenGui)
	local badgesFrame = Instance.new("Frame")
	badgesFrame.Name = "BadgesFrame"
	badgesFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	badgesFrame.BackgroundTransparency = 0
	badgesFrame.BorderSizePixel = 0
	badgesFrame.Size = UDim2.new(0, 576, 0, 416)
	badgesFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	badgesFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	badgesFrame.Visible = false
	badgesFrame.Parent = screen
	
	UIComponents.createCorner(badgesFrame, 12)
	
	-- Create header
	local header = Instance.new("TextLabel")
	header.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1, 0, 0, 50)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.Font = Enum.Font.GothamBold
	header.TextXAlignment = Enum.TextXAlignment.Center
	header.Text = "BADGES"
	header.TextColor3 = Color3.new(1, 1, 1)
	header.TextScaled = true
	header.Parent = badgesFrame
	
	-- Add rounded corners to header
	UIComponents.createCorner(header, 12)
	
	-- Create close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextScaled = true
	closeButton.Size = UDim2.fromOffset(40, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 5)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Parent = header
	
	UIComponents.createCorner(closeButton, 8)
	
	-- Create world selection tabs
	local worldTabs = Instance.new("Frame")
	worldTabs.Name = "WorldTabs"
	worldTabs.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	worldTabs.BorderSizePixel = 0
	worldTabs.Size = UDim2.new(1, -24, 0, 40)
	worldTabs.Position = UDim2.new(0, 12, 0, 60)
	worldTabs.Parent = badgesFrame
	
	UIComponents.createCorner(worldTabs, 6)
	
	-- World 1 tab
	local world1Tab = Instance.new("TextButton")
	world1Tab.Name = "World1Tab"
	world1Tab.Text = "World 1"
	world1Tab.Font = Enum.Font.GothamBold
	world1Tab.TextScaled = true
	world1Tab.Size = UDim2.new(0.5, -5, 1, -8)
	world1Tab.Position = UDim2.new(0, 4, 0, 4)
	world1Tab.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
	world1Tab.TextColor3 = Color3.new(1, 1, 1)
	world1Tab.Parent = worldTabs
	
	UIComponents.createCorner(world1Tab, 4)
	
	-- World 2 tab
	local world2Tab = Instance.new("TextButton")
	world2Tab.Name = "World2Tab"
	world2Tab.Text = "World 2 (Locked)"
	world2Tab.Font = Enum.Font.GothamBold
	world2Tab.TextScaled = true
	world2Tab.Size = UDim2.new(0.5, -5, 1, -8)
	world2Tab.Position = UDim2.new(0.5, 1, 0, 4)
	world2Tab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	world2Tab.TextColor3 = Color3.fromRGB(150, 150, 150)
	world2Tab.Parent = worldTabs
	
	UIComponents.createCorner(world2Tab, 4)
	
	-- Create scrolling list
	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Size = UDim2.new(1, -24, 1, -120)
	list.Position = UDim2.new(0, 12, 0, 100)
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	list.BorderSizePixel = 0
	list.Parent = badgesFrame
	
	-- Add rounded corners to the scrolling frame
	UIComponents.createCorner(list, 6)
	
	-- Create grid layout (4 columns for badges since they're smaller)
	local grid = Instance.new("UIGridLayout")
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.FillDirectionMaxCells = 4
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.CellSize = UDim2.fromOffset(150, 150)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = list
	
	return badgesFrame, closeButton, list, grid, world1Tab, world2Tab
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

-- Create arrow indicator pointing to roll button
function UIComponents.createRollButtonArrow(screen: ScreenGui, rollButton: TextButton)
	local TweenService = game:GetService("TweenService")
	
	-- Create container frame for the arrow
	local arrowContainer = Instance.new("Frame")
	arrowContainer.Name = "RollButtonArrow"
	arrowContainer.BackgroundTransparency = 1

	arrowContainer.Size = UDim2.fromOffset(120, 120) -- square for down arrow

	-- Position above the roll button (which is at 0.5, -80)
	arrowContainer.AnchorPoint = Vector2.new(0.5, 1)
	arrowContainer.Position = UDim2.new(0.5, -80, 1, -55)

	arrowContainer.Parent = screen
	arrowContainer.ZIndex = 10
	arrowContainer.Visible = false

	-- Arrow label
	local arrowLabel = Instance.new("TextLabel")
	arrowLabel.Name = "Arrow"
	arrowLabel.Size = UDim2.new(1, 0, 1, 0)
	arrowLabel.BackgroundTransparency = 1

	arrowLabel.Text = "↓"
	arrowLabel.TextColor3 = Color3.fromRGB(255, 50, 50)

	-- CONTROL SIZE + THICKNESS 👇
	arrowLabel.TextScaled = false
	arrowLabel.TextSize = 180 -- increase for thicker arrow
	arrowLabel.Font = Enum.Font.GothamBlack

	arrowLabel.Parent = arrowContainer
	arrowLabel.ZIndex = 11

	
	-- Create pulsing animation
	local pulseTween: Tween? = nil
	local function startPulse()
		-- Cancel existing tween if any
		if pulseTween then
			pulseTween:Cancel()
		end
		
		-- Create new pulse animation
		local pulseInfo = TweenInfo.new(
			0.8,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1, -- Repeat infinitely
			true -- Reverse
		)
		pulseTween = TweenService:Create(arrowLabel, pulseInfo, {
			TextTransparency = 0.3
		})
		pulseTween:Play()
	end
	
	-- Function to hide the arrow
	local function hideArrow()
		if arrowContainer and arrowContainer.Parent then
			arrowContainer.Visible = false
		end
		if pulseTween then
			pulseTween:Cancel()
			pulseTween = nil
		end
	end
	
	-- Function to show the arrow
	local function showArrow()
		if arrowContainer and arrowContainer.Parent then
			arrowContainer.Visible = true
			arrowLabel.TextTransparency = 0
			startPulse()
		end
	end
	
	return arrowContainer, hideArrow, showArrow
end

-- Create badge popup notification
function UIComponents.createBadgePopup(screen: ScreenGui)
	local TweenService = game:GetService("TweenService")
	
	-- Create popup frame
	local popup = Instance.new("Frame")
	popup.Name = "BadgePopup"
	popup.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	popup.BorderSizePixel = 0
	popup.Size = UDim2.fromOffset(400, 120)
	popup.Position = UDim2.new(0.5, 0, 0.2, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Parent = screen
	popup.ZIndex = 20
	popup.Visible = false
	popup.ClipsDescendants = false
	
	UIComponents.createCorner(popup, 12)
	
	-- Add border glow effect
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(100, 200, 100)
	border.Thickness = 3
	border.Transparency = 0
	border.Parent = popup
	
	-- Badge icon/emoji
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(60, 60)
	icon.Position = UDim2.new(0, 20, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = "🏆"
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.fromRGB(255, 215, 0)
	icon.TextTransparency = 0
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.TextYAlignment = Enum.TextYAlignment.Center
	icon.ZIndex = 21
	icon.Visible = true
	icon.Parent = popup
	
	-- Badge name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -100, 0, 40)
	nameLabel.Position = UDim2.new(0, 100, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Badge X"
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextTransparency = 0
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.ZIndex = 21
	nameLabel.Visible = true
	nameLabel.Parent = popup
	
	-- Status label (Unlocked/Already Unlocked)
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -100, 0, 30)
	statusLabel.Position = UDim2.new(0, 100, 0, 60)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Badge Unlocked!"
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
	statusLabel.TextTransparency = 0
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center
	statusLabel.ZIndex = 21
	statusLabel.Visible = true
	statusLabel.Parent = popup
	
	-- Function to show popup
	local function showPopup(badgeNumber: number, badgeName: string, alreadyUnlocked: boolean)
		print("showPopup called:", badgeNumber, badgeName, alreadyUnlocked)
		
		-- Update popup content
		nameLabel.Text = badgeName or ("Badge " .. tostring(badgeNumber))
		nameLabel.TextTransparency = 0
		nameLabel.Visible = true
		
		if alreadyUnlocked then
			statusLabel.Text = "Already Unlocked"
			statusLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
			border.Color = Color3.fromRGB(200, 200, 100)
		else
			statusLabel.Text = "Unlocked!"
			statusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
			border.Color = Color3.fromRGB(100, 200, 100)
		end
		statusLabel.TextTransparency = 0
		statusLabel.Visible = true
		
		icon.TextTransparency = 0
		icon.Visible = true
		
		-- Reset position and transparency
		popup.Position = UDim2.new(0.5, 0, 0.1, -50)
		popup.BackgroundTransparency = 0
		popup.Visible = true
		
		print("Popup visible set to true, nameLabel.Text:", nameLabel.Text, "statusLabel.Text:", statusLabel.Text)
		
		-- Animate in
		local slideIn = TweenService:Create(
			popup,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Position = UDim2.new(0.5, 0, 0.2, 0), BackgroundTransparency = 0}
		)
		slideIn:Play()
		
		-- Wait then animate out
		task.wait(2.5)
		
		local slideOut = TweenService:Create(
			popup,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0.1, -50), BackgroundTransparency = 1}
		)
		slideOut:Play()
		
		slideOut.Completed:Connect(function()
			popup.Visible = false
		end)
	end
	
	return popup, showPopup
end

return UIComponents
