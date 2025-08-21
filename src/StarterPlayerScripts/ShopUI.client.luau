local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the shop GUI
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "ShopGUI"
shopGui.ResetOnSpawn = false
shopGui.Parent = playerGui

-- Main frame (larger size)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 800, 0, 500)
mainFrame.Position = UDim2.new(0.5, -400, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = shopGui

-- Corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "SHOP"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleLabel

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleLabel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Tab container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -40, 0, 50)
tabContainer.Position = UDim2.new(0, 20, 0, 80)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

-- Special Shop Tab (Robux)
local specialTab = Instance.new("TextButton")
specialTab.Name = "SpecialTab"
specialTab.Size = UDim2.new(0, 150, 0, 40)
specialTab.Position = UDim2.new(0, 0, 0, 0)
specialTab.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold color for Robux
specialTab.BorderSizePixel = 0
specialTab.Text = "SPECIAL SHOP"
specialTab.TextColor3 = Color3.fromRGB(0, 0, 0)
specialTab.TextScaled = true
specialTab.Font = Enum.Font.GothamBold
specialTab.Parent = tabContainer

local specialTabCorner = Instance.new("UICorner")
specialTabCorner.CornerRadius = UDim.new(0, 8)
specialTabCorner.Parent = specialTab

-- Coin Shop Tab
local coinTab = Instance.new("TextButton")
coinTab.Name = "CoinTab"
coinTab.Size = UDim2.new(0, 150, 0, 40)
coinTab.Position = UDim2.new(0, 170, 0, 0)
coinTab.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray for coin shop
coinTab.BorderSizePixel = 0
coinTab.Text = "COIN SHOP"
coinTab.TextColor3 = Color3.fromRGB(255, 255, 255)
coinTab.TextScaled = true
coinTab.Font = Enum.Font.GothamBold
coinTab.Parent = tabContainer

local coinTabCorner = Instance.new("UICorner")
coinTabCorner.CornerRadius = UDim.new(0, 8)
coinTabCorner.Parent = coinTab

-- Content area
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -40, 1, -150)
contentFrame.Position = UDim2.new(0, 20, 0, 150)
contentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentFrame

-- Special Shop Content
local specialContent = Instance.new("Frame")
specialContent.Name = "SpecialContent"
specialContent.Size = UDim2.new(1, 0, 1, 0)
specialContent.BackgroundTransparency = 1
specialContent.Parent = contentFrame

-- Special shop title
local specialTitle = Instance.new("TextLabel")
specialTitle.Name = "SpecialTitle"
specialTitle.Size = UDim2.new(1, 0, 0, 50)
specialTitle.Position = UDim2.new(0, 0, 0, 20)
specialTitle.BackgroundTransparency = 1
specialTitle.Text = "Premium Items"
specialTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
specialTitle.TextScaled = true
specialTitle.Font = Enum.Font.GothamBold
specialTitle.Parent = specialContent

-- Special shop items container
local specialItemsContainer = Instance.new("ScrollingFrame")
specialItemsContainer.Name = "SpecialItemsContainer"
specialItemsContainer.Size = UDim2.new(1, -40, 1, -100)
specialItemsContainer.Position = UDim2.new(0, 20, 0, 80)
specialItemsContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
specialItemsContainer.BorderSizePixel = 0
specialItemsContainer.ScrollBarThickness = 6
specialItemsContainer.Parent = specialContent

local specialItemsCorner = Instance.new("UICorner")
specialItemsCorner.CornerRadius = UDim.new(0, 6)
specialItemsCorner.Parent = specialItemsContainer

-- Coin Shop Content
local coinContent = Instance.new("Frame")
coinContent.Name = "CoinContent"
coinContent.Size = UDim2.new(1, 0, 1, 0)
coinContent.BackgroundTransparency = 1
coinContent.Visible = false
coinContent.Parent = contentFrame

-- Coin shop title
local coinTitle = Instance.new("TextLabel")
coinTitle.Name = "CoinTitle"
coinTitle.Size = UDim2.new(1, 0, 0, 50)
coinTitle.Position = UDim2.new(0, 0, 0, 20)
coinTitle.BackgroundTransparency = 1
coinTitle.Text = "Regular Items"
coinTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
coinTitle.TextScaled = true
coinTitle.Font = Enum.Font.GothamBold
coinTitle.Parent = coinContent

-- Coin shop items container
local coinItemsContainer = Instance.new("ScrollingFrame")
coinItemsContainer.Name = "CoinItemsContainer"
coinItemsContainer.Size = UDim2.new(1, -40, 1, -100)
coinItemsContainer.Position = UDim2.new(0, 20, 0, 80)
coinItemsContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
coinItemsContainer.BorderSizePixel = 0
coinItemsContainer.ScrollBarThickness = 6
coinItemsContainer.Parent = coinContent

local coinItemsCorner = Instance.new("UICorner")
coinItemsCorner.CornerRadius = UDim.new(0, 6)
coinItemsCorner.Parent = coinItemsContainer

-- Initially hide the GUI
shopGui.Enabled = false

-- Function to show/hide shop
local function toggleShop(show)
    shopGui.Enabled = show
end

-- Function to switch tabs
local function switchToTab(tabName)
    if tabName == "special" then
        specialContent.Visible = true
        coinContent.Visible = false
        specialTab.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        coinTab.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    else
        specialContent.Visible = false
        coinContent.Visible = true
        specialTab.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        coinTab.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    end
end

-- Tab button functionality
specialTab.MouseButton1Click:Connect(function()
    switchToTab("special")
end)

coinTab.MouseButton1Click:Connect(function()
    switchToTab("coin")
end)

-- Close button functionality
closeButton.MouseButton1Click:Connect(function()
    toggleShop(false)
end)

-- Make the script accessible to other scripts
_G.ShopUI = {
    toggleShop = toggleShop
}
