-- Coin HUD: shows coin count at top-right

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local CoinCountUpdate: RemoteEvent = remotes:WaitForChild("CoinCountUpdate")
local LuckUpdate: RemoteEvent = remotes:WaitForChild("LuckUpdate")

local screen = Instance.new("ScreenGui")
screen.Name = "CoinHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = playerGui

-- Coin label
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 0.2
label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
label.TextColor3 = Color3.new(1,1,1)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.Size = UDim2.fromOffset(70, 40)
label.Position = UDim2.new(1, -20, 0, 5) -- Moved higher to avoid FREE MARBLE button
label.AnchorPoint = Vector2.new(1, 0)
label.Text = "$ 0"
label.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

-- Quick Buy Icons Container (below coins, vertical layout)
local quickBuyContainer = Instance.new("Frame")
quickBuyContainer.Name = "QuickBuyContainer"
quickBuyContainer.BackgroundTransparency = 1
quickBuyContainer.Size = UDim2.fromOffset(70, 200) -- Increased height for new button
quickBuyContainer.Position = UDim2.new(1, -20, 0, 45) -- Moved up to avoid jump button
quickBuyContainer.AnchorPoint = Vector2.new(1, 0)
quickBuyContainer.Parent = screen

local quickBuyLayout = Instance.new("UIListLayout")
quickBuyLayout.FillDirection = Enum.FillDirection.Vertical
quickBuyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
quickBuyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
quickBuyLayout.Padding = UDim.new(0, 12) -- Increased spacing between buttons
quickBuyLayout.Parent = quickBuyContainer

-- Free Mythical Marble Button (above luck button)
local freeMarbleButton = Instance.new("ImageButton")
freeMarbleButton.Name = "FreeMythicalMarble"
freeMarbleButton.Size = UDim2.fromOffset(60, 60)
freeMarbleButton.BackgroundColor3 = Color3.fromRGB(150, 100, 200) -- Purple/mythical color
freeMarbleButton.BorderSizePixel = 0
freeMarbleButton.Image = "rbxassetid://94105658467584"
freeMarbleButton.ScaleType = Enum.ScaleType.Fit
freeMarbleButton.LayoutOrder = 0 -- Above luck button
freeMarbleButton.Parent = quickBuyContainer

local freeMarbleCorner = Instance.new("UICorner")
freeMarbleCorner.CornerRadius = UDim.new(0, 10)
freeMarbleCorner.Parent = freeMarbleButton

-- Countdown label at bottom of button (small badge style)
local freeMarbleCountdown = Instance.new("TextLabel")
freeMarbleCountdown.Name = "Countdown"
freeMarbleCountdown.Size = UDim2.new(1, -4, 0, 24) -- Full width minus padding, increased height for larger text
freeMarbleCountdown.Position = UDim2.new(0, 2, 1, -2) -- At the very bottom with 2px margin
freeMarbleCountdown.AnchorPoint = Vector2.new(0, 1) -- Anchor to bottom-left
freeMarbleCountdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
freeMarbleCountdown.BackgroundTransparency = 0.4
freeMarbleCountdown.BorderSizePixel = 0
freeMarbleCountdown.TextColor3 = Color3.new(1, 1, 1)
freeMarbleCountdown.Font = Enum.Font.GothamBold
freeMarbleCountdown.TextSize = 16 -- Increased from 12 to 16 for larger text
freeMarbleCountdown.Text = "10:00"
freeMarbleCountdown.TextStrokeTransparency = 0.5
freeMarbleCountdown.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
freeMarbleCountdown.Parent = freeMarbleButton

local freeMarbleCountdownCorner = Instance.new("UICorner")
freeMarbleCountdownCorner.CornerRadius = UDim.new(0, 4)
freeMarbleCountdownCorner.Parent = freeMarbleCountdown

-- Permanent 2x Luck Quick Buy Button (Robux item) - BELOW free marble button
local luckButton = Instance.new("ImageButton")
luckButton.Name = "LuckQuickBuy"
luckButton.Size = UDim2.fromOffset(60, 60)
luckButton.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
luckButton.BorderSizePixel = 0
luckButton.Image = "rbxassetid://122460327748810"
luckButton.ScaleType = Enum.ScaleType.Fit
luckButton.LayoutOrder = 1
luckButton.Parent = quickBuyContainer

local luckBtnCorner = Instance.new("UICorner")
luckBtnCorner.CornerRadius = UDim.new(0, 10)
luckBtnCorner.Parent = luckButton

-- Nuke All Quick Buy Button (Robux item) - BELOW
local nukeButton = Instance.new("ImageButton")
nukeButton.Name = "NukeQuickBuy"
nukeButton.Size = UDim2.fromOffset(60, 60)
nukeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
nukeButton.BorderSizePixel = 0
nukeButton.Image = "rbxassetid://115934412352825"
nukeButton.ScaleType = Enum.ScaleType.Fit
nukeButton.LayoutOrder = 2
nukeButton.Parent = quickBuyContainer

local nukeCorner = Instance.new("UICorner")
nukeCorner.CornerRadius = UDim.new(0, 8)
nukeCorner.Parent = nukeButton

-- Hover effects for quick buy buttons
local function setupHoverEffects(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = normalColor
    end)
end

setupHoverEffects(freeMarbleButton, Color3.fromRGB(150, 100, 200), Color3.fromRGB(180, 130, 230))
setupHoverEffects(luckButton, Color3.fromRGB(100, 50, 150), Color3.fromRGB(140, 70, 190))
setupHoverEffects(nukeButton, Color3.fromRGB(180, 60, 60), Color3.fromRGB(220, 80, 80))

-- Handle Permanent 2x Luck quick buy (Robux purchase)
luckButton.MouseButton1Click:Connect(function()
    local robuxPurchase = remotes:FindFirstChild("RobuxPurchase")
    if robuxPurchase then
        robuxPurchase:FireServer("permanent_luck")
    end
end)

-- Handle Nuke All quick buy (Robux purchase)
nukeButton.MouseButton1Click:Connect(function()
    local robuxPurchase = remotes:FindFirstChild("RobuxPurchase")
    if robuxPurchase then
        robuxPurchase:FireServer("nuke_all")
    end
end)

-- Free Mythical Marble countdown and claim logic (client-side only, resets on join)
local COOLDOWN_DURATION = 600 -- 10 minutes (600 seconds)
local freeMarbleTimeRemaining = COOLDOWN_DURATION -- Start at 10 minutes when joining
local canClaim = false -- Track if player can claim

-- Function to update free marble countdown display
local function updateFreeMarbleDisplay()
    if freeMarbleTimeRemaining > 0 then
        local minutes = math.floor(freeMarbleTimeRemaining / 60)
        local seconds = freeMarbleTimeRemaining % 60
        freeMarbleCountdown.Text = string.format("%d:%02d", minutes, seconds)
        freeMarbleCountdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black during countdown
        freeMarbleCountdown.Visible = true
        freeMarbleButton.Active = false -- Disable clicking during countdown
        canClaim = false
    else
        freeMarbleCountdown.Text = "READY"
        freeMarbleCountdown.BackgroundColor3 = Color3.fromRGB(0, 200, 0) -- Green when ready
        freeMarbleCountdown.Visible = true
        freeMarbleButton.Active = true -- Enable clicking when ready
        canClaim = true
    end
end

-- Initial display update
updateFreeMarbleDisplay()

-- Update countdown every second (client-side only)
task.spawn(function()
    while true do
        task.wait(1)
        if freeMarbleTimeRemaining > 0 then
            freeMarbleTimeRemaining = math.max(0, freeMarbleTimeRemaining - 1)
            updateFreeMarbleDisplay()
        end
    end
end)

-- Handle Free Mythical Marble button click
freeMarbleButton.MouseButton1Click:Connect(function()
    if not canClaim or freeMarbleTimeRemaining > 0 then
        return -- Still on cooldown
    end
    
    -- Reset timer after claiming
    freeMarbleTimeRemaining = COOLDOWN_DURATION
    canClaim = false
    updateFreeMarbleDisplay()
    
    local claimRemote = remotes:FindFirstChild("ClaimFreeMythicalMarble")
    if claimRemote then
        claimRemote:FireServer()
    end
end)

-- Create marble unlock popup
local function createMarbleUnlockPopup()
    local popup = Instance.new("Frame")
    popup.Name = "MarbleUnlockPopup"
    popup.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    popup.BorderSizePixel = 0
    popup.Size = UDim2.fromOffset(400, 120)
    popup.Position = UDim2.new(0.5, 0, 0.2, 0)
    popup.AnchorPoint = Vector2.new(0.5, 0.5)
    popup.Parent = screen
    popup.ZIndex = 20
    popup.Visible = false
    popup.ClipsDescendants = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = popup
    
    -- Add border glow effect
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(255, 0, 0) -- Red color
    border.Thickness = 3
    border.Transparency = 0
    border.Parent = popup
    
    -- Marble icon/emoji
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.fromOffset(60, 60)
    icon.Position = UDim2.new(0, 20, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Text = "💎"
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.TextColor3 = Color3.fromRGB(150, 100, 200)
    icon.TextTransparency = 0
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.TextYAlignment = Enum.TextYAlignment.Center
    icon.ZIndex = 21
    icon.Visible = true
    icon.Parent = popup
    
    -- Marble name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -100, 0, 40)
    nameLabel.Position = UDim2.new(0, 100, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Castle Marble"
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextTransparency = 0
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.ZIndex = 21
    nameLabel.Visible = true
    nameLabel.Parent = popup
    
    -- Status label (Unlocked X/200)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -100, 0, 30)
    statusLabel.Position = UDim2.new(0, 100, 0, 60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Unlocked 1/200"
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
    statusLabel.TextTransparency = 0
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    statusLabel.ZIndex = 21
    statusLabel.Visible = true
    statusLabel.Parent = popup
    
    -- Function to show popup
    local function showPopup(marbleName: string, ownedCount: number, totalCount: number)
        nameLabel.Text = marbleName .. " Marble"
        statusLabel.Text = string.format("Unlocked %d/%d", ownedCount, totalCount)
        
        -- Reset position and transparency
        popup.Position = UDim2.new(0.5, 0, 0.1, -50)
        popup.BackgroundTransparency = 0
        popup.Visible = true
        
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
    
    return showPopup
end

-- Create the popup and get the show function
local showMarbleUnlockPopup = createMarbleUnlockPopup()

-- Listen for marble unlock notifications
local marbleUnlocked = remotes:WaitForChild("MarbleUnlocked", 10)
if marbleUnlocked then
    marbleUnlocked.OnClientEvent:Connect(function(marbleName: string, ownedCount: number, totalCount: number)
        showMarbleUnlockPopup(marbleName, ownedCount, totalCount)
    end)
end

-- Luck timer label (moved lower to avoid overlapping buttons)
local luckLabel = Instance.new("TextLabel")
luckLabel.BackgroundTransparency = 0.2
luckLabel.BackgroundColor3 = Color3.fromRGB(100, 50, 150) -- Purple for luck
luckLabel.TextColor3 = Color3.new(1,1,1)
luckLabel.Font = Enum.Font.GothamBold
luckLabel.TextScaled = true
luckLabel.Size = UDim2.fromOffset(160, 30)
luckLabel.Position = UDim2.new(1, -20, 0, 280) -- Moved lower to avoid overlapping buttons
luckLabel.AnchorPoint = Vector2.new(1, 0)
luckLabel.Text = "Luck: 1.0x"
luckLabel.Visible = false -- Initially hidden
luckLabel.Parent = screen

local luckCorner = Instance.new("UICorner")
luckCorner.CornerRadius = UDim.new(0, 8)
luckCorner.Parent = luckLabel

-- Variables for luck timer
local currentLuckMultiplier = 1.0
local luckEndTime = 0
local luckTimerConnection = nil
local permanentLuckBonus = 1.0

-- Function to update luck display
local function updateLuckDisplay()
    local currentTime = os.time()
    local timeLeft = math.max(0, luckEndTime - currentTime)
    
    -- Check if there's an active potion
    if currentLuckMultiplier > 1.0 and luckEndTime > 0 and timeLeft > 0 then
        -- Active potion with timer
        local minutes = math.floor(timeLeft / 60)
        local seconds = timeLeft % 60
        luckLabel.Text = string.format("Luck: %.1fx (%d:%02d)", currentLuckMultiplier, minutes, seconds)
        luckLabel.BackgroundColor3 = Color3.fromRGB(100, 50, 150) -- Purple for active potion
        luckLabel.Visible = true
    elseif permanentLuckBonus > 1.0 then
        -- Only permanent luck, no active potion
        luckLabel.Text = string.format("Luck: %.1fx (Permanent)", permanentLuckBonus)
        luckLabel.BackgroundColor3 = Color3.fromRGB(100, 50, 150) -- Purple for permanent
        luckLabel.Visible = true
    else
        -- No luck bonus
        luckLabel.Visible = false
    end
    
    -- Clean up timer if potion expired
    if luckEndTime > 0 and timeLeft <= 0 then
        luckEndTime = 0
        if luckTimerConnection then
            luckTimerConnection:Disconnect()
            luckTimerConnection = nil
        end
        -- Update display to show permanent luck if available
        updateLuckDisplay()
    end
end

-- Function to start luck timer
local function startLuckTimer(multiplier, duration)
    -- The multiplier includes both permanent bonus and potion multiplier
    -- Store the total multiplier for display
    currentLuckMultiplier = multiplier
    luckEndTime = os.time() + duration
    
    -- Start timer loop
    if luckTimerConnection then
        luckTimerConnection:Disconnect()
    end
    
    luckTimerConnection = game:GetService("RunService").Heartbeat:Connect(function()
        updateLuckDisplay()
    end)
    
    -- Initial update
    updateLuckDisplay()
end

CoinCountUpdate.OnClientEvent:Connect(function(count: number)
	label.Text = string.format("$ %d", count or 0)
end)

-- Listen for luck updates
LuckUpdate.OnClientEvent:Connect(function(multiplier: number, timeLeft: number)
    -- Extract permanent bonus from total multiplier
    -- The multiplier includes both permanent bonus and potion multiplier
    if timeLeft > 0 then
        -- Active potion - start timer
        startLuckTimer(multiplier, timeLeft)
    else
        -- No active potion - check if there's permanent luck
        -- The multiplier should be the permanent bonus when timeLeft is 0
        if multiplier > 1.0 then
            permanentLuckBonus = multiplier
            currentLuckMultiplier = 1.0
            luckEndTime = 0
        else
            permanentLuckBonus = 1.0
            currentLuckMultiplier = 1.0
            luckEndTime = 0
        end
        
        if luckTimerConnection then
            luckTimerConnection:Disconnect()
            luckTimerConnection = nil
        end
        
        updateLuckDisplay()
    end
end)

-- Listen for Robux data updates to get permanent luck bonus
local robuxDataUpdate = remotes:WaitForChild("RobuxDataUpdate", 10)
if robuxDataUpdate then
    robuxDataUpdate.OnClientEvent:Connect(function(permanentLuckBonusValue: number, hasNukeAll: boolean)
        permanentLuckBonus = permanentLuckBonusValue or 1.0
        updateLuckDisplay()
    end)
end

-- Request Robux data on script load to get permanent luck bonus
task.spawn(function()
    local requestRobuxData = remotes:FindFirstChild("RequestRobuxData")
    if requestRobuxData then
        requestRobuxData:FireServer()
    end
end) 