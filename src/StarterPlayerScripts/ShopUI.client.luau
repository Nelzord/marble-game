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

-- Luck display
local luckDisplay = Instance.new("TextLabel")
luckDisplay.Name = "LuckDisplay"
luckDisplay.Size = UDim2.new(1, -20, 0, 30)
luckDisplay.Position = UDim2.new(0, 10, 0, 70)
luckDisplay.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
luckDisplay.BorderSizePixel = 0
luckDisplay.Text = "Current Luck: 1.0x"
luckDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
luckDisplay.TextScaled = true
luckDisplay.Font = Enum.Font.GothamBold
luckDisplay.Parent = coinContent

local luckCorner = Instance.new("UICorner")
luckCorner.CornerRadius = UDim.new(0, 6)
luckCorner.Parent = luckDisplay

-- Coin shop items container
local coinItemsContainer = Instance.new("ScrollingFrame")
coinItemsContainer.Name = "CoinItemsContainer"
coinItemsContainer.Size = UDim2.new(1, -40, 1, -130)
coinItemsContainer.Position = UDim2.new(0, 20, 0, 110)
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

-- Variables for shop functionality
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local coinCountUpdate = remotes:WaitForChild("CoinCountUpdate")

-- Create shop purchase remote if it doesn't exist
local shopPurchase
if remotes:FindFirstChild("ShopPurchase") then
    shopPurchase = remotes:FindFirstChild("ShopPurchase")
else
    shopPurchase = Instance.new("RemoteEvent")
    shopPurchase.Name = "ShopPurchase"
    shopPurchase.Parent = remotes
end

-- Create luck update remote if it doesn't exist
local luckUpdate
if remotes:FindFirstChild("LuckUpdate") then
    luckUpdate = remotes:FindFirstChild("LuckUpdate")
else
    luckUpdate = Instance.new("RemoteEvent")
    luckUpdate.Name = "LuckUpdate"
    luckUpdate.Parent = remotes
end

-- Current coin count
local currentCoins = 0

-- Store update functions for shop items
local robuxUpdateFunctions = {}
local coinUpdateFunctions = {}

-- Function to create shop item UI
local function createShopItem(item, container, isRobuxItem)
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "ItemFrame_" .. item.name
    itemFrame.Size = UDim2.new(1, -20, 0, 80)
    itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = container
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = itemFrame
    
    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = itemFrame
    
    -- Item description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "DescLabel"
    descLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
    descLabel.Position = UDim2.new(0, 10, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = item.description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = itemFrame
    
    -- Price label
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Size = UDim2.new(0.3, 0, 0.4, 0)
    priceLabel.Position = UDim2.new(0.7, 0, 0, 5)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = item.price .. (isRobuxItem and " Robux" or " Coins")
    priceLabel.TextColor3 = isRobuxItem and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 215, 0)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextXAlignment = Enum.TextXAlignment.Right
    priceLabel.Parent = itemFrame
    
    -- Buy button
    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(0.3, 0, 0.4, 0)
    buyButton.Position = UDim2.new(0.7, 0, 0, 35)
    buyButton.BackgroundColor3 = isRobuxItem and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(0, 150, 0)
    buyButton.BorderSizePixel = 0
    buyButton.Text = isRobuxItem and "BUY (R$)" or "BUY"
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.TextScaled = true
    buyButton.Font = Enum.Font.GothamBold
    buyButton.Parent = itemFrame
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 6)
    buyCorner.Parent = buyButton
    
    -- Update button state based on affordability and ownership
    local function updateButtonState()
        if isRobuxItem then
            -- Check if player owns permanent luck (for permanent_luck item)
            if item.itemType == "permanent_luck" and _G.playerPermanentLuckBonus and _G.playerPermanentLuckBonus >= 2 then
                buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                buyButton.Text = "OWNED"
                buyButton.Active = false
            else
                -- For other Robux items, always show as purchasable
                buyButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                buyButton.Text = "BUY (R$)"
                buyButton.Active = true
            end
        else
            -- For coin items, check if player has enough coins
            if currentCoins >= item.price then
                buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                buyButton.Text = "BUY"
            else
                buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                buyButton.Text = "NO COINS"
            end
        end
    end
    
    -- Buy button functionality
    buyButton.MouseButton1Click:Connect(function()
        if isRobuxItem then
            -- Don't allow purchase if already owned (for permanent_luck)
            if item.itemType == "permanent_luck" and _G.playerPermanentLuckBonus and _G.playerPermanentLuckBonus >= 2 then
                return
            end
            
            -- Show feedback that purchase prompt is being shown
            buyButton.Text = "OPENING..."
            buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            
            -- Fire Robux purchase request to server
            local robuxPurchase = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("RobuxPurchase")
            if robuxPurchase then
                robuxPurchase:FireServer(item.itemType)
                
                -- Reset button after a short delay
                task.delay(2, function()
                    if buyButton then
                        updateButtonState()
                    end
                end)
            end
        else
            -- Fire coin purchase request to server
            if currentCoins >= item.price then
                shopPurchase:FireServer(item.name)
            end
        end
    end)
    
    -- Return update function
    return updateButtonState
end

-- Function to populate coin shop items
local function populateCoinShopItems()
    -- Clear existing items
    for _, child in pairs(coinItemsContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("ItemFrame_") then
            child:Destroy()
        end
    end
    
    -- Clear update functions
    coinUpdateFunctions = {}
    
    -- Get shop items from server (for now, we'll use hardcoded items)
    local shopItems = {
        {
            name = "Lucky Potion (1.25x)",
            price = 50,
            description = "Increases luck by 1.25x for 5 minutes",
            itemType = "lucky_potion",
            luckMultiplier = 1.25
        },
        {
            name = "Lucky Potion (1.5x)",
            price = 75,
            description = "Increases luck by 1.5x for 5 minutes",
            itemType = "lucky_potion",
            luckMultiplier = 1.5
        },
        {
            name = "Lucky Potion (2x)",
            price = 100,
            description = "Increases luck by 2x for 5 minutes",
            itemType = "lucky_potion",
            luckMultiplier = 2
        }
    }
    
    -- Create items
    for i, item in ipairs(shopItems) do
        local updateFunc = createShopItem(item, coinItemsContainer, false)
        table.insert(coinUpdateFunctions, updateFunc)
        
        -- Position the item
        local itemFrame = coinItemsContainer:FindFirstChild("ItemFrame_" .. item.name)
        if itemFrame then
            itemFrame.Position = UDim2.new(0, 10, 0, (i - 1) * 90)
        end
    end
    
    -- Update container size
    coinItemsContainer.CanvasSize = UDim2.new(0, 0, 0, #shopItems * 90)
end

-- Function to update all shop items
local function updateAllShopItems()
    -- Update Robux shop items
    for _, updateFunc in pairs(robuxUpdateFunctions) do
        if updateFunc then
            updateFunc()
        end
    end
    
    -- Update coin shop items
    for _, updateFunc in pairs(coinUpdateFunctions) do
        if updateFunc then
            updateFunc()
        end
    end
end

-- Make updateAllShopItems globally accessible
_G.updateAllShopItems = updateAllShopItems

-- Function to populate Robux shop items
local function populateRobuxShopItems()
    -- Clear existing items
    for _, child in pairs(specialItemsContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("ItemFrame_") then
            child:Destroy()
        end
    end
    
    -- Clear update functions
    robuxUpdateFunctions = {}
    
    -- Robux shop items
    local robuxItems = {
        {
            name = "Nuke All",
            price = 100,
            description = "Instantly kill everyone including yourself with a massive explosion! (One-time use)",
            itemType = "nuke_all"
        },
        {
            name = "Permanent 2x Luck",
            price = 200,
            description = "Permanent 2x luck bonus (applies to all potions)",
            itemType = "permanent_luck"
        }
    }
    
    -- Create items
    for i, item in ipairs(robuxItems) do
        local updateFunc = createShopItem(item, specialItemsContainer, true)
        table.insert(robuxUpdateFunctions, updateFunc)
        
        -- Position the item
        local itemFrame = specialItemsContainer:FindFirstChild("ItemFrame_" .. item.name)
        if itemFrame then
            itemFrame.Position = UDim2.new(0, 10, 0, (i - 1) * 90)
        end
    end
    
    -- Update container size
    specialItemsContainer.CanvasSize = UDim2.new(0, 0, 0, #robuxItems * 90)
end

-- Function to update coin count
local function updateCoinCount(coinCount)
    currentCoins = coinCount
    -- Update all shop items
    updateAllShopItems()
end

-- Function to update luck display
local function updateLuckDisplay(luckMultiplier, timeLeft)
    if luckDisplay then
        if luckMultiplier > 1 and timeLeft > 0 then
            local minutes = math.floor(timeLeft / 60)
            local seconds = timeLeft % 60
            luckDisplay.Text = "Current Luck: " .. string.format("%.2f", luckMultiplier) .. "x (" .. minutes .. ":" .. string.format("%02d", seconds) .. ")"
            luckDisplay.BackgroundColor3 = Color3.fromRGB(100, 50, 150) -- Purple for active luck
        else
            luckDisplay.Text = "Current Luck: 1.00x"
            luckDisplay.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Gray for no luck
        end
    end
end

-- Function to update Robux data display
local function updateRobuxDataDisplay(permanentLuckBonus, hasNukeAll)
    -- Store permanent luck bonus globally for shop items to access
    _G.playerPermanentLuckBonus = permanentLuckBonus
    
    -- Update all shop items to reflect ownership status
    if _G.updateAllShopItems then
        _G.updateAllShopItems()
    end
end

-- Listen for coin count updates
coinCountUpdate.OnClientEvent:Connect(updateCoinCount)

-- Listen for luck updates
luckUpdate.OnClientEvent:Connect(updateLuckDisplay)

-- Listen for Robux data updates
local robuxDataUpdate = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("RobuxDataUpdate")
if robuxDataUpdate then
    robuxDataUpdate.OnClientEvent:Connect(updateRobuxDataDisplay)
end

-- Populate shop when switching tabs
local originalSwitchToTab = switchToTab
switchToTab = function(tabName)
    originalSwitchToTab(tabName)
    if tabName == "coin" then
        populateCoinShopItems()
    elseif tabName == "special" then
        populateRobuxShopItems()
    end
end

-- Make the script accessible to other scripts
_G.ShopUI = {
    toggleShop = toggleShop
}
