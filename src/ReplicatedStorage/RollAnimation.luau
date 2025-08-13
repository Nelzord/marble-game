-- RollAnimation.luau
-- Rolling animation UI and logic for the Marble Game

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))
local RollForMarble: RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RollForMarble")

-- State variables
local isRolling = false
local rollAnimationFrame: Frame? = nil
local rollAnimationText: TextLabel? = nil
local rollAnimationShadow: TextLabel? = nil
local currentRollCallback: (() -> ())? = nil

local RollAnimation = {}

-- Function to create roll animation UI
function RollAnimation:createRollAnimationUI()
	if rollAnimationFrame then
		rollAnimationFrame:Destroy()
	end
	
	rollAnimationFrame = Instance.new("Frame")
	rollAnimationFrame.Name = "RollAnimationFrame"
	rollAnimationFrame.Size = UDim2.new(0, 600, 0, 120)
	rollAnimationFrame.Position = UDim2.new(0.5, 0, 0, -40)
	rollAnimationFrame.AnchorPoint = Vector2.new(0.5, 0)
	rollAnimationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	rollAnimationFrame.BackgroundTransparency = 0.2 -- semi-transparent like inventory and coins
	rollAnimationFrame.BorderSizePixel = 0
	rollAnimationFrame.Visible = false
	rollAnimationFrame.ZIndex = 10
	rollAnimationFrame.Parent = self.screen
	
	-- Add rounded corners to match inventory and coins style
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = rollAnimationFrame
	
	-- Create elements directly in the rollAnimationFrame
	local function createElementInFrame(elementType, properties)
		local element = Instance.new(elementType)
		for property, value in pairs(properties) do
			element[property] = value
		end
		element.Parent = rollAnimationFrame
		return element
	end
	
	-- Title (left side)
	local title = createElementInFrame("TextLabel", {
		Name = "Title",
		Text = "ROLLING FOR MARBLE...",
		TextScaled = true,
		Size = UDim2.new(0.4, 0, 0, 35),
		Position = UDim2.new(0, 20, 0, 15),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		ZIndex = 11
	})
	
	-- Ticket icon (center-right)
	local ticketIcon = createElementInFrame("TextLabel", {
		Name = "TicketIcon",
		Text = "🎫",
		TextScaled = true,
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(0.5, -15, 0, 15),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1), -- White color to match theme
		Font = Enum.Font.GothamBold,
		ZIndex = 11
	})
	
	-- Close button (top-right)
	local closeButton = createElementInFrame("TextButton", {
		Name = "CloseButton",
		Text = "X",
		TextScaled = true,
		Size = UDim2.new(0, 25, 0, 25),
		Position = UDim2.new(1, -35, 0, 15),
		BackgroundColor3 = Color3.fromRGB(255, 100, 100),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		ZIndex = 12
	})
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton
	
	-- Close button functionality
	closeButton.MouseButton1Click:Connect(function()
		print("Close button clicked!")
		if rollAnimationFrame and rollAnimationFrame.Parent then
			print("Destroying roll animation frame")
			rollAnimationFrame:Destroy()
			isRolling = false
		else
			print("rollAnimationFrame not found or not parented")
		end
	end)
	
	-- Rolling text (main display - center)
	rollAnimationText = createElementInFrame("TextLabel", {
		Name = "RollingText",
		Text = "",
		TextScaled = true,
		Size = UDim2.new(0.6, 0, 0, 50),
		Position = UDim2.new(0.2, 0, 0.5, -25),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1), -- White color to match theme
		Font = Enum.Font.GothamBold,
		ZIndex = 11
	})
	
	-- Text shadow (thicker for better visibility on translucent background)
	rollAnimationShadow = createElementInFrame("TextLabel", {
		Name = "RollingTextShadow",
		Text = "",
		TextScaled = true,
		Size = UDim2.new(0.6, 0, 0, 50),
		Position = UDim2.new(0.2, 3, 0.5, -21),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(0, 0, 0),
		Font = Enum.Font.GothamBold,
		ZIndex = 10
	})
	
	-- Progress bar (bottom)
	local progressBar = createElementInFrame("Frame", {
		Name = "ProgressBar",
		Size = UDim2.new(0, 0, 0, 6),
		Position = UDim2.new(0, 20, 1, -30),
		BackgroundColor3 = Color3.fromRGB(100, 100, 100), -- Grey color to match theme
		BorderSizePixel = 0,
		ZIndex = 11
	})
	
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 3)
	progressCorner.Parent = progressBar
	
	-- Progress bar background
	local progressBg = createElementInFrame("Frame", {
		Name = "ProgressBackground",
		Size = UDim2.new(1, -40, 0, 6),
		Position = UDim2.new(0, 20, 1, -30),
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		BorderSizePixel = 0,
		ZIndex = 10
	})
	
	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(0, 3)
	progressBgCorner.Parent = progressBg
	
	-- Result display (same area as rolling text, will replace it)
	local resultDisplay = createElementInFrame("TextLabel", {
		Name = "ResultDisplay",
		Text = "",
		TextScaled = true,
		Size = UDim2.new(0.6, 0, 0, 50),
		Position = UDim2.new(0.2, 0, 0.5, -25),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(0, 255, 0),
		Font = Enum.Font.GothamBold,
		ZIndex = 11,
		Visible = false
	})
	
	return rollAnimationFrame, progressBar
end

-- Function to start roll animation
function RollAnimation:startRoll()
	if isRolling then return end
	isRolling = true
	
	local frame, progressBar = self:createRollAnimationUI()
	frame.Visible = true
	
	-- Get all rollable marbles
	local rollableMarbles = Marbles.getRollable()
	if #rollableMarbles == 0 then
		frame:Destroy()
		isRolling = false
		return
	end
	
	-- Animation duration
	local totalDuration = 3.0 -- 3 seconds
	local startTime = tick()
	
	-- Rolling sound effect
	local rollSfx = Instance.new("Sound")
	rollSfx.Name = "RollSound"
	rollSfx.SoundId = "rbxassetid://127877437691780"
	rollSfx.Volume = 0.4
	rollSfx.Looped = true
	rollSfx.Parent = frame
	rollSfx:Play()
	
	-- Add particle effects for excitement
	local particles = Instance.new("Frame")
	particles.Name = "Particles"
	particles.Size = UDim2.new(1, 0, 1, 0)
	particles.Position = UDim2.new(0, 0, 0, 0)
	particles.BackgroundTransparency = 1
	particles.ZIndex = 9
	particles.Parent = frame
	
	-- Create floating particles (optimized for horizontal layout)
	for i = 1, 12 do -- Reduced particles for horizontal layout
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6)) -- Even smaller particles
		particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
		particle.BackgroundColor3 = Color3.fromRGB(
			math.random(200, 255),
			math.random(200, 255),
			math.random(200, 255)
		)
		particle.BorderSizePixel = 0
		particle.ZIndex = 9
		particle.Parent = particles
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3) -- Smaller corner radius
		corner.Parent = particle
		
		-- Animate particle (horizontal movement focus)
		local startPos = particle.Position
		local endPos = UDim2.new(math.random(), 0, math.random() * 0.5, 0) -- More horizontal movement
		local animStart = tick()
		local animDuration = math.random(1.5, 3) -- Faster animation
		
		RunService.Heartbeat:Connect(function()
			local elapsed = tick() - animStart
			local progress = math.min(elapsed / animDuration, 1)
			
			if progress >= 1 then
				particle:Destroy()
				return
			end
			
			-- Smooth movement
			local currentPos = UDim2.new(
				startPos.X.Scale + (endPos.X.Scale - startPos.X.Scale) * progress,
				startPos.X.Offset + (endPos.X.Offset - startPos.X.Offset) * progress,
				startPos.Y.Scale + (endPos.Y.Scale - startPos.Y.Scale) * progress,
				startPos.Y.Offset + (endPos.Y.Offset - startPos.Y.Offset) * progress
			)
			particle.Position = currentPos
			
			-- Fade out near the end
			if progress > 0.8 then
				particle.BackgroundTransparency = (progress - 0.8) * 5
			end
		end)
	end
	
	-- Animation loop
	local connection
	local lastChangeTime = 0
	local changeInterval = 0.1 -- Change odds display every 0.1 seconds
	local waitingForResult = false
	local resultReceived = false
	
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.min(elapsed / totalDuration, 1)
		local currentTime = tick()
		
		-- Update progress bar (cap at 100% to prevent going off-screen)
		-- Use the actual panel width minus margins (40px total) to ensure it fits
		local maxWidth = (frame.AbsoluteSize.X - 40) / frame.AbsoluteSize.X
		local clampedProgress = math.min(progress, maxWidth)
		progressBar.Size = UDim2.new(clampedProgress, 0, 0, 6)
		
		-- Show odds flying by with dynamic changes
		if progress < 0.8 then
			-- Change odds display at regular intervals for dynamic effect
			if currentTime - lastChangeTime >= changeInterval then
				local randomMarble = rollableMarbles[math.random(1, #rollableMarbles)]
				local oddsText = string.format("%s (1/%d)", randomMarble.name, randomMarble.dropDenominator or 1)
				
				if rollAnimationText then
					rollAnimationText.Text = oddsText
					-- Add some visual flair with color changes
					rollAnimationText.TextColor3 = Color3.fromRGB(
						math.random(200, 255),
						math.random(200, 255),
						math.random(200, 255)
					)
				end
				if rollAnimationShadow then
					rollAnimationShadow.Text = oddsText
				end
				
				lastChangeTime = currentTime
			end
		elseif progress < 1 then
			-- Final reveal phase with pulsing effect
			if rollAnimationText then
				rollAnimationText.Text = "REVEALING..."
				-- Pulsing white color
				local pulse = math.abs(math.sin(currentTime * 8)) * 0.3 + 0.7
				rollAnimationText.TextColor3 = Color3.fromRGB(255 * pulse, 255 * pulse, 255 * pulse)
			end
			if rollAnimationShadow then
				rollAnimationShadow.Text = "REVEALING..."
			end
		else
			-- Animation complete - but wait for server result
			if not waitingForResult then
				waitingForResult = true
				
				-- Change text to waiting for result
				if rollAnimationText then
					rollAnimationText.Text = "WAITING FOR RESULT..."
					rollAnimationText.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
				if rollAnimationShadow then
					rollAnimationShadow.Text = "WAITING FOR RESULT..."
				end
				
				-- Stop the rolling sound
				rollSfx:Stop()
				rollSfx:Destroy()
				
				-- Keep progress bar at max width (respecting margins)
				local maxWidth = (frame.AbsoluteSize.X - 40) / frame.AbsoluteSize.X
				progressBar.Size = UDim2.new(maxWidth, 0, 0, 6)
			end
		end
		
		-- If we have a result and animation is complete, show the result
		if waitingForResult and resultReceived then
			print("Animation complete - showing result and celebration")
			print("waitingForResult:", waitingForResult, "resultReceived:", resultReceived)
			connection:Disconnect()
			
			-- Hide rolling text
			if rollAnimationText then
				rollAnimationText.Visible = false
				print("Hidden rolling text")
			end
			if rollAnimationShadow then
				rollAnimationShadow.Visible = false
				print("Hidden rolling shadow")
			end
			
			-- Show result with celebration effect
			local resultDisplay = frame:FindFirstChild("ResultDisplay")
			if resultDisplay then
				print("Found resultDisplay, making it visible")
				print("ResultDisplay text:", resultDisplay.Text)
				resultDisplay.Visible = true
				-- Don't change the text - it should already contain the stored result from the server
				
				-- Celebration animation
				local celebrationStart = tick()
				local celebrationConnection
				celebrationConnection = RunService.Heartbeat:Connect(function()
					local celebrationElapsed = tick() - celebrationStart
					local celebrationProgress = math.min(celebrationElapsed / 1.5, 1)
					
					-- Bounce effect
					local bounce = math.sin(celebrationElapsed * 10) * (1 - celebrationProgress) * 10
					resultDisplay.Position = UDim2.new(0.2, 0, 0.5, -25 + bounce)
					
					if celebrationProgress >= 1 then
						celebrationConnection:Disconnect()
					end
				end)
			else
				print("ERROR: resultDisplay not found in frame")
			end
			
			-- Fade out after delay
			task.delay(2.0, function()
				if frame and frame.Parent then
					-- Fade out animation
					local fadeTime = 0.8
					local fadeStart = tick()
					local fadeConnection
					fadeConnection = RunService.Heartbeat:Connect(function()
						local fadeElapsed = tick() - fadeStart
						local fadeProgress = math.min(fadeElapsed / fadeTime, 1)
						
						frame.BackgroundTransparency = 0.2 + (fadeProgress * 0.8)
						
						if fadeProgress >= 1 then
							fadeConnection:Disconnect()
							frame:Destroy()
							isRolling = false
						end
					end)
				end
			end)
		end
	end)
	
	-- Actually trigger the roll
	RollForMarble:FireServer()
	
	-- Return a function that can be called when we get the result
	return function()
		print("Roll callback called - setting resultReceived to true")
		resultReceived = true
	end
end

-- Function to show roll result
function RollAnimation:showResult(result)
	print("RollResult received:", result.success, result.marbleName or result.marbleId or "nil")
	
	-- Call the roll callback to complete the animation
	if currentRollCallback then
		print("Calling roll callback to complete animation")
		currentRollCallback()
		currentRollCallback = nil
	else
		print("No roll callback found - animation may have already completed")
	end
	
	-- Store the result but don't show it yet - wait for animation to complete
	if rollAnimationFrame and rollAnimationFrame.Parent then
		local resultDisplay = rollAnimationFrame:FindFirstChild("ResultDisplay")
		if resultDisplay then
			-- Store the result text but keep it hidden
			if result.success then
				local suffix = result.new and " (NEW!)" or ""
				resultDisplay.Text = string.format("YOU GOT: %s%s", result.marbleName or result.marbleId or "?", suffix)
				resultDisplay.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green for success
				print("Stored result display text:", resultDisplay.Text)
			else
				resultDisplay.Text = result.message or "Roll failed"
				resultDisplay.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red for failure
				print("Stored result display text:", resultDisplay.Text)
			end
			-- Keep it hidden - it will be shown when the animation completes
			resultDisplay.Visible = false
		else
			print("ResultDisplay not found in rollAnimationFrame")
		end
	else
		print("rollAnimationFrame not found or not parented")
	end
end

-- Function to initialize the roll animation
function RollAnimation:init(screen)
	self.screen = screen
	print("=== RollAnimation Initialized ===")
end

return RollAnimation
