-- Coin HUD: shows coin count at top-right

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local CoinCountUpdate: RemoteEvent = remotes:WaitForChild("CoinCountUpdate")
local LuckUpdate: RemoteEvent = remotes:WaitForChild("LuckUpdate")

-- Separate ScreenGui for coin counter (low DisplayOrder)
local coinCounterScreen = Instance.new("ScreenGui")
coinCounterScreen.Name = "CoinCounter"
coinCounterScreen.ResetOnSpawn = false
coinCounterScreen.IgnoreGuiInset = false
coinCounterScreen.DisplayOrder = 1 -- Low display order, should be below other UI elements
coinCounterScreen.Parent = playerGui

-- Coin label
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 0.4 -- Match Marbles/Badges/Shop opacity
label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
label.TextColor3 = Color3.new(1,1,1)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.Size = UDim2.fromOffset(120, 32) -- Match Marbles/Badges/Shop size
label.Position = UDim2.new(0, 16, 0, 140) -- Below shop button (shop at Y=96, height=32, so 96+32+12=140)
label.AnchorPoint = Vector2.new(0, 0) -- Anchor to top-left to match shop button
label.Text = "$ 0"
label.Parent = coinCounterScreen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

-- ScreenGui for daily rewards calendar and quick buy buttons (high DisplayOrder)
local screen = Instance.new("ScreenGui")
screen.Name = "CoinHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.DisplayOrder = 120 -- Higher than MarbleUI and ShopGUI (110) to overlay everything including roll button, power, etc.
screen.Parent = playerGui

-- Quick Buy Icons Container (below coins, vertical layout)
local quickBuyContainer = Instance.new("Frame")
quickBuyContainer.Name = "QuickBuyContainer"
quickBuyContainer.BackgroundTransparency = 1
quickBuyContainer.Size = UDim2.fromOffset(70, 260) -- Increased height for calendar button
quickBuyContainer.Position = UDim2.new(1, -20, 0, 5) -- Moved up to avoid blocking Luck banner
quickBuyContainer.AnchorPoint = Vector2.new(1, 0)
quickBuyContainer.Parent = screen

local quickBuyLayout = Instance.new("UIListLayout")
quickBuyLayout.FillDirection = Enum.FillDirection.Vertical
quickBuyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
quickBuyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
quickBuyLayout.Padding = UDim.new(0, 12) -- Increased spacing between buttons
quickBuyLayout.Parent = quickBuyContainer

-- Calendar Button (above free marble button)
local calendarButton = Instance.new("ImageButton")
calendarButton.Name = "CalendarButton"
calendarButton.Size = UDim2.fromOffset(60, 60)
calendarButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200) -- Calendar blue color
calendarButton.BorderSizePixel = 0
calendarButton.Image = "rbxassetid://133009860740417"
calendarButton.ScaleType = Enum.ScaleType.Fit
calendarButton.LayoutOrder = -1 -- Above free marble button
calendarButton.Parent = quickBuyContainer

local calendarCorner = Instance.new("UICorner")
calendarCorner.CornerRadius = UDim.new(0, 10)
calendarCorner.Parent = calendarButton

-- Red info badge on calendar button (top right)
local calendarInfoBadge = Instance.new("Frame")
calendarInfoBadge.Name = "InfoBadge"
calendarInfoBadge.Size = UDim2.fromOffset(18, 18)
calendarInfoBadge.Position = UDim2.new(1, -2, 0, 2)
calendarInfoBadge.AnchorPoint = Vector2.new(1, 0)
calendarInfoBadge.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red
calendarInfoBadge.BorderSizePixel = 0
calendarInfoBadge.ZIndex = 10
calendarInfoBadge.Parent = calendarButton

local infoBadgeCorner = Instance.new("UICorner")
infoBadgeCorner.CornerRadius = UDim.new(0, 9) -- Fully circular
infoBadgeCorner.Parent = calendarInfoBadge

local infoBadgeLabel = Instance.new("TextLabel")
infoBadgeLabel.Name = "InfoLabel"
infoBadgeLabel.Size = UDim2.new(1, 0, 1, 0)
infoBadgeLabel.BackgroundTransparency = 1
infoBadgeLabel.Text = "!"
infoBadgeLabel.TextColor3 = Color3.new(1, 1, 1)
infoBadgeLabel.TextScaled = true
infoBadgeLabel.Font = Enum.Font.GothamBold
infoBadgeLabel.ZIndex = 11
infoBadgeLabel.Parent = calendarInfoBadge

-- Calendar overlay (full screen, clickable background)
local calendarOverlay = Instance.new("TextButton")
calendarOverlay.Name = "CalendarOverlay"
calendarOverlay.Size = UDim2.new(1, 0, 1, 0)
calendarOverlay.Position = UDim2.new(0, 0, 0, 0)
calendarOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
calendarOverlay.BackgroundTransparency = 0.5
calendarOverlay.BorderSizePixel = 0
calendarOverlay.Text = ""
calendarOverlay.AutoButtonColor = false
calendarOverlay.Visible = false
calendarOverlay.ZIndex = 50 -- High ZIndex to overlay other buttons
calendarOverlay.Parent = screen

-- Calendar UI Frame (initially hidden)
local calendarFrame = Instance.new("Frame")
calendarFrame.Name = "CalendarFrame"
calendarFrame.Size = UDim2.new(0, 500, 0, 400)
calendarFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
calendarFrame.AnchorPoint = Vector2.new(0.5, 0.5)
calendarFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
calendarFrame.BorderSizePixel = 0
calendarFrame.Visible = false
calendarFrame.ZIndex = 51 -- Higher than overlay to appear on top
calendarFrame.Parent = screen

local calendarFrameCorner = Instance.new("UICorner")
calendarFrameCorner.CornerRadius = UDim.new(0, 12)
calendarFrameCorner.Parent = calendarFrame

-- Calendar title
local calendarTitle = Instance.new("TextLabel")
calendarTitle.Name = "Title"
calendarTitle.Size = UDim2.new(1, 0, 0, 50)
calendarTitle.Position = UDim2.new(0, 0, 0, 0)
calendarTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
calendarTitle.BorderSizePixel = 0
calendarTitle.Text = "Daily Rewards"
calendarTitle.TextColor3 = Color3.new(1, 1, 1)
calendarTitle.TextScaled = true
calendarTitle.Font = Enum.Font.GothamBold
calendarTitle.ZIndex = 52
calendarTitle.Parent = calendarFrame

local calendarTitleCorner = Instance.new("UICorner")
calendarTitleCorner.CornerRadius = UDim.new(0, 12)
calendarTitleCorner.Parent = calendarTitle

-- Close button (top right of banner)
local calendarCloseButton = Instance.new("TextButton")
calendarCloseButton.Name = "CloseButton"
calendarCloseButton.Size = UDim2.fromOffset(40, 40)
calendarCloseButton.Position = UDim2.new(1, -10, 0, 5)
calendarCloseButton.AnchorPoint = Vector2.new(1, 0)
calendarCloseButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
calendarCloseButton.BorderSizePixel = 0
calendarCloseButton.Text = "X"
calendarCloseButton.TextColor3 = Color3.new(1, 1, 1)
calendarCloseButton.TextScaled = true
calendarCloseButton.Font = Enum.Font.GothamBold
calendarCloseButton.ZIndex = 53
calendarCloseButton.Parent = calendarTitle

local calendarCloseCorner = Instance.new("UICorner")
calendarCloseCorner.CornerRadius = UDim.new(0, 8)
calendarCloseCorner.Parent = calendarCloseButton

-- Days container for days 1-6 (two rows)
local daysContainer = Instance.new("Frame")
daysContainer.Name = "DaysContainer"
daysContainer.Size = UDim2.new(1, -40, 0, 160) -- Increased height for 2 rows with more spacing
daysContainer.Position = UDim2.new(0, 20, 0, 70)
daysContainer.BackgroundTransparency = 1
daysContainer.ZIndex = 52
daysContainer.Parent = calendarFrame

local daysLayout = Instance.new("UIGridLayout")
daysLayout.FillDirection = Enum.FillDirection.Horizontal
daysLayout.FillDirectionMaxCells = 3 -- 3 columns for days 1-3 and 4-6
daysLayout.CellPadding = UDim2.fromOffset(10, 10)
daysLayout.CellSize = UDim2.fromOffset(140, 70) -- Increased height to fit reward text and button
daysLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
daysLayout.VerticalAlignment = Enum.VerticalAlignment.Top
daysLayout.Parent = daysContainer

-- Define rewards for each day
local dailyRewards = {
	[1] = { type = "coins", amount = 100, display = "100 Gold" },
	[2] = { type = "marble", id = "Gold", display = "Gold Marble" },
	[3] = { type = "luck", display = "2x Luck Potion" },
	[4] = { type = "marble", id = "Diamond", display = "Diamond Marble" },
	[5] = { type = "coins", amount = 500, display = "500 Gold" },
	[6] = { type = "coins", amount = 1000, display = "1000 Gold" },
}

-- Create days 1-6 in grid layout
for day = 1, 6 do
	local reward = dailyRewards[day]
	local dayFrame = Instance.new("Frame")
	dayFrame.Name = "Day" .. day
	dayFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	dayFrame.BorderSizePixel = 0
	dayFrame.ZIndex = 53
	dayFrame.Parent = daysContainer
	
	local dayCorner = Instance.new("UICorner")
	dayCorner.CornerRadius = UDim.new(0, 8)
	dayCorner.Parent = dayFrame
	
	local dayLabel = Instance.new("TextLabel")
	dayLabel.Name = "DayLabel"
	dayLabel.Size = UDim2.new(1, 0, 0, 18)
	dayLabel.Position = UDim2.new(0, 0, 0, 3)
	dayLabel.BackgroundTransparency = 1
	dayLabel.Text = "Day " .. day
	dayLabel.TextColor3 = Color3.new(1, 1, 1)
	dayLabel.TextSize = 12
	dayLabel.Font = Enum.Font.GothamBold
	dayLabel.ZIndex = 54
	dayLabel.Parent = dayFrame
	
	-- Reward label - shows what they're going to get
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Name = "RewardLabel"
	rewardLabel.Size = UDim2.new(1, -10, 0, 28)
	rewardLabel.Position = UDim2.new(0, 5, 0, 20)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = reward.display
	rewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
	rewardLabel.TextSize = 10
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.TextWrapped = true
	rewardLabel.ZIndex = 54
	rewardLabel.Parent = dayFrame
	
	-- Claim button
	local claimButton = Instance.new("TextButton")
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(1, -10, 0, 18)
	claimButton.Position = UDim2.new(0, 5, 1, -5)
	claimButton.AnchorPoint = Vector2.new(0, 1)
	claimButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	claimButton.BorderSizePixel = 0
	claimButton.Text = "CLAIM"
	claimButton.TextColor3 = Color3.new(1, 1, 1)
	claimButton.TextSize = 10
	claimButton.Font = Enum.Font.GothamBold
	claimButton.ZIndex = 54
	claimButton.Parent = dayFrame
	
	local claimCorner = Instance.new("UICorner")
	claimCorner.CornerRadius = UDim.new(0, 4)
	claimCorner.Parent = claimButton
	
	-- Store reward data in button for claim handler
	claimButton:SetAttribute("RewardType", reward.type)
	if reward.amount then
		claimButton:SetAttribute("RewardAmount", reward.amount)
	end
	if reward.id then
		claimButton:SetAttribute("RewardId", reward.id)
	end
	claimButton:SetAttribute("Day", day)
	
	-- Connect claim button
	claimButton.MouseButton1Click:Connect(function()
		if not claimButton.Active then
			return -- Button is disabled (locked or already claimed)
		end
		
		local rewardType = claimButton:GetAttribute("RewardType")
		local rewardAmount = claimButton:GetAttribute("RewardAmount")
		local rewardId = claimButton:GetAttribute("RewardId")
		local dayNum = claimButton:GetAttribute("Day")
		
		-- Get or create the remote event for daily rewards
		local dailyRewardRemote = remotes:FindFirstChild("ClaimDailyReward")
		if not dailyRewardRemote then
			dailyRewardRemote = Instance.new("RemoteEvent")
			dailyRewardRemote.Name = "ClaimDailyReward"
			dailyRewardRemote.Parent = remotes
		end
		
		-- Fire to server
		dailyRewardRemote:FireServer(dayNum, rewardType, rewardAmount, rewardId)
		
		-- Request updated state after claiming
		task.wait(0.5) -- Small delay to allow server to process
		local requestState = remotes:FindFirstChild("RequestDailyRewardState")
		if requestState then
			requestState:FireServer()
		end
	end)
end

-- Day 7 - Smaller frame at the bottom
local day7Frame = Instance.new("Frame")
day7Frame.Name = "Day7"
day7Frame.Size = UDim2.new(1, -40, 0, 100) -- Reduced height to make it smaller
day7Frame.Position = UDim2.new(0, 20, 1, -60) -- Lower position, closer to bottom
day7Frame.AnchorPoint = Vector2.new(0, 1)
day7Frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
day7Frame.BorderSizePixel = 0
day7Frame.ZIndex = 53
day7Frame.Parent = calendarFrame

local day7Corner = Instance.new("UICorner")
day7Corner.CornerRadius = UDim.new(0, 8)
day7Corner.Parent = day7Frame

local day7Label = Instance.new("TextLabel")
day7Label.Name = "DayLabel"
day7Label.Size = UDim2.new(1, 0, 0, 20)
day7Label.Position = UDim2.new(0, 0, 0, 8)
day7Label.BackgroundTransparency = 1
day7Label.Text = "Day 7"
day7Label.TextColor3 = Color3.new(1, 1, 1)
day7Label.TextSize = 14
day7Label.Font = Enum.Font.GothamBold
day7Label.ZIndex = 54
day7Label.Parent = day7Frame

-- Day 7 reward label
local day7RewardLabel = Instance.new("TextLabel")
day7RewardLabel.Name = "RewardLabel"
day7RewardLabel.Size = UDim2.new(1, -20, 0, 35)
day7RewardLabel.Position = UDim2.new(0, 10, 0, 30)
day7RewardLabel.BackgroundTransparency = 1
day7RewardLabel.Text = "Limited exceedingly rare reward"
day7RewardLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red/pink for rare
day7RewardLabel.TextSize = 12
day7RewardLabel.Font = Enum.Font.GothamBold
day7RewardLabel.TextWrapped = true
day7RewardLabel.ZIndex = 54
day7RewardLabel.Parent = day7Frame

-- Day 7 claim button
local day7ClaimButton = Instance.new("TextButton")
day7ClaimButton.Name = "ClaimButton"
day7ClaimButton.Size = UDim2.new(1, -20, 0, 25)
day7ClaimButton.Position = UDim2.new(0, 10, 1, -5)
day7ClaimButton.AnchorPoint = Vector2.new(0, 1)
day7ClaimButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
day7ClaimButton.BorderSizePixel = 0
day7ClaimButton.Text = "CLAIM"
day7ClaimButton.TextColor3 = Color3.new(1, 1, 1)
day7ClaimButton.TextSize = 12
day7ClaimButton.Font = Enum.Font.GothamBold
day7ClaimButton.ZIndex = 54
day7ClaimButton.Parent = day7Frame

local day7ClaimCorner = Instance.new("UICorner")
day7ClaimCorner.CornerRadius = UDim.new(0, 6)
day7ClaimCorner.Parent = day7ClaimButton

-- Store reward data for Day 7
day7ClaimButton:SetAttribute("RewardType", "marble")
day7ClaimButton:SetAttribute("RewardId", "Coin")
day7ClaimButton:SetAttribute("Day", 7)

-- Track if calendar has been opened
local calendarHasBeenOpened = false

-- Daily reward state
local currentDay = 1
local claimedToday = false

-- Function to update daily reward UI
local function updateDailyRewardUI()
	-- Update claim buttons for days 1-6
	for day = 1, 6 do
		local dayFrame = daysContainer:FindFirstChild("Day" .. day)
		if dayFrame then
			local claimButton = dayFrame:FindFirstChild("ClaimButton")
			if claimButton then
				if day < currentDay then
					-- Past day - already claimed (shows as claimed)
					claimButton.Text = "CLAIMED"
					claimButton.TextSize = 10
					claimButton.TextScaled = false
					claimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					claimButton.Active = false
				elseif day == currentDay and not claimedToday then
					-- Current day - can claim
					claimButton.Text = "CLAIM"
					claimButton.TextSize = 10
					claimButton.TextScaled = false
					claimButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
					claimButton.Active = true
				elseif day == currentDay and claimedToday then
					-- Already claimed today - show claimed
					claimButton.Text = "CLAIMED"
					claimButton.TextSize = 10
					claimButton.TextScaled = false
					claimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					claimButton.Active = false
				else
					-- Future day - locked
					claimButton.Text = "LOCKED"
					claimButton.TextSize = 10
					claimButton.TextScaled = false
					claimButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					claimButton.Active = false
				end
			end
		end
	end
	
	-- Update Day 7 claim button
	if day7ClaimButton then
		if 7 < currentDay then
			-- Past day - already claimed
			day7ClaimButton.Text = "CLAIMED"
			day7ClaimButton.TextSize = 12
			day7ClaimButton.TextScaled = false
			day7ClaimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			day7ClaimButton.Active = false
		elseif 7 == currentDay and not claimedToday then
			-- Current day - can claim
			day7ClaimButton.Text = "CLAIM"
			day7ClaimButton.TextSize = 12
			day7ClaimButton.TextScaled = false
			day7ClaimButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
			day7ClaimButton.Active = true
		elseif 7 == currentDay and claimedToday then
			-- Already claimed today - show claimed
			day7ClaimButton.Text = "CLAIMED"
			day7ClaimButton.TextSize = 12
			day7ClaimButton.TextScaled = false
			day7ClaimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			day7ClaimButton.Active = false
		else
			-- Future day - locked
			day7ClaimButton.Text = "LOCKED"
			day7ClaimButton.TextSize = 12
			day7ClaimButton.TextScaled = false
			day7ClaimButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			day7ClaimButton.Active = false
		end
	end
end

-- Listen for daily reward state updates
local dailyRewardStateRemote = remotes:FindFirstChild("DailyRewardState")
if dailyRewardStateRemote then
	dailyRewardStateRemote.OnClientEvent:Connect(function(day: number, claimed: boolean)
		currentDay = day
		claimedToday = claimed or false
		updateDailyRewardUI()
	end)
end

-- Function to close calendar
local function closeCalendar()
	calendarFrame.Visible = false
	calendarOverlay.Visible = false
end

-- Handle calendar button click
calendarButton.MouseButton1Click:Connect(function()
	-- Show overlay first, then frame on top
	calendarOverlay.Visible = true
	calendarFrame.Visible = true
	calendarFrame.Active = true
	
	-- Request daily reward state
	local requestState = remotes:FindFirstChild("RequestDailyRewardState")
	if requestState then
		requestState:FireServer()
	end
	
	-- Hide info badge after first click
	if not calendarHasBeenOpened then
		calendarInfoBadge.Visible = false
		calendarHasBeenOpened = true
	end
end)

-- Handle close button click
calendarCloseButton.MouseButton1Click:Connect(closeCalendar)

-- Handle clicking outside (on overlay) to close
calendarOverlay.MouseButton1Click:Connect(closeCalendar)

-- Connect Day 7 claim button
day7ClaimButton.MouseButton1Click:Connect(function()
	if not day7ClaimButton.Active then
		return -- Button is disabled (locked or already claimed)
	end
	
	local rewardType = day7ClaimButton:GetAttribute("RewardType")
	local rewardId = day7ClaimButton:GetAttribute("RewardId")
	local dayNum = day7ClaimButton:GetAttribute("Day")
	
	-- Get or create the remote event for daily rewards
	local dailyRewardRemote = remotes:FindFirstChild("ClaimDailyReward")
	if not dailyRewardRemote then
		dailyRewardRemote = Instance.new("RemoteEvent")
		dailyRewardRemote.Name = "ClaimDailyReward"
		dailyRewardRemote.Parent = remotes
	end
	
	-- Fire to server
	dailyRewardRemote:FireServer(dayNum, rewardType, nil, rewardId)
	
	-- Request updated state after claiming
	task.wait(0.5) -- Small delay to allow server to process
	local requestState = remotes:FindFirstChild("RequestDailyRewardState")
	if requestState then
		requestState:FireServer()
	end
end)

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

setupHoverEffects(calendarButton, Color3.fromRGB(50, 150, 200), Color3.fromRGB(70, 180, 230))
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

-- Request daily reward state on script load
task.spawn(function()
	task.wait(1) -- Wait for server to be ready
	local requestState = remotes:FindFirstChild("RequestDailyRewardState")
	if requestState then
		requestState:FireServer()
	end
end) 