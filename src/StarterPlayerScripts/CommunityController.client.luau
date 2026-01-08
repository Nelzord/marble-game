-- CommunityController: Client-side handler for community/group join prompts
-- Receives event from server and opens the group page directly

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local GROUP_ID = 283577267
local GROUP_NAME = "Marble Collector"
local GROUP_URL = "https://www.roblox.com/groups/" .. GROUP_ID
local COMMUNITY_DEBUG = true

local function clog(...)
	if COMMUNITY_DEBUG then
		print("[CommunityController]", ...)
	end
end

clog("Initializing...")

-- Try to open the group page directly
local function openGroupPage()
	clog("Attempting to open group page:", GROUP_URL)
	
	-- Method 1: Try SetCore to open Roblox URL (works in published games)
	local success = pcall(function()
		StarterGui:SetCore("OpenRobloxUrl", GROUP_URL)
	end)
	
	if success then
		clog("Successfully opened group page via SetCore")
		return true
	else
		clog("SetCore method failed, trying alternative...")
	end
	
	-- Method 2: Try opening via group ID directly
	local success2 = pcall(function()
		StarterGui:SetCore("OpenRobloxUrl", "https://www.roblox.com/communities/" .. GROUP_ID)
	end)
	
	if success2 then
		clog("Successfully opened community page via SetCore")
		return true
	end
	
	return false
end

-- Fallback UI if direct opening doesn't work
local communityGui = nil
local isShowing = false

local function createFallbackUI()
	if communityGui then return communityGui end
	
	-- Main ScreenGui
	communityGui = Instance.new("ScreenGui")
	communityGui.Name = "CommunityPopup"
	communityGui.ResetOnSpawn = false
	communityGui.DisplayOrder = 100
	communityGui.Parent = PlayerGui
	
	-- Dark overlay background
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = communityGui
	
	-- Main popup frame
	local popup = Instance.new("Frame")
	popup.Name = "Popup"
	popup.Size = UDim2.new(0, 420, 0, 300)
	popup.Position = UDim2.new(0.5, -210, 0.5, -150)
	popup.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	popup.BorderSizePixel = 0
	popup.Parent = communityGui
	
	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 16)
	popupCorner.Parent = popup
	
	-- Gradient accent at top
	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(1, 0, 0, 6)
	accent.Position = UDim2.new(0, 0, 0, 0)
	accent.BorderSizePixel = 0
	accent.Parent = popup
	
	local accentGradient = Instance.new("UIGradient")
	accentGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 180, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))
	})
	accentGradient.Parent = accent
	
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 16)
	accentCorner.Parent = accent
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 40)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "🎱 Join Our Community!"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = popup
	
	-- Group name
	local groupNameLabel = Instance.new("TextLabel")
	groupNameLabel.Name = "GroupName"
	groupNameLabel.Size = UDim2.new(1, -40, 0, 30)
	groupNameLabel.Position = UDim2.new(0, 20, 0, 60)
	groupNameLabel.BackgroundTransparency = 1
	groupNameLabel.Text = GROUP_NAME
	groupNameLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	groupNameLabel.TextSize = 22
	groupNameLabel.Font = Enum.Font.GothamBold
	groupNameLabel.TextXAlignment = Enum.TextXAlignment.Center
	groupNameLabel.Parent = popup
	
	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.Size = UDim2.new(1, -40, 0, 40)
	instructions.Position = UDim2.new(0, 20, 0, 95)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Copy this link and paste it in your browser:"
	instructions.TextColor3 = Color3.fromRGB(200, 200, 200)
	instructions.TextSize = 16
	instructions.Font = Enum.Font.Gotham
	instructions.TextWrapped = true
	instructions.TextXAlignment = Enum.TextXAlignment.Center
	instructions.Parent = popup
	
	-- URL TextBox (selectable/copyable)
	local urlBox = Instance.new("TextBox")
	urlBox.Name = "URLBox"
	urlBox.Size = UDim2.new(1, -60, 0, 40)
	urlBox.Position = UDim2.new(0, 30, 0, 140)
	urlBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	urlBox.BorderSizePixel = 0
	urlBox.Text = GROUP_URL
	urlBox.TextColor3 = Color3.fromRGB(100, 200, 255)
	urlBox.TextSize = 14
	urlBox.Font = Enum.Font.GothamMedium
	urlBox.TextEditable = false
	urlBox.ClearTextOnFocus = false
	urlBox.Parent = popup
	
	local urlBoxCorner = Instance.new("UICorner")
	urlBoxCorner.CornerRadius = UDim.new(0, 8)
	urlBoxCorner.Parent = urlBox
	
	-- Select all text when focused
	urlBox.Focused:Connect(function()
		urlBox:CaptureFocus()
		-- Select all text
		urlBox.SelectionStart = 1
		urlBox.CursorPosition = #urlBox.Text + 1
	end)
	
	-- Hint text
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.Size = UDim2.new(1, -40, 0, 25)
	hintLabel.Position = UDim2.new(0, 20, 0, 185)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "Click the box above to select, then Ctrl+C to copy"
	hintLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	hintLabel.TextSize = 13
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.TextXAlignment = Enum.TextXAlignment.Center
	hintLabel.Parent = popup
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 120, 0, 40)
	closeButton.Position = UDim2.new(0.5, -60, 1, -55)
	closeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "Close"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 18
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = popup
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	
	-- Hover effect for close button
	closeButton.MouseEnter:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 100, 120)}):Play()
	end)
	
	closeButton.MouseLeave:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 80, 100)}):Play()
	end)
	
	closeButton.MouseButton1Click:Connect(function()
		hideCommunityUI()
	end)
	
	-- Click overlay to close
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hideCommunityUI()
		end
	end)
	
	-- Initially hidden
	communityGui.Enabled = false
	
	return communityGui
end

local function showFallbackUI()
	if isShowing then return end
	isShowing = true
	
	local gui = createFallbackUI()
	gui.Enabled = true
	
	-- Animate in
	local popup = gui:FindFirstChild("Popup")
	if popup then
		popup.Position = UDim2.new(0.5, -210, 0.5, -110)
		popup.BackgroundTransparency = 0.3
		TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -210, 0.5, -150),
			BackgroundTransparency = 0
		}):Play()
	end
	
	clog("Showing fallback community UI")
end

function hideCommunityUI()
	if not isShowing then return end
	isShowing = false
	
	if communityGui then
		local popup = communityGui:FindFirstChild("Popup")
		if popup then
			local tween = TweenService:Create(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, -210, 0.5, -110),
				BackgroundTransparency = 0.3
			})
			tween:Play()
			tween.Completed:Connect(function()
				communityGui.Enabled = false
			end)
		else
			communityGui.Enabled = false
		end
	end
	
	clog("Hiding community UI")
end

-- Check if player is already in the group
local function isPlayerInGroup()
	local success, result = pcall(function()
		return player:IsInGroup(GROUP_ID)
	end)
	
	if success then
		return result
	end
	return false
end

-- Wait for the RemoteEvent
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PromptCommunityJoin = Remotes:WaitForChild("PromptCommunityJoin")

-- Handle the prompt request from server
PromptCommunityJoin.OnClientEvent:Connect(function()
	clog("Received community join prompt request")
	
	-- Check if already in group
	if isPlayerInGroup() then
		clog("Player is already in the group!")
	end
	
	-- Try to open the group page directly
	local opened = openGroupPage()
	
	-- If direct open failed, show fallback UI with copyable link
	if not opened then
		clog("Direct open failed, showing fallback UI")
		showFallbackUI()
	end
end)

clog("CommunityController initialized - listening for community join prompts")

