-- Coin HUD: shows coin count at top-right

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local CoinCountUpdate: RemoteEvent = remotes:WaitForChild("CoinCountUpdate")

local screen = Instance.new("ScreenGui")
screen.Name = "CoinHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = playerGui

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

CoinCountUpdate.OnClientEvent:Connect(function(count: number)
	label.Text = string.format("Coins: %d", count or 0)
end) 