-- TimeTravel ability module: Allows the marble to go back in time 5 seconds
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ability = {}

-- State tracking for active time travel effects
local activeTimeTravels: { [Player]: boolean } = {}
local playerPositions: { [Player]: { [number]: Vector3 } } = {} -- Store positions over time
local positionHistorySize = 300 -- Store 5 seconds of positions at 60fps

function Ability.Description()
	return "TimeTravel: Go back in time 5 seconds to your previous position."
end

function Ability.Cooldown()
	return 7.5 -- 7.5 second cooldown (twice as quick as before)
end

function Ability.ActivateAbility(player: Player, character: Model)
	if activeTimeTravels[player] then 
		return 
	end
	
	activeTimeTravels[player] = true
	
	-- Get the player's position history
	local positions = playerPositions[player]
	if not positions or #positions == 0 then
		-- No history available, can't time travel
		activeTimeTravels[player] = false
		return
	end
	
	-- Find the position from 5 seconds ago (approximately 300 frames at 60fps)
	local targetIndex = math.max(1, #positions - 300)
	local targetPosition = positions[targetIndex]
	
			if targetPosition then
			-- Teleport the player back in time
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				-- Create a black/white time travel effect
				local timeTravelEffect = Instance.new("Part")
				timeTravelEffect.Shape = Enum.PartType.Ball
				timeTravelEffect.Size = Vector3.new(10, 10, 10)
				timeTravelEffect.Position = hrp.Position
				timeTravelEffect.Anchored = true
				timeTravelEffect.CanCollide = false
				timeTravelEffect.Material = Enum.Material.Neon
				timeTravelEffect.Color = Color3.fromRGB(255, 255, 255) -- White
				timeTravelEffect.Transparency = 0.2
				timeTravelEffect.Parent = workspace
				
				-- Create flying numbers effect
				local numbers = {"5", "4", "3", "2", "1", "0", "∞", "⏰", "⏱️", "⏲️"}
				for i = 1, 8 do
					local number = Instance.new("Part")
					number.Shape = Enum.PartType.Ball
					number.Size = Vector3.new(1, 1, 1)
					number.Position = hrp.Position + Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))
					number.Anchored = true
					number.CanCollide = false
					number.Material = Enum.Material.Neon
					number.Color = i % 2 == 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0) -- Alternating black/white
					number.Transparency = 0.1
					number.Parent = workspace
					
					-- Add a SurfaceGui with the number text
					local surfaceGui = Instance.new("SurfaceGui")
					surfaceGui.Face = Enum.NormalId.Front
					surfaceGui.Parent = number
					
					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.new(1, 0, 1, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.Text = numbers[math.random(1, #numbers)]
					textLabel.TextColor3 = i % 2 == 0 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255) -- Opposite color for contrast
					textLabel.TextScaled = true
					textLabel.Font = Enum.Font.SourceSansBold
					textLabel.Parent = surfaceGui
					
					-- Animate the number flying outward
					local randomDirection = Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)).Unit
					local targetPosition = number.Position + (randomDirection * 15)
					
					local tween = game:GetService("TweenService"):Create(number, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = targetPosition,
						Transparency = 1,
						Size = Vector3.new(0.5, 0.5, 0.5)
					})
					
					tween:Play()
					tween.Completed:Connect(function()
						number:Destroy()
					end)
				end
				
				-- Animate the main effect
				local tween = game:GetService("TweenService"):Create(timeTravelEffect, TweenInfo.new(0.8), {
					Size = Vector3.new(25, 25, 25),
					Transparency = 1
				})
				
				-- Teleport and clean up
				tween:Play()
				tween.Completed:Connect(function()
					timeTravelEffect:Destroy()
				end)
				
				-- Teleport to the historical position
				hrp.CFrame = CFrame.new(targetPosition)
				
				-- Clear position history after time travel
				playerPositions[player] = {}
			end
		end
	
	-- Reset active state
	activeTimeTravels[player] = false
end

function Ability.DeactivateAbility(player: Player, character: Model)
	activeTimeTravels[player] = nil
end

-- Function to record player positions (called from server)
function Ability.RecordPosition(player: Player, position: Vector3)
	if not playerPositions[player] then
		playerPositions[player] = {}
	end
	
	local positions = playerPositions[player]
	table.insert(positions, position)
	
	-- Keep only the last 5 seconds of positions
	if #positions > positionHistorySize then
		table.remove(positions, 1)
	end
end

-- Function to get stored positions (for server use)
function Ability.GetStoredPositions(player: Player): { Vector3 }?
	return playerPositions[player]
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	activeTimeTravels[player] = nil
	playerPositions[player] = nil
end)

return Ability
