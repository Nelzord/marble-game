-- Jumper marble ability: double jump
local Ability = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants
local JUMP_FORCE = 50 -- Force applied for the double jump
local JUMP_DURATION = 0.3 -- How long the jump effect lasts
local JUMP_COOLDOWN = 3 -- Cooldown between double jumps

function Ability.Description()
	return "Jumper: Press E to perform a double jump when in mid-air."
end

function Ability.Cooldown()
	return JUMP_COOLDOWN -- 3 second cooldown
end

-- Helper function to check if character is in mid-air
local function isInMidAir(character: Model): boolean
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	
	if not humanoidRootPart or not humanoid then
		return false
	end
	
	-- Check if the character is falling or jumping (not on ground)
	return humanoid.FloorMaterial == Enum.Material.Air
end

-- Helper function to apply jump force
local function applyJumpForce(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create BodyVelocity for the jump
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, JUMP_FORCE * 1000, 0)
	bodyVelocity.Velocity = Vector3.new(0, JUMP_FORCE, 0)
	bodyVelocity.Parent = humanoidRootPart
	
	-- Remove the BodyVelocity after the jump duration
	task.delay(JUMP_DURATION, function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
end

-- Helper function to create jump visual effect
local function createJumpEffect(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create a small explosion effect at the character's position
	local explosion = Instance.new("Explosion")
	explosion.Position = humanoidRootPart.Position
	explosion.BlastRadius = 0 -- No damage, just visual
	explosion.BlastPressure = 0 -- No force, just visual
	explosion.Visible = true
	explosion.Parent = workspace
	
	-- Create particle effect
	local attachment = Instance.new("Attachment")
	attachment.Parent = humanoidRootPart
	
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/fire_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0)) -- Yellow particles
	particles.Size = NumberSequence.new(0.2, 0.8)
	particles.Transparency = NumberSequence.new(0.3, 1)
	particles.Rate = 50
	particles.Lifetime = NumberRange.new(0.5, 1.0)
	particles.Speed = NumberRange.new(5, 15)
	particles.SpreadAngle = Vector2.new(45, 45)
	particles.Parent = attachment
	
	-- Clean up particles after effect
	task.delay(1.0, function()
		if particles and particles.Parent then
			particles:Destroy()
		end
		if attachment and attachment.Parent then
			attachment:Destroy()
		end
	end)
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("JUMPER ABILITY LOG: Activating Jumper marble ability for player:", player.Name)
	print("JUMPER ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	print("JUMPER ABILITY LOG: Cooldown duration:", Ability.Cooldown(), "seconds")
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("JUMPER ABILITY LOG: No character or HumanoidRootPart found, aborting")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	
	if not humanoidRootPart or not humanoid then
		print("JUMPER ABILITY LOG: No HumanoidRootPart or Humanoid found, aborting")
		return
	end
	
	-- Check if character is in mid-air (required for double jump)
	if not isInMidAir(character) then
		print("JUMPER ABILITY LOG: Character is not in mid-air, double jump not available")
		return
	end
	
	-- Check if already double jumping (prevent spam)
	if character:GetAttribute("IsDoubleJumping") then
		print("JUMPER ABILITY LOG: Already double jumping, returning early")
		return
	end
	
	print("JUMPER ABILITY LOG: Character is in mid-air, performing double jump")
	
	-- Set double jumping state
	character:SetAttribute("IsDoubleJumping", true)
	
	-- Apply jump force
	applyJumpForce(character)
	
	-- Create visual effect
	createJumpEffect(character)
	
	-- Reset double jumping state after jump duration
	task.delay(JUMP_DURATION, function()
		if character then
			character:SetAttribute("IsDoubleJumping", false)
			print("JUMPER ABILITY LOG: Double jump completed")
		end
	end)
	
	print("JUMPER ABILITY LOG: Jumper ability activation complete")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("JUMPER ABILITY LOG: Deactivating Jumper marble ability for player:", player.Name)
	
	if character then
		-- Reset double jumping state
		character:SetAttribute("IsDoubleJumping", false)
	end
end

return Ability
