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
label.Size = UDim2.fromOffset(160, 40)
label.Position = UDim2.new(1, -20, 0, 20)
label.AnchorPoint = Vector2.new(1, 0)
label.Text = "Coins: 0"
label.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

-- Luck timer label
local luckLabel = Instance.new("TextLabel")
luckLabel.BackgroundTransparency = 0.2
luckLabel.BackgroundColor3 = Color3.fromRGB(100, 50, 150) -- Purple for luck
luckLabel.TextColor3 = Color3.new(1,1,1)
luckLabel.Font = Enum.Font.GothamBold
luckLabel.TextScaled = true
luckLabel.Size = UDim2.fromOffset(160, 30)
luckLabel.Position = UDim2.new(1, -20, 0, 70)
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

-- Function to update luck display
local function updateLuckDisplay()
    if currentLuckMultiplier > 1.0 and luckEndTime > 0 then
        local currentTime = os.time()
        local timeLeft = math.max(0, luckEndTime - currentTime)
        
        if timeLeft > 0 then
            local minutes = math.floor(timeLeft / 60)
            local seconds = timeLeft % 60
            luckLabel.Text = string.format("Luck: %.1fx (%d:%02d)", currentLuckMultiplier, minutes, seconds)
            luckLabel.Visible = true
        else
            -- Luck expired
            currentLuckMultiplier = 1.0
            luckEndTime = 0
            luckLabel.Visible = false
            if luckTimerConnection then
                luckTimerConnection:Disconnect()
                luckTimerConnection = nil
            end
        end
    else
        luckLabel.Visible = false
        if luckTimerConnection then
            luckTimerConnection:Disconnect()
            luckTimerConnection = nil
        end
    end
end

-- Function to start luck timer
local function startLuckTimer(multiplier, duration)
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
	label.Text = string.format("Coins: %d", count or 0)
end)

-- Listen for luck updates
LuckUpdate.OnClientEvent:Connect(function(multiplier: number, timeLeft: number)
    if multiplier > 1.0 and timeLeft > 0 then
        startLuckTimer(multiplier, timeLeft)
    else
        currentLuckMultiplier = 1.0
        luckEndTime = 0
        luckLabel.Visible = false
        if luckTimerConnection then
            luckTimerConnection:Disconnect()
            luckTimerConnection = nil
        end
    end
end) 