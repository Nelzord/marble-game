-- Marble rolling controller (client-side)
-- Default Roblox camera; visual marble rotates around player while physics uses linear velocity

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))

local DEBUG = false
local function dprint(...)
	if DEBUG then
		print("[MarbleClient]", ...)
	end
end

local MOVEMENT_DEBUG = false
local function mprint(...)
	if MOVEMENT_DEBUG then
		print("[MarbleMove]", ...)
	end
end

local inputState = {
	forward = 0,
	right = 0,
}

local boundCharacters: { [Model]: boolean } = {}

local baseSpeed = 24 -- movement magnitude; abilities can scale via SpeedMultiplier

local function getMoveDirection(camera: Camera): Vector3
	local cf = camera.CFrame
	local forward = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if forward.Magnitude > 0 then forward = forward.Unit end
	local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
	if right.Magnitude > 0 then right = right.Unit end
	local dir = forward * inputState.forward + right * inputState.right
	if dir.Magnitude > 1 then dir = dir.Unit end
	return dir
end

local function bindInputs()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then inputState.forward = 1 end
		if input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then inputState.forward = -1 end
		if input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then inputState.right = 1 end
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then inputState.right = -1 end
	end)
	UserInputService.InputEnded:Connect(function(input, _processed)
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then if inputState.forward == 1 then inputState.forward = 0 end end
		if input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then if inputState.forward == -1 then inputState.forward = 0 end end
		if input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then if inputState.right == 1 then inputState.right = 0 end end
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then if inputState.right == -1 then inputState.right = 0 end end
	end)
end

local function waitForHRP(character: Model, timeoutSeconds: number?): BasePart?
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	local ok = character:WaitForChild("HumanoidRootPart", timeoutSeconds or 5)
	if ok and ok:IsA("BasePart") then
		return ok
	end
	return nil
end

local function ensureCosmeticBall(character: Model, hrp: BasePart): BasePart
	local existing = character:FindFirstChild("CosmeticBall")
	if existing and existing:IsA("BasePart") then
		return existing
	end
	local ball = Instance.new("Part")
	ball.Name = "CosmeticBall"
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.SmoothPlastic
	ball.Color = Color3.fromRGB(230, 230, 230)
	ball.Size = hrp.Size
	ball.CanCollide = false
	ball.Massless = true
	ball.Anchored = false
	ball.Parent = character
	return ball
end

local function applyCosmeticColorFromEquipped(character: Model, cosmetic: BasePart)
	local id = character:GetAttribute("EquippedMarbleId")
	dprint("applyCosmeticColor", id)
	if type(id) ~= "string" then return end
	local def = Marbles.getById(id)
	if def and def.color then
		cosmetic.Color = def.color
	else
		cosmetic.Color = Color3.fromRGB(230,230,230)
	end
end

local function applyCosmeticTexturesFromEquipped(character: Model, cosmetic: BasePart)
	local id = character:GetAttribute("EquippedMarbleId")
	dprint("applyCosmeticTextures", id)
	if type(id) ~= "string" then return end
	local texturesRoot = ReplicatedStorage:FindFirstChild("MarbleTextures")
	local folder = texturesRoot and texturesRoot:FindFirstChild(id) or nil
	-- Clear existing
	for _, ch in ipairs(cosmetic:GetChildren()) do
		if ch:IsA("Decal") or ch:IsA("Texture") then ch:Destroy() end
	end
	local assets = {}
	if folder then
		for _, inst in ipairs(folder:GetChildren()) do
			if inst:IsA("Decal") or inst:IsA("Texture") then
				table.insert(assets, inst)
			end
		end
	end
	local DEFAULT_DECALS: { [string]: string } = {
		Default = "rbxassetid://110926540048461",
		Red = "rbxassetid://99977275020564",
		Green = "rbxassetid://114474679212927",
		Blue = "rbxassetid://128223600665334",
	}
	if #assets == 0 then
		local fallback = DEFAULT_DECALS[id]
		dprint("no assets found; using fallback?", fallback ~= nil)
		if fallback then
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local d = Instance.new("Decal")
				d.Texture = fallback
				d.Face = face
				d.Parent = cosmetic
			end
		end
		return
	end
	dprint("found", #assets, "assets for", id)
	if #assets == 1 then
		local src = assets[1]
		for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
			local clone = src:Clone()
			if clone:IsA("Decal") then
				(clone :: Decal).Face = face
			elseif clone:IsA("Texture") then
				(clone :: Texture).Face = face
			end
			clone.Parent = cosmetic
		end
		return
	end
	for _, src in ipairs(assets) do
		local clone = src:Clone()
		clone.Parent = cosmetic
	end
end

local function muteFootstepsLocal(character: Model)
	local function handleDescendant(descendant: Instance)
		if descendant:IsA("Sound") then
			local n = descendant.Name
			if n == "Running" or n == "Run" or n == "Footsteps" or n == "Jumping" or n == "Jump" then
				descendant.Volume = 0
				descendant.Playing = false
			end
		elseif (descendant:IsA("LocalScript") or descendant:IsA("Script")) and descendant.Name == "RbxCharacterSounds" then
			descendant:Destroy()
		end
	end
	for _, d in ipairs(character:GetDescendants()) do
		handleDescendant(d)
	end
	character.DescendantAdded:Connect(handleDescendant)
end

local function setupNameplateScaling(character: Model)
	local gui = character:FindFirstChild("Nameplate")
	if not gui or not gui:IsA("BillboardGui") then return end
	local basePixels = 180 -- must match server base width
	local baseDistance = 25 -- distance at which the size equals basePixels
	local minScale = 0.6
	local maxScale = 1.2
	local cam = workspace.CurrentCamera

	local function update()
		if not cam then cam = workspace.CurrentCamera end
		local adornee = gui.Adornee
		if not adornee or not adornee.Parent then return end
		local camPos = cam and cam.CFrame.Position or Vector3.zero
		local dist = (adornee.Position - camPos).Magnitude
		local scale = math.clamp(baseDistance / dist, minScale, maxScale)
		gui.Size = UDim2.fromOffset(basePixels * scale, 36 * scale)
	end

	update()
	RunService.RenderStepped:Connect(update)
end

local function setupController(character: Model)
	if boundCharacters[character] then return end
	dprint("setupController for", character)

	local hrp = waitForHRP(character, 5)
	if not hrp then
		local conn
		conn = character.ChildAdded:Connect(function(child)
			if child.Name == "HumanoidRootPart" and child:IsA("BasePart") then
				conn:Disconnect()
				setupController(character)
			end
		end)
		return
	end
	boundCharacters[character] = true

	-- Ensure default Roblox camera follows Humanoid
	local hum = character:FindFirstChildOfClass("Humanoid")
	local cam = workspace.CurrentCamera
	if cam and hum then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
	end

	-- Make physical root invisible; cosmetic ball will be visible
	hrp.Transparency = 1

	-- Create visual marble that we rotate for effect
	local cosmetic = ensureCosmeticBall(character, hrp)
	applyCosmeticColorFromEquipped(character, cosmetic)
	applyCosmeticTexturesFromEquipped(character, cosmetic)
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(function()
		applyCosmeticColorFromEquipped(character, cosmetic)
		applyCosmeticTexturesFromEquipped(character, cosmetic)
	end)

	-- Mute default character running/jump sounds for this character
	muteFootstepsLocal(character)

	-- Keep nameplate a constant on-screen size
	setupNameplateScaling(character)

	-- Track orientation for cosmetic rolling
	local visualCFrame = CFrame.new()
	local lastPos = hrp.Position

	local function getSpeedMultiplier(): number
		local mult = character:GetAttribute("SpeedMultiplier")
		return typeof(mult) == "number" and mult or 1
	end

	local logAccum = 0
	local prevIsInput = false
	local glideHoriz = Vector3.zero
	local stepConn
	stepConn = RunService.RenderStepped:Connect(function(dt)
		if not hrp or not hrp.Parent then
			if stepConn then stepConn:Disconnect() end
			return
		end

		-- Physics movement via linear velocity (horizontal only)
		local cameraNow = workspace.CurrentCamera
		local dir = cameraNow and getMoveDirection(cameraNow) or Vector3.zero
		local speed = baseSpeed * getSpeedMultiplier()
		local targetHoriz = dir * speed
		local currentVel = hrp.AssemblyLinearVelocity
		local horiz = Vector3.new(currentVel.X, 0, currentVel.Z)

		-- Deceleration-only: instant target when input; otherwise, glide velocity decays
		local isInput = targetHoriz.Magnitude > 0.01
		local wrote = false
		if isInput then
			local newHoriz = targetHoriz
			if newHoriz.Magnitude < 0.0001 then newHoriz = Vector3.zero end
			glideHoriz = newHoriz
			hrp.AssemblyLinearVelocity = Vector3.new(newHoriz.X, currentVel.Y, newHoriz.Z)
			wrote = true
		else
			-- Decay glide horizontally to simulate ice friction
			local baseFactor = 0.985 -- per 60fps frame
			local frames = math.clamp(dt * 60, 0, 5)
			local reduce = character:GetAttribute("FrictionReduction")
			local reduction = (typeof(reduce) == "number" and reduce or 0)
			local perFrame = 1 - (1 - baseFactor) * (1 - reduction)
			local factor = perFrame ^ frames
			glideHoriz = glideHoriz * factor
			if glideHoriz.Magnitude < 0.001 then
				glideHoriz = Vector3.zero
			end
			if glideHoriz ~= Vector3.zero then
				hrp.AssemblyLinearVelocity = Vector3.new(glideHoriz.X, currentVel.Y, glideHoriz.Z)
				wrote = true
			end
		end

		-- Movement debug logs (rate-limited)
		logAccum += dt
		if MOVEMENT_DEBUG and logAccum >= 0.5 then
			logAccum = 0
			local mat = hrp.Material
			local props = hrp.CustomPhysicalProperties
			local friction, fw
			pcall(function()
				friction = props and (props :: any).Friction or nil
				fw = props and (props :: any).FrictionWeight or nil
			end)
			mprint(string.format("input=%s wroteVel=%s horiz=%.2f target=%.2f glide=%.2f mat=%s fric=%s fw=%s", tostring(isInput), tostring(wrote), horiz.Magnitude, targetHoriz.Magnitude, glideHoriz.Magnitude, tostring(mat), tostring(friction), tostring(fw)))
		end
		if isInput ~= prevIsInput then
			prevIsInput = isInput
			mprint("input state changed:", isInput and "START" or "STOP")
		end

		-- Update cosmetic rotation to match traveled distance
		local currentPos = hrp.Position
		local deltaPos = currentPos - lastPos
		lastPos = currentPos
		local deltaXZ = Vector3.new(deltaPos.X, 0, deltaPos.Z)
		local dist = deltaXZ.Magnitude
		if dist > 0.0001 then
			local radius = (hrp.Size.X + hrp.Size.Y + hrp.Size.Z) / 6
			if radius <= 0 then radius = 2 end
			local angle = dist / radius
			local moveDir = deltaXZ.Unit
			local axis = Vector3.new(moveDir.Z, 0, -moveDir.X)
			visualCFrame = CFrame.fromAxisAngle(axis, angle) * visualCFrame
		end
		cosmetic.CFrame = CFrame.new(hrp.Position) * visualCFrame
	end)

	character.AncestryChanged:Connect(function(_, parent)
		if not parent and stepConn then
			stepConn:Disconnect()
		end
	end)
end

local function onCharacterAdded(character: Model)
	setupController(character)
end

bindInputs()

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded) 