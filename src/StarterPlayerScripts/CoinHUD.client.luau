-- Coin HUD: shows coin count at top-right

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
label.Position = UDim2.new(1, -20, 0, 20)
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
quickBuyContainer.Size = UDim2.fromOffset(70, 130)
quickBuyContainer.Position = UDim2.new(1, -20, 0, 65)
quickBuyContainer.AnchorPoint = Vector2.new(1, 0)
quickBuyContainer.Parent = screen

local quickBuyLayout = Instance.new("UIListLayout")
quickBuyLayout.FillDirection = Enum.FillDirection.Vertical
quickBuyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
quickBuyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
quickBuyLayout.Padding = UDim.new(0, 6)
quickBuyLayout.Parent = quickBuyContainer

-- Permanent 2x Luck Quick Buy Button (Robux item) - BIGGER, ON TOP
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

-- Luck timer label
local luckLabel = Instance.new("TextLabel")
luckLabel.BackgroundTransparency = 0.2
luckLabel.BackgroundColor3 = Color3.fromRGB(100, 50, 150) -- Purple for luck
luckLabel.TextColor3 = Color3.new(1,1,1)
luckLabel.Font = Enum.Font.GothamBold
luckLabel.TextScaled = true
luckLabel.Size = UDim2.fromOffset(160, 30)
luckLabel.Position = UDim2.new(1, -20, 0, 200)
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