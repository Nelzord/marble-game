-- CoinDropCountdown: Displays countdown UI for coin drop events

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Wait for remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local CoinDropEventStart: RemoteEvent = remotes:WaitForChild("CoinDropEventStart")
local CoinDropEventEnd: RemoteEvent = remotes:WaitForChild("CoinDropEventEnd")
local CoinDropCountdown: RemoteEvent = remotes:WaitForChild("CoinDropCountdown")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinDropCountdownUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 20 -- Higher display order than coin counter to appear on top
screenGui.Parent = playerGui

-- Countdown label (positioned over coin counter at top-right)
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.BackgroundTransparency = 0.1
countdownLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black background
countdownLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
countdownLabel.Font = Enum.Font.GothamBold
countdownLabel.TextScaled = true
countdownLabel.Size = UDim2.new(0, 300, 0, 45)
countdownLabel.Position = UDim2.new(1, -20, 0, 20) -- Top-right, same position as coin counter
countdownLabel.AnchorPoint = Vector2.new(1, 0) -- Anchor at top-right
countdownLabel.Text = ""
countdownLabel.Visible = false
countdownLabel.ZIndex = 10
countdownLabel.Parent = screenGui

-- Add corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = countdownLabel

-- No stroke/border - match the style of Marbles/Badges/Shop buttons

-- Event active label (shows during the event)
local eventActiveLabel = Instance.new("TextLabel")
eventActiveLabel.Name = "EventActiveLabel"
eventActiveLabel.BackgroundTransparency = 0.1
eventActiveLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black background
eventActiveLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
eventActiveLabel.Font = Enum.Font.GothamBold
eventActiveLabel.TextScaled = true
eventActiveLabel.Size = UDim2.new(0, 320, 0, 45)
eventActiveLabel.Position = UDim2.new(1, -20, 0, 20) -- Top-right, same position as coin counter
eventActiveLabel.AnchorPoint = Vector2.new(1, 0) -- Anchor at top-right
eventActiveLabel.Text = "💰 Coin Drop Active!"
eventActiveLabel.Visible = false
eventActiveLabel.ZIndex = 10
eventActiveLabel.Parent = screenGui

local eventCorner = Instance.new("UICorner")
eventCorner.CornerRadius = UDim.new(0, 8)
eventCorner.Parent = eventActiveLabel

-- No stroke/border - match the style of Marbles/Badges/Shop buttons

-- Event ended label
local eventEndedLabel = Instance.new("TextLabel")
eventEndedLabel.Name = "EventEndedLabel"
eventEndedLabel.BackgroundTransparency = 0.1
eventEndedLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black background
eventEndedLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
eventEndedLabel.Font = Enum.Font.GothamBold
eventEndedLabel.TextSize = 24
eventEndedLabel.TextScaled = false
eventEndedLabel.Size = UDim2.new(0, 280, 0, 40)
eventEndedLabel.Position = UDim2.new(1, -20, 0, 20) -- Top-right, same position as coin counter
eventEndedLabel.AnchorPoint = Vector2.new(1, 0) -- Anchor at top-right
eventEndedLabel.Text = "Coin Drop Event Ended"
eventEndedLabel.Visible = false
eventEndedLabel.ZIndex = 10
eventEndedLabel.Parent = screenGui

local endedCorner = Instance.new("UICorner")
endedCorner.CornerRadius = UDim.new(0, 8)
endedCorner.Parent = eventEndedLabel

-- No stroke/border - match the style of Marbles/Badges/Shop buttons

-- Animation variables
local currentCountdown = 0
local eventActive = false
local countdownThread = nil
local eventThread = nil

-- Function to format time
local function formatTime(seconds: number): string
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

-- Function to show countdown
local function showCountdown(seconds: number)
	print("[CoinDropCountdown] Showing countdown:", seconds)
	currentCountdown = seconds
	countdownLabel.Visible = true
	countdownLabel.Text = string.format("💰 Coin Drop in %s", formatTime(seconds))
	
	-- Update countdown every second (no animation, static text)
	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end
	
	countdownThread = task.spawn(function()
		while currentCountdown > 0 and not eventActive do
			task.wait(1)
			currentCountdown = currentCountdown - 1
			if currentCountdown > 0 then
				countdownLabel.Text = string.format("💰 Coin Drop in %s", formatTime(currentCountdown))
			else
				countdownLabel.Visible = false
			end
		end
		countdownThread = nil
	end)
end

-- Function to show event active
local function showEventActive(duration: number)
	eventActive = true
	countdownLabel.Visible = false
	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end
	
	eventActiveLabel.Visible = true
	local timeLeft = duration
	eventActiveLabel.Text = string.format("💰 Coin Drop Active! (%s)", formatTime(timeLeft))
	
	-- Update timer every second to show countdown during event
	if eventThread then
		task.cancel(eventThread)
		eventThread = nil
	end
	
	eventThread = task.spawn(function()
		while timeLeft > 0 and eventActive do
			task.wait(1)
			timeLeft = timeLeft - 1
			if timeLeft > 0 then
				eventActiveLabel.Text = string.format("💰 Coin Drop Active! (%s)", formatTime(timeLeft))
			else
				eventActiveLabel.Text = "💰 Coin Drop Active! (0:00)"
			end
		end
		eventActiveLabel.Visible = false
		eventActive = false
		eventThread = nil
	end)
end

-- Function to hide event (countdown will show immediately after)
local function hideEvent()
	eventActive = false
	eventActiveLabel.Visible = false
	
	-- Clean up threads
	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end
	if eventThread then
		task.cancel(eventThread)
		eventThread = nil
	end
	
	-- Countdown will be shown by the server sending a new countdown event
end

-- Listen for countdown
CoinDropCountdown.OnClientEvent:Connect(function(seconds: number)
	print("[CoinDropCountdown] Received countdown event:", seconds)
	showCountdown(seconds)
end)

-- Debug: Check if remotes exist
print("[CoinDropCountdown] Script loaded, waiting for events...")
print("[CoinDropCountdown] CoinDropCountdown remote exists:", CoinDropCountdown ~= nil)

-- Listen for event start
CoinDropEventStart.OnClientEvent:Connect(function(duration: number)
	showEventActive(duration)
end)

-- Listen for event end
CoinDropEventEnd.OnClientEvent:Connect(function()
	hideEvent()
end)
