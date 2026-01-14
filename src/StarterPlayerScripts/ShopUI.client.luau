local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the shop GUI
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "ShopGUI"
shopGui.ResetOnSpawn = false
shopGui.DisplayOrder = 110 -- Same as daily rewards to overlay roll button and other UI elements
shopGui.Parent = playerGui

-- Main frame (larger size)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 640, 0, 400)
mainFrame.Position = UDim2.new(0.5, -320, 0.5, -200)
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

-- Add UIListLayout for proper tab distribution
local tabListLayout = Instance.new("UIListLayout")
tabListLayout.FillDirection = Enum.FillDirection.Horizontal
tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabListLayout.Padding = UDim.new(0, 5) -- 5 pixel spacing between tabs
tabListLayout.Parent = tabContainer

-- Gamepasses Tab (First)
local gamepassesTab = Instance.new("TextButton")
gamepassesTab.Name = "GamepassesTab"
gamepassesTab.Size = UDim2.new(0.33, -4, 0, 40) -- 1/3 width minus padding
gamepassesTab.BackgroundColor3 = Color3.fromRGB(100, 200, 255) -- Blue for gamepasses (active by default)
gamepassesTab.BorderSizePixel = 0
gamepassesTab.Text = "GAMEPASSES"
gamepassesTab.TextColor3 = Color3.fromRGB(255, 255, 255)
gamepassesTab.TextScaled = true
gamepassesTab.Font = Enum.Font.GothamBold
gamepassesTab.LayoutOrder = 1
gamepassesTab.Parent = tabContainer

local gamepassesTabCorner = Instance.new("UICorner")
gamepassesTabCorner.CornerRadius = UDim.new(0, 8)
gamepassesTabCorner.Parent = gamepassesTab

-- Special Shop Tab (Second)
local specialTab = Instance.new("TextButton")
specialTab.Name = "SpecialTab"
specialTab.Size = UDim2.new(0.33, -4, 0, 40) -- 1/3 width minus padding
specialTab.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray for Robux
specialTab.BorderSizePixel = 0
specialTab.Text = "SPECIAL SHOP"
specialTab.TextColor3 = Color3.fromRGB(255, 255, 255)
specialTab.TextScaled = true
specialTab.Font = Enum.Font.GothamBold
specialTab.LayoutOrder = 2
specialTab.Parent = tabContainer

local specialTabCorner = Instance.new("UICorner")
specialTabCorner.CornerRadius = UDim.new(0, 8)
specialTabCorner.Parent = specialTab

-- Coin Shop Tab (Third)
local coinTab = Instance.new("TextButton")
coinTab.Name = "CoinTab"
coinTab.Size = UDim2.new(0.33, -4, 0, 40) -- 1/3 width minus padding
coinTab.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray for coin shop
coinTab.BorderSizePixel = 0
coinTab.Text = "COIN SHOP"
coinTab.TextColor3 = Color3.fromRGB(255, 255, 255)
coinTab.TextScaled = true
coinTab.Font = Enum.Font.GothamBold
coinTab.LayoutOrder = 3
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

-- Gamepasses Content (First)
local gamepassesContent = Instance.new("Frame")
gamepassesContent.Name = "GamepassesContent"
gamepassesContent.Size = UDim2.new(1, 0, 1, 0)
gamepassesContent.BackgroundTransparency = 1
gamepassesContent.Parent = contentFrame

-- Gamepasses items container
local gamepassesItemsContainer = Instance.new("ScrollingFrame")
gamepassesItemsContainer.Name = "GamepassesItemsContainer"
gamepassesItemsContainer.Size = UDim2.new(1, -40, 1, -40)
gamepassesItemsContainer.Position = UDim2.new(0, 20, 0, 20)
gamepassesItemsContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
gamepassesItemsContainer.BorderSizePixel = 0
gamepassesItemsContainer.ScrollBarThickness = 6
gamepassesItemsContainer.Parent = gamepassesContent

local gamepassesItemsCorner = Instance.new("UICorner")
gamepassesItemsCorner.CornerRadius = UDim.new(0, 6)
gamepassesItemsCorner.Parent = gamepassesItemsContainer

-- Gamepasses grid layout
local gamepassesGridLayout = Instance.new("UIGridLayout")
gamepassesGridLayout.CellSize = UDim2.new(0, 150, 0, 200)
gamepassesGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gamepassesGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gamepassesGridLayout.Parent = gamepassesItemsContainer

-- Coin Shop Content
local coinContent = Instance.new("Frame")
coinContent.Name = "CoinContent"
coinContent.Size = UDim2.new(1, 0, 1, 0)
coinContent.BackgroundTransparency = 1
coinContent.Visible = false
coinContent.Parent = contentFrame

-- Coin shop items container
local coinItemsContainer = Instance.new("ScrollingFrame")
coinItemsContainer.Name = "CoinItemsContainer"
coinItemsContainer.Size = UDim2.new(1, -40, 1, -40)
coinItemsContainer.Position = UDim2.new(0, 20, 0, 20)
coinItemsContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
coinItemsContainer.BorderSizePixel = 0
coinItemsContainer.ScrollBarThickness = 6
coinItemsContainer.Parent = coinContent

local coinItemsCorner = Instance.new("UICorner")
coinItemsCorner.CornerRadius = UDim.new(0, 6)
coinItemsCorner.Parent = coinItemsContainer

-- Coin shop grid layout
local coinGridLayout = Instance.new("UIGridLayout")
coinGridLayout.CellSize = UDim2.new(0, 150, 0, 200)
coinGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
coinGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
coinGridLayout.Parent = coinItemsContainer

-- Special Shop Content (Second)
local specialContent = Instance.new("Frame")
specialContent.Name = "SpecialContent"
specialContent.Size = UDim2.new(1, 0, 1, 0)
specialContent.BackgroundTransparency = 1
specialContent.Visible = false
specialContent.Parent = contentFrame

-- Special shop items container
local specialItemsContainer = Instance.new("ScrollingFrame")
specialItemsContainer.Name = "SpecialItemsContainer"
specialItemsContainer.Size = UDim2.new(1, -40, 1, -40)
specialItemsContainer.Position = UDim2.new(0, 20, 0, 20)
specialItemsContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
specialItemsContainer.BorderSizePixel = 0
specialItemsContainer.ScrollBarThickness = 6
specialItemsContainer.Parent = specialContent

local specialItemsCorner = Instance.new("UICorner")
specialItemsCorner.CornerRadius = UDim.new(0, 6)
specialItemsCorner.Parent = specialItemsContainer

-- Special shop grid layout
local specialGridLayout = Instance.new("UIGridLayout")
specialGridLayout.CellSize = UDim2.new(0, 150, 0, 200)
specialGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
specialGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
specialGridLayout.Parent = specialItemsContainer

-- Initially hide the GUI
shopGui.Enabled = false

-- Store update functions for shop items
local robuxUpdateFunctions = {}
local coinUpdateFunctions = {}
local gamepassesUpdateFunctions = {}

-- Current coin count
local currentCoins = 0
-- Store globally so buy buttons can access it
_G.currentCoins = 0

-- Item info popup (created once, reused)
local itemInfoPopup = nil
local function createItemInfoPopup()
    if itemInfoPopup then
        return itemInfoPopup
    end
    
    local TweenService = game:GetService("TweenService")
    
    -- Create popup background overlay (TextButton so it can receive clicks)
    local overlay = Instance.new("TextButton")
    overlay.Name = "ItemInfoOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Text = ""
    overlay.AutoButtonColor = false
    overlay.ZIndex = 50
    overlay.Visible = false
    overlay.Parent = shopGui
    
    -- Create popup frame
    local popup = Instance.new("Frame")
    popup.Name = "ItemInfoPopup"
    popup.Size = UDim2.new(0, 400, 0, 300)
    popup.Position = UDim2.new(0.5, 0, 0.5, 0)
    popup.AnchorPoint = Vector2.new(0.5, 0.5)
    popup.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    popup.BorderSizePixel = 0
    popup.ZIndex = 51
    popup.Visible = false
    popup.Parent = shopGui
    
    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, 12)
    popupCorner.Parent = popup
    
    -- Header
    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    header.BorderSizePixel = 0
    header.Text = "Item Information"
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextSize = 22
    header.Font = Enum.Font.GothamBold
    header.TextXAlignment = Enum.TextXAlignment.Center
    header.TextYAlignment = Enum.TextYAlignment.Center
    header.ZIndex = 52
    header.Parent = popup
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.ZIndex = 52
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -40, 0, 40)
    nameLabel.Position = UDim2.new(0, 20, 0, 60)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Item Name"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 24
    nameLabel.TextWrapped = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.ZIndex = 52
    nameLabel.Parent = popup
    
    -- Price label
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Size = UDim2.new(1, -40, 0, 30)
    priceLabel.Position = UDim2.new(0, 20, 0, 100)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "Price: 100 Coins"
    priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    priceLabel.TextSize = 20
    priceLabel.TextWrapped = true
    priceLabel.Font = Enum.Font.Gotham
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.TextYAlignment = Enum.TextYAlignment.Center
    priceLabel.ZIndex = 52
    priceLabel.Parent = popup
    
    -- Description label (scrollable)
    local descriptionFrame = Instance.new("Frame")
    descriptionFrame.Name = "DescriptionFrame"
    descriptionFrame.Size = UDim2.new(1, -40, 1, -150)
    descriptionFrame.Position = UDim2.new(0, 20, 0, 140)
    descriptionFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    descriptionFrame.BorderSizePixel = 0
    descriptionFrame.ZIndex = 52
    descriptionFrame.Parent = popup
    
    local descCorner = Instance.new("UICorner")
    descCorner.CornerRadius = UDim.new(0, 8)
    descCorner.Parent = descriptionFrame
    
    local descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Name = "DescriptionLabel"
    descriptionLabel.Size = UDim2.new(1, -20, 1, -20)
    descriptionLabel.Position = UDim2.new(0, 10, 0, 10)
    descriptionLabel.BackgroundTransparency = 1
    descriptionLabel.Text = "Item description goes here..."
    descriptionLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    descriptionLabel.TextSize = 20
    descriptionLabel.TextWrapped = true
    descriptionLabel.Font = Enum.Font.Gotham
    descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
    descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
    descriptionLabel.ZIndex = 53
    descriptionLabel.Parent = descriptionFrame
    
    -- Close button functionality
    local function closePopup()
        overlay.Visible = false
        popup.Visible = false
    end
    
    closeButton.MouseButton1Click:Connect(closePopup)
    overlay.MouseButton1Click:Connect(closePopup)
    
    itemInfoPopup = {
        overlay = overlay,
        popup = popup,
        nameLabel = nameLabel,
        priceLabel = priceLabel,
        descriptionLabel = descriptionLabel,
        close = closePopup
    }
    
    return itemInfoPopup
end

-- Function to show item info popup
local function showItemInfoPopup(itemName, description, price, isRobuxItem)
    local popup = createItemInfoPopup()
    
    -- Update popup content
    popup.nameLabel.Text = itemName
    popup.priceLabel.Text = "Price: " .. price .. (isRobuxItem and " Robux" or " Coins")
    popup.priceLabel.TextColor3 = isRobuxItem and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 215, 0)
    popup.descriptionLabel.Text = description
    
    -- Show popup with animation
    popup.overlay.Visible = true
    popup.popup.Visible = true
    
    -- Make sure text is visible
    popup.nameLabel.Visible = true
    popup.priceLabel.Visible = true
    popup.descriptionLabel.Visible = true
    
    local TweenService = game:GetService("TweenService")
    popup.popup.Position = UDim2.new(0.5, 0, 0.4, -50)
    popup.popup.BackgroundTransparency = 1
    
    local slideIn = TweenService:Create(
        popup.popup,
        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0}
    )
    slideIn:Play()
end

-- Function to create shop item UI
local function createShopItem(item, container, isRobuxItem)
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "ItemFrame_" .. item.name
    itemFrame.Size = UDim2.new(0, 150, 0, 200) -- Fixed size for grid
    itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = container
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = itemFrame
    
    -- Image placeholder
    local imagePlaceholder = Instance.new("Frame")
    imagePlaceholder.Name = "ImagePlaceholder"
    imagePlaceholder.Size = UDim2.new(1, -10, 0, 100)
    imagePlaceholder.Position = UDim2.new(0, 5, 0, 5)
    imagePlaceholder.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    imagePlaceholder.BorderSizePixel = 0
    imagePlaceholder.Parent = itemFrame
    
    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, 6)
    imageCorner.Parent = imagePlaceholder
    
    -- Info icon button (top-right corner of item frame)
    local infoButton = Instance.new("TextButton")
    infoButton.Name = "InfoButton"
    infoButton.Size = UDim2.new(0, 24, 0, 24)
    infoButton.Position = UDim2.new(1, -30, 0, 5)
    infoButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    infoButton.BorderSizePixel = 0
    infoButton.Text = "i"
    infoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoButton.TextScaled = true
    infoButton.Font = Enum.Font.GothamBold
    infoButton.ZIndex = 10
    infoButton.Parent = itemFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 12)
    infoCorner.Parent = infoButton
    
    -- Hover effects for info button
    infoButton.MouseEnter:Connect(function()
        infoButton.BackgroundColor3 = Color3.fromRGB(120, 170, 255)
    end)
    infoButton.MouseLeave:Connect(function()
        infoButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    end)
    
    -- Item image or viewport (for marbles)
    local itemImage = nil
    local viewport = nil
    
    -- For marbles, use ViewportFrame like inventory
    if item.itemType == "gold_marble" or item.itemType == "diamond_marble" or item.itemType == "coin_marble" 
       or item.itemType == "meteor_marble" or item.itemType == "tsunami_marble" or item.itemType == "glass_marble" then
        viewport = Instance.new("ViewportFrame")
        viewport.Name = "MarbleViewport"
        viewport.Size = UDim2.new(1, 0, 1, 0)
        viewport.Position = UDim2.new(0, 0, 0, 0)
        viewport.BackgroundTransparency = 1
        viewport.BorderSizePixel = 0
        viewport.Parent = imagePlaceholder
        
        local world = Instance.new("WorldModel")
        world.Parent = viewport
        
        local sphere = Instance.new("Part")
        sphere.Shape = Enum.PartType.Ball
        sphere.Size = Vector3.new(6, 6, 6)
        sphere.Anchored = true
        sphere.CanCollide = false
        sphere.Parent = world
        
        -- Apply textures to the sphere
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))
        local marbleId = item.marbleId or (item.itemType == "gold_marble" and "Gold" or (item.itemType == "diamond_marble" and "Diamond" or (item.itemType == "coin_marble" and "Coin" or nil)))
        local def = Marbles.getById(marbleId)
        
        -- Apply textures using the same logic as inventory
        local texturesRoot = ReplicatedStorage:FindFirstChild("MarbleTextures")
        local folder = texturesRoot and texturesRoot:FindFirstChild(marbleId)
        local assets = {}
        
        if folder then
            for _, inst in ipairs(folder:GetChildren()) do
                if inst:IsA("Decal") or inst:IsA("Texture") then
                    table.insert(assets, inst)
                end
            end
        end
        
        local FALLBACK_DECALS = {
            Gold = "rbxassetid://84142305330257",
            Diamond = "rbxassetid://95881293008595",
            Coin = "rbxassetid://98528749229098", -- Coin marble texture
            Meteor = "rbxassetid://135554382256334", -- Meteor marble texture
            Tsunami = "rbxassetid://109162306563849", -- Tsunami marble texture
            Glass = "rbxassetid://101699002274981", -- Glass marble texture
            Castle = "rbxassetid://136095563046974", -- Castle marble texture
            Phoenix = "rbxassetid://124481451788068", -- Phoenix marble texture
        }
        
        if #assets == 0 then
            local fallback = FALLBACK_DECALS[marbleId]
            if fallback then
                for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
                    local d = Instance.new("Decal")
                    d.Texture = fallback
                    d.Face = face
                    d.Parent = sphere
                end
            end
        elseif #assets == 1 then
            local src = assets[1]
            for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
                local clone = src:Clone()
                if clone:IsA("Decal") then
                    clone.Face = face
                elseif clone:IsA("Texture") then
                    clone.Face = face
                end
                clone.Parent = sphere
            end
        else
            for _, src in ipairs(assets) do
                local clone = src:Clone()
                clone.Parent = sphere
            end
        end
        
        -- Set color if no textures applied
        if #sphere:GetChildren() == 0 and def and def.color then
            sphere.Color = def.color
        end
        
        -- Camera setup
        local cam = Instance.new("Camera")
        local center = Vector3.new(0, 0, 0)
        sphere.Position = center
        cam.CFrame = CFrame.new(center + Vector3.new(0, 0, 12), center)
        cam.Parent = world
        viewport.CurrentCamera = cam
        
        -- Rotate the sphere slowly for visual effect
        task.spawn(function()
            while viewport and viewport.Parent do
                sphere.CFrame = sphere.CFrame * CFrame.Angles(0, math.rad(1), 0)
                task.wait(0.05)
            end
        end)
    else
        -- For other items, use ImageLabel
        itemImage = Instance.new("ImageLabel")
        itemImage.Name = "ItemImage"
        itemImage.Size = UDim2.new(1, 0, 1, 0)
        itemImage.Position = UDim2.new(0, 0, 0, 0)
        itemImage.BackgroundTransparency = 1
        itemImage.ScaleType = Enum.ScaleType.Fit
        itemImage.Parent = imagePlaceholder
        
        -- Set specific images based on item type
        if item.itemType == "nuke_all" then
            itemImage.Image = "rbxassetid://115934412352825"
        elseif item.itemType == "permanent_luck" then
            itemImage.Image = "rbxassetid://122460327748810"
        elseif item.itemType == "lucky_potion" then
            -- Set image based on luck multiplier
            if item.luckMultiplier == 1.25 then
                itemImage.Image = "rbxassetid://81477674576659"
            elseif item.luckMultiplier == 1.5 then
                itemImage.Image = "rbxassetid://104597457196107"
            elseif item.luckMultiplier == 2 then
                itemImage.Image = "rbxassetid://89877824960542"
            else
                -- Default placeholder for unknown luck multipliers
                local placeholderText = Instance.new("TextLabel")
                placeholderText.Name = "PlaceholderText"
                placeholderText.Size = UDim2.new(1, 0, 1, 0)
                placeholderText.Position = UDim2.new(0, 0, 0, 0)
                placeholderText.BackgroundTransparency = 1
                placeholderText.Text = "IMAGE"
                placeholderText.TextColor3 = Color3.fromRGB(150, 150, 150)
                placeholderText.TextScaled = true
                placeholderText.Font = Enum.Font.Gotham
                placeholderText.Parent = imagePlaceholder
            end
        else
        -- Default placeholder for other items
        local placeholderText = Instance.new("TextLabel")
        placeholderText.Name = "PlaceholderText"
        placeholderText.Size = UDim2.new(1, 0, 1, 0)
        placeholderText.Position = UDim2.new(0, 0, 0, 0)
        placeholderText.BackgroundTransparency = 1
        placeholderText.Text = "IMAGE"
        placeholderText.TextColor3 = Color3.fromRGB(150, 150, 150)
        placeholderText.TextScaled = true
        placeholderText.Font = Enum.Font.Gotham
        placeholderText.Parent = imagePlaceholder
    end
    end
    
    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -10, 0, 30)
    nameLabel.Position = UDim2.new(0, 5, 0, 110)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = itemFrame
    
    -- Price label container (fixed height for alignment)
    local priceContainer = Instance.new("Frame")
    priceContainer.Name = "PriceContainer"
    local isOnSale = item.originalPrice and item.originalPrice > item.price
    priceContainer.Size = UDim2.new(1, -10, 0, 25)
    priceContainer.Position = UDim2.new(0, 5, 0, 145)
    priceContainer.BackgroundTransparency = 1
    priceContainer.Parent = itemFrame
    
    -- Check if item has originalPrice (on sale)
    if isOnSale then
        -- Calculate discount percentage
        local discountPercent = math.floor(((item.originalPrice - item.price) / item.originalPrice) * 100)
        
        -- "BEST VALUE" badge positioned to the left of info icon (top-right corner)
        local badgeFrame = Instance.new("Frame")
        badgeFrame.Name = "BestValueBadge"
        badgeFrame.Size = UDim2.new(0, 0, 0, 18)
        badgeFrame.Position = UDim2.new(0, 5, 0, 5) -- Start at left edge, will be adjusted
        badgeFrame.AnchorPoint = Vector2.new(0, 0) -- Anchor to top-left
        badgeFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
        badgeFrame.BorderSizePixel = 0
        badgeFrame.ZIndex = 10
        badgeFrame.Parent = itemFrame -- Parent to itemFrame, not priceContainer
        
        -- Don't clip the entire itemFrame to avoid cutting off the button
        -- The badge positioning logic already ensures it stays within bounds
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 3)
        badgeCorner.Parent = badgeFrame
        
        local badgeLabel = Instance.new("TextLabel")
        badgeLabel.Name = "BadgeLabel"
        badgeLabel.Size = UDim2.new(1, -6, 1, -4)
        badgeLabel.Position = UDim2.new(0, 3, 0, 2)
        badgeLabel.BackgroundTransparency = 1
        badgeLabel.Text = discountPercent .. "% OFF"
        badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0) -- Black text
        badgeLabel.TextSize = 10
        badgeLabel.Font = Enum.Font.GothamBold
        badgeLabel.TextXAlignment = Enum.TextXAlignment.Center
        badgeLabel.ZIndex = 11
        badgeLabel.Parent = badgeFrame
        
        -- Update badge width and position based on text
        task.spawn(function()
            wait(0.1) -- Wait for itemFrame to be fully sized
            local badgeWidth = badgeLabel.TextBounds.X + 6
            badgeFrame.Size = UDim2.new(0, badgeWidth, 0, 18)
            
            -- Info icon is at (1, -30) with size 24, so it starts at width - 54
            -- Position badge to end 5 pixels before info icon starts
            -- Use UDim2 to position from right edge: 1 (right) - (54 + 5 + badgeWidth) / itemFrameWidth
            local itemFrameWidth = itemFrame.AbsoluteSize.X
            if itemFrameWidth > 0 then
                local infoIconStart = itemFrameWidth - 54
                local badgeEndX = infoIconStart - 5
                local badgeStartX = badgeEndX - badgeWidth
                
                -- Ensure badge doesn't go beyond left edge (minimum 5px from left)
                if badgeStartX < 5 then
                    badgeStartX = 5
                    -- Adjust width if needed to not overlap with info icon
                    if badgeStartX + badgeWidth > infoIconStart - 5 then
                        badgeWidth = math.max(50, infoIconStart - 5 - badgeStartX)
                        badgeFrame.Size = UDim2.new(0, badgeWidth, 0, 18)
                    end
                end
                
                badgeFrame.Position = UDim2.new(0, badgeStartX, 0, 5)
            end
        end)
        
        -- Also update when itemFrame size changes
        itemFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local badgeWidth = badgeLabel.TextBounds.X + 6
            badgeFrame.Size = UDim2.new(0, badgeWidth, 0, 18)
            
            local itemFrameWidth = itemFrame.AbsoluteSize.X
            if itemFrameWidth > 0 then
                local infoIconStart = itemFrameWidth - 54
                local badgeEndX = infoIconStart - 5
                local badgeStartX = badgeEndX - badgeWidth
                
                if badgeStartX < 5 then
                    badgeStartX = 5
                    if badgeStartX + badgeWidth > infoIconStart - 5 then
                        badgeWidth = math.max(50, infoIconStart - 5 - badgeStartX)
                        badgeFrame.Size = UDim2.new(0, badgeWidth, 0, 18)
                    end
                end
                
                badgeFrame.Position = UDim2.new(0, badgeStartX, 0, 5)
            end
        end)
        
        -- Sale price (prominent, center)
        local salePriceLabel = Instance.new("TextLabel")
        salePriceLabel.Name = "SalePriceLabel"
        salePriceLabel.Size = UDim2.new(1, 0, 1, 0)
        salePriceLabel.Position = UDim2.new(0, 0, 0, 0)
        salePriceLabel.BackgroundTransparency = 1
        salePriceLabel.Text = item.price .. (isRobuxItem and " Robux" or " Coins")
        salePriceLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Bright green for sale
        salePriceLabel.TextSize = 18
        salePriceLabel.Font = Enum.Font.GothamBold
        salePriceLabel.TextXAlignment = Enum.TextXAlignment.Center
        salePriceLabel.Parent = priceContainer
    else
        -- Normal price display (matching sale price style)
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Name = "PriceLabel"
        priceLabel.Size = UDim2.new(1, 0, 1, 0)
        priceLabel.Position = UDim2.new(0, 0, 0, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = item.price .. (isRobuxItem and " Robux" or " Coins")
        priceLabel.TextColor3 = isRobuxItem and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0)
        priceLabel.TextSize = 18
        priceLabel.Font = Enum.Font.GothamBold
        priceLabel.TextXAlignment = Enum.TextXAlignment.Center
        priceLabel.Parent = priceContainer
    end
    
    -- Buy button (always at same position for alignment)
    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(1, -10, 0, 30)
    buyButton.Position = UDim2.new(0, 5, 0, 170) -- Moved up 5px to fit within 200px frame
    buyButton.BackgroundColor3 = isRobuxItem and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(0, 150, 0)
    buyButton.BorderSizePixel = 0
    buyButton.Text = isRobuxItem and "BUY (R$)" or "BUY"
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.TextSize = 16
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
            -- Check if player owns Gold Marble
            elseif item.itemType == "gold_marble" and _G.ownedMarbles and _G.ownedMarbles["Gold"] then
                buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                buyButton.Text = "OWNED"
                buyButton.Active = false
            -- Check if player owns Diamond Marble
            elseif item.itemType == "diamond_marble" and _G.ownedMarbles and _G.ownedMarbles["Diamond"] then
                buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                buyButton.Text = "OWNED"
                buyButton.Active = false
            -- Check if player owns Coin Marble
            elseif item.itemType == "coin_marble" and _G.ownedMarbles and _G.ownedMarbles["Coin"] then
                buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                buyButton.Text = "OWNED"
                buyButton.Active = false
            else
                -- For other Robux items, always show as purchasable
                buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                buyButton.Text = "BUY (R$)"
                buyButton.Active = true
            end
        else
            -- For coin items, check if player has enough coins
            local currentCoinCount = _G.currentCoins or currentCoins
            if currentCoinCount >= item.price then
                buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                buyButton.Text = "BUY"
                buyButton.Active = true
            else
                buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                buyButton.Text = "NOT ENOUGH"
                buyButton.Active = false
            end
        end
    end
    
    -- Buy button functionality
    buyButton.MouseButton1Click:Connect(function()
        print("[ShopUI] Buy button clicked for item:", item.name, "Type:", item.itemType, "IsRobux:", isRobuxItem)
        print("[ShopUI] Current coins at purchase time:", currentCoins)
        print("[ShopUI] Button Active:", buyButton.Active)
        
        if isRobuxItem then
            -- Don't allow purchase if already owned (for permanent_luck)
            if item.itemType == "permanent_luck" and _G.playerPermanentLuckBonus and _G.playerPermanentLuckBonus >= 2 then
                print("[ShopUI] Item already owned, purchase blocked")
                return
            end
            -- Don't allow purchase if already owned (for Gold Marble)
            if item.itemType == "gold_marble" then
                print("[ShopUI] Checking Gold Marble ownership. _G.ownedMarbles:", _G.ownedMarbles)
                if _G.ownedMarbles and _G.ownedMarbles["Gold"] then
                    print("[ShopUI] Gold Marble already owned, purchase blocked")
                    return
                end
            end
            -- Don't allow purchase if already owned (for Diamond Marble)
            if item.itemType == "diamond_marble" then
                print("[ShopUI] Checking Diamond Marble ownership. _G.ownedMarbles:", _G.ownedMarbles)
                if _G.ownedMarbles and _G.ownedMarbles["Diamond"] then
                    print("[ShopUI] Diamond Marble already owned, purchase blocked")
                    return
                end
            end
            -- Don't allow purchase if already owned (for Coin Marble)
            if item.itemType == "coin_marble" then
                print("[ShopUI] Checking Coin Marble ownership. _G.ownedMarbles:", _G.ownedMarbles)
                if _G.ownedMarbles and _G.ownedMarbles["Coin"] then
                    print("[ShopUI] Coin Marble already owned, purchase blocked")
                    return
                end
            end
            
            -- For Robux items, trigger the purchase
            print("[ShopUI] Attempting Robux purchase for:", item.itemType)
            local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
            if remotesFolder then
                local robuxPurchase = remotesFolder:FindFirstChild("RobuxPurchase")
                if robuxPurchase then
                    print("[ShopUI] Firing RobuxPurchase remote event for:", item.itemType)
                    robuxPurchase:FireServer(item.itemType)
                    print("[ShopUI] RobuxPurchase remote event fired successfully")
                else
                    warn("[ShopUI] RobuxPurchase remote event not found in Remotes folder")
                end
            else
                warn("[ShopUI] Remotes folder not found")
            end
        else
            -- For coin items, check if already owned (for marbles)
            if item.itemType == "meteor_marble" then
                if _G.ownedMarbles and _G.ownedMarbles["Meteor"] then
                    print("[ShopUI] Meteor Marble already owned, purchase blocked")
                    return
                end
            elseif item.itemType == "tsunami_marble" then
                if _G.ownedMarbles and _G.ownedMarbles["Tsunami"] then
                    print("[ShopUI] Tsunami Marble already owned, purchase blocked")
                    return
                end
            elseif item.itemType == "glass_marble" then
                if _G.ownedMarbles and _G.ownedMarbles["Glass"] then
                    print("[ShopUI] Glass Marble already owned, purchase blocked")
                    return
                end
            end
            -- For coin items, check if player has enough coins
            -- Use the global currentCoins variable, not the captured one
            local currentCoinCount = _G.currentCoins or currentCoins
            print("Coin purchase attempt. Current coins:", currentCoinCount, "Required:", item.price)
            if currentCoinCount >= item.price then
                -- Trigger coin purchase
                local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
                if remotesFolder then
                    local shopPurchase = remotesFolder:FindFirstChild("ShopPurchase")
                    if shopPurchase then
                        print("Firing ShopPurchase remote event for:", item.name)
                        shopPurchase:FireServer(item.name)
                    else
                        print("ShopPurchase remote event not found")
                    end
                else
                    print("Remotes folder not found")
                end
            else
                print("Not enough coins for purchase")
            end
        end
    end)
    
    -- Initial button state update
    updateButtonState()
    
    -- Info button functionality - show item description popup
    infoButton.MouseButton1Click:Connect(function()
        showItemInfoPopup(item.name, item.description or "No description available.", item.price, isRobuxItem)
    end)
    
    -- Return update function
    return updateButtonState
end

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
            name = "Coin Marble",
            price = 350, -- Sale price
            originalPrice = 1000, -- Original price
            description = "Unlock the Coin Marble - Drops coins behind you as you move while active",
            itemType = "coin_marble"
        },
        {
            name = "Gold Marble",
            price = 300,
            description = "Unlock the Gold Marble - Multiplies all coins collected by 5x while active",
            itemType = "gold_marble"
        },
        {
            name = "Diamond Marble",
            price = 500,
            description = "Unlock the Diamond Marble - Multiplies all coins collected by 10x while active",
            itemType = "diamond_marble"
        }
    }
    
    -- Create items
    for i, item in ipairs(robuxItems) do
        local updateFunc = createShopItem(item, specialItemsContainer, true)
        table.insert(robuxUpdateFunctions, updateFunc)
    end
    
    -- Update container size based on grid layout
    local function updateCanvasSize()
        local gridSize = specialGridLayout.AbsoluteContentSize
        specialItemsContainer.CanvasSize = UDim2.new(0, 0, 0, gridSize.Y + 20)
    end
    
    -- Connect to grid layout changes
    specialGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
    updateCanvasSize()
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
    -- Marbles first, then potions
    local shopItems = {
        {
            name = "Meteor Marble",
            price = 100,
            description = "Unlock the Meteor Marble - Teleport high into the sky as meteors rain down around you",
            itemType = "meteor_marble",
            marbleId = "Meteor"
        },
        {
            name = "Tsunami Marble",
            price = 200,
            description = "Unlock the Tsunami Marble - Summon a massive wave from below that launches you skyward",
            itemType = "tsunami_marble",
            marbleId = "Tsunami"
        },
        {
            name = "Glass Marble",
            price = 300,
            description = "Unlock the Glass Marble - Leaves behind a glass trail while moving that makes marbles slip",
            itemType = "glass_marble",
            marbleId = "Glass"
        },
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
    end
    
    -- Update container size based on grid layout
    local function updateCanvasSize()
        local gridSize = coinGridLayout.AbsoluteContentSize
        coinItemsContainer.CanvasSize = UDim2.new(0, 0, 0, gridSize.Y + 20)
    end
    
    -- Connect to grid layout changes
    coinGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
    updateCanvasSize()
end

-- Function to populate gamepasses items
local function populateGamepassesItems()
    -- Clear existing items
    for _, child in pairs(gamepassesItemsContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("ItemFrame_") then
            child:Destroy()
        end
    end
    
    -- Clear update functions
    gamepassesUpdateFunctions = {}
    
    -- Gamepasses items
    local gamepassesItems = {
        {
            name = "Permanent 2x Luck",
            price = 200, -- Sale price
            originalPrice = 500, -- Original price
            description = "Permanent 2x luck bonus (applies to all potions)",
            itemType = "permanent_luck"
        }
    }
    
    -- Create items
    for i, item in ipairs(gamepassesItems) do
        local updateFunc = createShopItem(item, gamepassesItemsContainer, true) -- Use Robux styling for gamepasses
        table.insert(gamepassesUpdateFunctions, updateFunc)
    end
    
    -- Update container size based on grid layout
    local function updateCanvasSize()
        local gridSize = gamepassesGridLayout.AbsoluteContentSize
        gamepassesItemsContainer.CanvasSize = UDim2.new(0, 0, 0, gridSize.Y + 20)
    end
    
    -- Connect to grid layout changes
    gamepassesGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
    updateCanvasSize()
end

-- Function to switch tabs
local function switchToTab(tabName)
    -- Hide all content
    gamepassesContent.Visible = false
    specialContent.Visible = false
    coinContent.Visible = false
    
    -- Reset all tab colors
    gamepassesTab.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    specialTab.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    coinTab.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    if tabName == "gamepasses" then
        gamepassesContent.Visible = true
        gamepassesTab.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    elseif tabName == "special" then
        specialContent.Visible = true
        specialTab.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    elseif tabName == "coin" then
        coinContent.Visible = true
        coinTab.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    end
end

-- Function to show/hide shop
local function toggleShop(show)
    shopGui.Enabled = show
    if show then
        print("Shop opened. Current coins:", currentCoins)
        -- Request current coin count from server
        local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
        if remotesFolder then
            local requestCoins = remotesFolder:FindFirstChild("RequestCoins")
            if requestCoins then
                print("Requesting current coin count from server")
                requestCoins:FireServer()
            else
                print("RequestCoins remote event not found, using current value")
            end
            
            -- Request Robux data to ensure ownership status is up-to-date
            local requestRobuxData = remotesFolder:FindFirstChild("RequestRobuxData")
            if requestRobuxData then
                print("Requesting Robux data from server for ownership check")
                requestRobuxData:FireServer()
            end
        end
        -- When opening the shop, populate the default tab (gamepasses)
        populateGamepassesItems()
        -- Make sure gamepasses tab is active
        switchToTab("gamepasses")
    end
end

-- Tab button functionality
specialTab.MouseButton1Click:Connect(function()
    switchToTab("special")
end)

coinTab.MouseButton1Click:Connect(function()
    switchToTab("coin")
end)

gamepassesTab.MouseButton1Click:Connect(function()
    switchToTab("gamepasses")
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
    
    -- Update gamepasses items
    for _, updateFunc in pairs(gamepassesUpdateFunctions) do
        if updateFunc then
            updateFunc()
        end
    end
end

-- Make updateAllShopItems globally accessible
_G.updateAllShopItems = updateAllShopItems


-- Function to update coin count
local function updateCoinCount(coinCount)
    print("Coin count updated:", coinCount)
    currentCoins = coinCount
    -- Store globally so buy buttons can access it
    _G.currentCoins = coinCount
    -- Update all shop items
    updateAllShopItems()
    
    -- If shop is open, refresh the currently visible tab
    if shopGui.Enabled then
        print("Shop is open, refreshing current tab with new coin count")
        if gamepassesContent.Visible then
            populateGamepassesItems()
        elseif specialContent.Visible then
            populateRobuxShopItems()
        elseif coinContent.Visible then
            populateCoinShopItems()
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

-- Listen for Robux data updates (use WaitForChild to ensure we don't miss initial data)
local robuxDataUpdate = remotes:WaitForChild("RobuxDataUpdate", 10)
if robuxDataUpdate then
    robuxDataUpdate.OnClientEvent:Connect(function(permanentLuckBonus, hasNukeAll)
        updateRobuxDataDisplay(permanentLuckBonus, hasNukeAll)
        
        -- Refresh the gamepasses tab if shop is open and gamepasses is visible
        if shopGui.Enabled and gamepassesContent.Visible then
            populateGamepassesItems()
        end
    end)
end

-- Request Robux data on script load to ensure we have the latest ownership info
task.spawn(function()
    local requestRobuxData = remotes:FindFirstChild("RequestRobuxData")
    if requestRobuxData then
        requestRobuxData:FireServer()
    end
end)

-- Populate shop when switching tabs
local originalSwitchToTab = switchToTab
switchToTab = function(tabName)
    originalSwitchToTab(tabName)
    if tabName == "gamepasses" then
        populateGamepassesItems()
    elseif tabName == "special" then
        populateRobuxShopItems()
    elseif tabName == "coin" then
        populateCoinShopItems()
    end
end

-- Make the script accessible to other scripts
_G.ShopUI = {
    toggleShop = toggleShop
}
