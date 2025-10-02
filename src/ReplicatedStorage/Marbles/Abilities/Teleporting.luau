-- Teleporting ability module: Teleports the marble upward in the air
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ability = {}

-- State tracking for active teleporting effects
local activeTeleports: { [Player]: boolean } = {}

function Ability.Description()
	return "Teleporting: Teleport upward in the air to gain height advantage."
end

function Ability.Cooldown()
	return 8 -- 8 second cooldown
end

function Ability.ActivateAbility(player: Player, character: Model)
	if activeTeleports[player] then 
		return 
	end
	
	activeTeleports[player] = true
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		-- Create a teleportation effect
		local teleportEffect = Instance.new("Part")
		teleportEffect.Shape = Enum.PartType.Ball
		teleportEffect.Size = Vector3.new(8, 8, 8)
		teleportEffect.Position = hrp.Position
		teleportEffect.Anchored = true
		teleportEffect.CanCollide = false
		teleportEffect.Material = Enum.Material.Neon
		teleportEffect.Color = Color3.fromRGB(100, 200, 255) -- Blue teleportation color
		teleportEffect.Transparency = 0.3
		teleportEffect.Parent = workspace
		
		-- Create teleportation particles effect
		local particles = {"✨", "⭐", "💫", "🌟", "⚡", "🔮", "💎", "🌀"}
		for i = 1, 6 do
			local particle = Instance.new("Part")
			particle.Shape = Enum.PartType.Ball
			particle.Size = Vector3.new(0.8, 0.8, 0.8)
			particle.Position = hrp.Position + Vector3.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
			particle.Anchored = true
			particle.CanCollide = false
			particle.Material = Enum.Material.Neon
			particle.Color = Color3.fromRGB(math.random(100, 255), math.random(100, 255), 255) -- Random blue-ish colors
			particle.Transparency = 0.2
			particle.Parent = workspace
			
			-- Add a SurfaceGui with the particle emoji
			local surfaceGui = Instance.new("SurfaceGui")
			surfaceGui.Face = Enum.NormalId.Front
			surfaceGui.Parent = particle
			
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.Text = particles[math.random(1, #particles)]
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			textLabel.TextScaled = true
			textLabel.Font = Enum.Font.SourceSansBold
			textLabel.Parent = surfaceGui
			
			-- Animate the particle flying outward
			local randomDirection = Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)).Unit
			local targetPosition = particle.Position + (randomDirection * 12)
			
			local tween = game:GetService("TweenService"):Create(particle, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = targetPosition,
				Transparency = 1,
				Size = Vector3.new(0.3, 0.3, 0.3)
			})
			
			tween:Play()
			tween.Completed:Connect(function()
				particle:Destroy()
			end)
		end
		
		-- Animate the main effect
		local tween = game:GetService("TweenService"):Create(teleportEffect, TweenInfo.new(0.6), {
			Size = Vector3.new(20, 20, 20),
			Transparency = 1
		})
		
		-- Teleport upward and clean up
		tween:Play()
		tween.Completed:Connect(function()
			teleportEffect:Destroy()
		end)
		
		-- Calculate teleportation height (teleport 20 studs upward)
		local teleportHeight = 20
		local newPosition = hrp.Position + Vector3.new(0, teleportHeight, 0)
		
		-- Teleport to the new position
		hrp.CFrame = CFrame.new(newPosition)
		
		-- Add a brief upward velocity to make the teleport feel more natural
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
		bodyVelocity.Velocity = Vector3.new(0, 10, 0) -- Small upward push
		bodyVelocity.Parent = hrp
		
		-- Remove the body velocity after a short time
		game:GetService("Debris"):AddItem(bodyVelocity, 0.5)
	end
	
	-- Reset active state
	activeTeleports[player] = false
end

function Ability.DeactivateAbility(player: Player, character: Model)
	activeTeleports[player] = nil
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	activeTeleports[player] = nil
end)

return Ability
