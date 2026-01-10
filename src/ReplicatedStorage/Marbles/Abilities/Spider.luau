-- Spider marble ability: spawns spider webs that players can pass through with movement benefits
local Ability = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Constants
local WEB_DURATION = 10 -- seconds the webs should exist
local WEB_COUNT = 6 -- Number of webs to spawn
local WEB_SIZE = Vector3.new(8, 20, 8) -- Width, Height, Depth
local WEB_SPAWN_RADIUS = 12 -- Radius around player to spawn webs
local WEB_FORCE = 40 -- Force applied to push marbles up when in web
local WEB_RADIUS = 6 -- Radius to check for marbles to push
local ABILITY_COOLDOWN = 6 -- 6 second cooldown (shorter than web duration)

function Ability.Description()
	return "Spider: Spawns spider webs you can pass through with enhanced movement."
end

function Ability.Cooldown()
	return ABILITY_COOLDOWN
end

-- Helper: get (or create) the folder that holds references to webs
local function getOrCreateWebFolder(character: Model)
	local folder = character:FindFirstChild("SpiderWebFolder")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SpiderWebFolder"
		folder.Archivable = false
		folder.Parent = character
	end
	return folder
end

-- Helper: find marbles within radius of a position
local function findMarblesInRadius(position: Vector3, radius: number): {BasePart}
	local marbles = {}
	
	-- Check all players' characters
	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if character and character:GetAttribute("IsMarbleCharacter") then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				local distance = (hrp.Position - position).Magnitude
				if distance <= radius then
					table.insert(marbles, hrp)
				end
			end
		end
	end
	
	return marbles
end

-- Helper: apply force along web strands to marbles
local function pushMarblesAlongWebs(webModel: Model, force: number)
	-- Check all players' characters
	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if character and character:GetAttribute("IsMarbleCharacter") then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				local playerPos = hrp.Position
				
				-- Check each web strand in the web model
				for _, strand in ipairs(webModel:GetDescendants()) do
					if strand:IsA("BasePart") and strand.Name == "WebStrand" then
						-- Calculate distance from player to strand
						local strandStart = strand.CFrame.Position - strand.CFrame.LookVector * (strand.Size.Z / 2)
						local strandEnd = strand.CFrame.Position + strand.CFrame.LookVector * (strand.Size.Z / 2)
						
						-- Find closest point on strand to player
						local strandDir = (strandEnd - strandStart).Unit
						local toPlayer = playerPos - strandStart
						local projection = math.max(0, math.min(strand.Size.Z, toPlayer:Dot(strandDir)))
						local closestPoint = strandStart + strandDir * projection
						
						local distanceToStrand = (playerPos - closestPoint).Magnitude
						
						-- If player is close to this strand
						if distanceToStrand <= WEB_RADIUS then
							-- Calculate direction along the strand (upward component)
							local strandUpward = math.max(0, strandDir.Y) -- Only use upward component
							if strandUpward > 0.1 then -- Only push if strand goes upward
								-- Apply force along the strand direction (with emphasis on upward)
								local pushDirection = strandDir
								-- Emphasize upward movement
								pushDirection = Vector3.new(
									pushDirection.X * 0.3,
									math.max(pushDirection.Y, 0.7), -- Strong upward push
									pushDirection.Z * 0.3
								).Unit
								
								local bodyVelocity = Instance.new("BodyVelocity")
								bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
								bodyVelocity.Velocity = pushDirection * force
								bodyVelocity.Parent = hrp
								
								-- Remove the BodyVelocity after a short time
								Debris:AddItem(bodyVelocity, 0.2)
								break -- Only apply force from one strand at a time
							end
						end
					end
				end
			end
		end
	end
end

-- Helper function to create web strands
local function createWebStrand(startPos: Vector3, endPos: Vector3, thickness: number): Part
	local strand = Instance.new("Part")
	strand.Name = "WebStrand"
	strand.Material = Enum.Material.Neon
	strand.Color = Color3.fromRGB(255, 255, 255) -- White web
	strand.Transparency = 0.3
	strand.Anchored = true
	strand.CanCollide = false
	
	local distance = (endPos - startPos).Magnitude
	strand.Size = Vector3.new(thickness, thickness, distance)
	strand.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance/2)
	
	return strand
end

-- Helper function to create a spider web (web-like appearance with strands)
local function createSpiderWeb(position: Vector3): Model
	local webModel = Instance.new("Model")
	webModel.Name = "SpiderWeb"
	
	-- Create center point
	local center = position
	local radius = WEB_SIZE.X / 2
	local height = WEB_SIZE.Y
	
	-- Create radial strands (from center outward)
	local radialStrandCount = 8
	for i = 1, radialStrandCount do
		local angle = (i / radialStrandCount) * math.pi * 2
		local endX = center.X + math.cos(angle) * radius
		local endZ = center.Z + math.sin(angle) * radius
		local endY = center.Y + math.random(-height/4, height/4)
		
		local strand = createWebStrand(
			center,
			Vector3.new(endX, endY, endZ),
			0.2
		)
		strand.Parent = webModel
	end
	
	-- Create spiral strands (web pattern)
	local spiralCount = 4
	for i = 1, spiralCount do
		local spiralAngle = (i / spiralCount) * math.pi * 2
		local points = 6
		for j = 1, points do
			local progress = j / points
			local currentRadius = radius * progress
			local currentX = center.X + math.cos(spiralAngle + progress * math.pi * 2) * currentRadius
			local currentZ = center.Z + math.sin(spiralAngle + progress * math.pi * 2) * currentRadius
			local currentY = center.Y + math.sin(progress * math.pi) * (height * 0.3)
			
			if j > 1 then
				local prevX = center.X + math.cos(spiralAngle + (j-1)/points * math.pi * 2) * (radius * (j-1)/points)
				local prevZ = center.Z + math.sin(spiralAngle + (j-1)/points * math.pi * 2) * (radius * (j-1)/points)
				local prevY = center.Y + math.sin((j-1)/points * math.pi) * (height * 0.3)
				
				local strand = createWebStrand(
					Vector3.new(prevX, prevY, prevZ),
					Vector3.new(currentX, currentY, currentZ),
					0.15
				)
				strand.Parent = webModel
			end
		end
	end
	
	-- Create vertical strands for height (these are the main climbing strands)
	local verticalStrandCount = 8
	for i = 1, verticalStrandCount do
		local angle = (i / verticalStrandCount) * math.pi * 2
		local baseX = center.X + math.cos(angle) * radius * 0.6
		local baseZ = center.Z + math.sin(angle) * radius * 0.6
		local baseY = center.Y - height/2
		local topY = center.Y + height/2
		
		local strand = createWebStrand(
			Vector3.new(baseX, baseY, baseZ),
			Vector3.new(baseX, topY, baseZ),
			0.25 -- Slightly thicker for main climbing strands
		)
		strand.Parent = webModel
	end
	
	-- Create invisible collision/force area (like Blue geyser)
	local forceArea = Instance.new("Part")
	forceArea.Name = "WebForceArea"
	forceArea.Material = Enum.Material.ForceField
	forceArea.Color = Color3.fromRGB(255, 255, 255)
	forceArea.Size = WEB_SIZE
	forceArea.Transparency = 1 -- Completely invisible
	forceArea.Anchored = true
	forceArea.CanCollide = false -- Players can pass through
	forceArea.CFrame = CFrame.new(position.X, position.Y + WEB_SIZE.Y / 2, position.Z)
	forceArea.Parent = webModel
	
	-- Add web particles around the force area
	local attachment = Instance.new("Attachment")
	attachment.Parent = forceArea
	
	local webEmitter = Instance.new("ParticleEmitter")
	webEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	webEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	webEmitter.Size = NumberSequence.new(0.1, 0.2)
	webEmitter.Transparency = NumberSequence.new(0.6, 1)
	webEmitter.Rate = 20
	webEmitter.Lifetime = NumberRange.new(1, 2)
	webEmitter.Speed = NumberRange.new(0.5, 2)
	webEmitter.SpreadAngle = Vector2.new(360, 360)
	webEmitter.Parent = attachment
	
	-- Add subtle web glow
	local webLight = Instance.new("PointLight")
	webLight.Color = Color3.fromRGB(255, 255, 200)
	webLight.Range = 15
	webLight.Brightness = 0.8
	webLight.Parent = forceArea
	
	webModel.Parent = workspace
	return forceArea -- Return the force area for pushing logic
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("SPIDER ABILITY: Activating for player:", player.Name)
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("SPIDER ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local playerPosition = humanoidRootPart.Position
	
	-- Create webs around the player
	local folder = getOrCreateWebFolder(character)
	local spawnedWebs = {}
	
	for i = 1, WEB_COUNT do
		local angle = (i / WEB_COUNT) * math.pi * 2
		local radius = math.random(WEB_SPAWN_RADIUS * 0.6, WEB_SPAWN_RADIUS)
		local webX = playerPosition.X + math.cos(angle) * radius
		local webZ = playerPosition.Z + math.sin(angle) * radius
		local webY = playerPosition.Y + math.random(-3, 3)
		
		local webPosition = Vector3.new(webX, webY, webZ)
		local webForceArea = createSpiderWeb(webPosition)
		local webModel = webForceArea.Parent -- Get the model
		
		-- Store reference to the model
		local ref = Instance.new("ObjectValue")
		ref.Name = ("Web_%s"):format(tick() + i)
		ref.Value = webModel
		ref.Parent = folder
		
		table.insert(spawnedWebs, webForceArea) -- Store force area for pushing logic
		
		-- Start pushing mechanism for this web (push along individual strands)
		local pushConnection
		local function startPushing()
			pushConnection = RunService.Heartbeat:Connect(function()
				if webModel and webModel.Parent then
					pushMarblesAlongWebs(webModel, WEB_FORCE)
				else
					if pushConnection then
						pushConnection:Disconnect()
						pushConnection = nil
					end
				end
			end)
		end
		
		startPushing()
		
		-- Clean up pushing connection after web duration
		task.delay(WEB_DURATION, function()
			if pushConnection then
				pushConnection:Disconnect()
				pushConnection = nil
			end
		end)
	end
	
	-- Schedule automatic cleanup - destroy web models after WEB_DURATION
	task.delay(WEB_DURATION, function()
		print("SPIDER ABILITY: Cleaning up webs after", WEB_DURATION, "seconds")
		
		-- Fade out and destroy all web models
		for _, ref in pairs(folder:GetChildren()) do
			if ref:IsA("ObjectValue") and ref.Value then
				local webModel = ref.Value
				if webModel and webModel.Parent then
					-- Fade out all parts in the web model
					for _, part in ipairs(webModel:GetDescendants()) do
						if part:IsA("BasePart") then
							local fadeTween = TweenService:Create(part, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
								Transparency = 1
							})
							fadeTween:Play()
						end
						if part:IsA("PointLight") then
							local lightTween = TweenService:Create(part, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
								Brightness = 0
							})
							lightTween:Play()
						end
					end
					
					-- Destroy after fade
					task.delay(1.5, function()
						if webModel and webModel.Parent then
							webModel:Destroy()
						end
					end)
				end
				ref:Destroy()
			end
		end
	end)
	
	print("SPIDER ABILITY: Activation complete - Web duration:", WEB_DURATION, "seconds, Cooldown:", Ability.Cooldown(), "seconds")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("SPIDER ABILITY: Deactivating for player:", player.Name)
	
	if not character then
		return
	end
	
	-- Remove all webs immediately if they exist
	local folder = character:FindFirstChild("SpiderWebFolder")
	if folder then
		for _, ref in pairs(folder:GetChildren()) do
			if ref:IsA("ObjectValue") and ref.Value then
				if ref.Value.Parent then
					print("SPIDER ABILITY: Removing web immediately")
					ref.Value:Destroy()
				end
			end
		end
		folder:Destroy()
	end
end

return Ability
