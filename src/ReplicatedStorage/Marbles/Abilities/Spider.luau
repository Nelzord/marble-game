-- Spider marble ability: web grappling
local Ability = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants
local WEB_RANGE = 100
local WEB_SPEED = 80
local GRAPPLE_SPEED = 120
local WEB_DURATION = 5

function Ability.Description()
	return "Spider: Shoot a web to grapple and swing toward targets."
end

function Ability.Cooldown()
	return 8 -- 8 second cooldown
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("SPIDER ABILITY LOG: Activating Spider marble ability for player:", player.Name)
	print("SPIDER ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	print("SPIDER ABILITY LOG: Cooldown duration:", Ability.Cooldown(), "seconds")
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("SPIDER ABILITY LOG: No character or HumanoidRootPart found, aborting")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	
	if not humanoidRootPart or not humanoid then
		print("SPIDER ABILITY LOG: No HumanoidRootPart or Humanoid found, aborting")
		return
	end
	
	print("SPIDER ABILITY LOG: Character components found, checking grappling state")
	
	-- Check if already grappling
	if character:GetAttribute("IsGrappling") then
		print("SPIDER ABILITY LOG: Already grappling, returning early")
		return
	end
	
	print("SPIDER ABILITY LOG: Not grappling, proceeding with web creation")
	
	-- Get mouse hit position for web target - handle safely
	local targetPosition
	local success, result = pcall(function()
		local mouse = player:GetMouse()
		if mouse and mouse.Hit then
			return mouse.Hit.Position
		else
			-- Fallback: shoot web forward from character
			return humanoidRootPart.Position + (humanoidRootPart.CFrame.LookVector * WEB_RANGE)
		end
	end)
	
	if success and result then
		targetPosition = result
		print("SPIDER ABILITY LOG: Got mouse target position:", targetPosition)
	else
		-- Fallback: shoot web forward from character
		targetPosition = humanoidRootPart.Position + (humanoidRootPart.CFrame.LookVector * WEB_RANGE)
		print("SPIDER ABILITY LOG: Using fallback target position:", targetPosition)
	end
	
	-- Calculate distance to target
	local distance = (targetPosition - humanoidRootPart.Position).Magnitude
	print("SPIDER ABILITY LOG: Distance to target:", distance, "Max range:", WEB_RANGE)
	
	if distance > WEB_RANGE then
		-- Target too far, adjust to max range
		local direction = (targetPosition - humanoidRootPart.Position).Unit
		targetPosition = humanoidRootPart.Position + (direction * WEB_RANGE)
		distance = WEB_RANGE
		print("SPIDER ABILITY LOG: Adjusted target to max range:", distance)
	end
	
	print("SPIDER ABILITY LOG: Creating web visual effect")
	
	-- Create web visual effect
	local web = Instance.new("Part")
	web.Name = "SpiderWeb"
	web.Material = Enum.Material.Fabric
	web.Color = Color3.fromRGB(255, 255, 255)
	web.Transparency = 0.3
	web.Anchored = true
	web.CanCollide = false
	web.Size = Vector3.new(0.1, 0.1, distance)
	web.CFrame = CFrame.lookAt(humanoidRootPart.Position, targetPosition) * CFrame.new(0, 0, -distance/2)
	web.Parent = workspace
	
	print("SPIDER ABILITY LOG: Web created, creating attachment")
	
	-- Create web attachment at target
	local webAttachment = Instance.new("Part")
	webAttachment.Name = "WebAttachment"
	webAttachment.Material = Enum.Material.Fabric
	webAttachment.Color = Color3.fromRGB(255, 255, 255)
	webAttachment.Transparency = 0.2
	webAttachment.Anchored = true
	webAttachment.CanCollide = false
	webAttachment.Size = Vector3.new(2, 2, 2)
	webAttachment.Shape = Enum.PartType.Ball
	webAttachment.Position = targetPosition
	webAttachment.Parent = workspace
	
	print("SPIDER ABILITY LOG: Setting grappling state")
	
	-- Set grappling state
	character:SetAttribute("IsGrappling", true)
	character:SetAttribute("WebTarget", targetPosition)
	
	-- Grapple toward the web
	local grappleStartTime = tick()
	local grappleDuration = distance / GRAPPLE_SPEED
	
	print("SPIDER ABILITY LOG: Starting grapple movement, duration:", grappleDuration)
	
	-- Create connection for smooth grappling movement
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		-- Safety check: ensure character still exists and is valid
		if not character or not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
			if connection then 
				connection:Disconnect() 
				connection = nil
			end
			return
		end
		
		-- Safety check: ensure humanoid root part is still valid
		local currentHRP = character:FindFirstChild("HumanoidRootPart")
		if not currentHRP or not currentHRP.Parent then
			if connection then 
				connection:Disconnect() 
				connection = nil
			end
			return
		end
		
		local elapsed = tick() - grappleStartTime
		local progress = math.min(elapsed / grappleDuration, 1)
		
		-- Smooth easing function for natural movement
		local easedProgress = 1 - (1 - progress) * (1 - progress)
		
		-- Calculate new position
		local startPos = currentHRP.Position
		local endPos = targetPosition
		local newPos = startPos:Lerp(endPos, easedProgress)
		
		-- Move character safely
		pcall(function()
			currentHRP.CFrame = CFrame.new(newPos)
		end)
		
		-- Check if grapple is complete
		if progress >= 1 then
			if connection then 
				connection:Disconnect() 
				connection = nil
			end
			character:SetAttribute("IsGrappling", false)
			character:SetAttribute("WebTarget", nil)
			
			print("SPIDER ABILITY LOG: Grapple complete, cleaning up web")
			
			-- Clean up web after delay
			task.delay(WEB_DURATION, function()
				if web and web.Parent then
					web:Destroy()
				end
				if webAttachment and webAttachment.Parent then
					webAttachment:Destroy()
				end
			end)
		end
	end)
	
	print("SPIDER ABILITY LOG: Grapple connection created, setting cleanup timer")
	
	-- Clean up web if ability is deactivated early
	task.delay(WEB_DURATION, function()
		if web and web.Parent then
			web:Destroy()
		end
		if webAttachment and webAttachment.Parent then
			webAttachment:Destroy()
		end
	end)
	
	print("SPIDER ABILITY LOG: Spider ability activation complete")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	if character then
		character:SetAttribute("IsGrappling", false)
		character:SetAttribute("WebTarget", nil)
	end
end

return Ability 