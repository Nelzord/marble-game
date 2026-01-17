-- 67 marble ability: Creates a big "6" and "7" (7-seg style) next to each other, disappears after 6 seconds
local Ability = {}

-- Services
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

-- Constants (tweak these)
local SEGMENT_THICKNESS = 2         -- thickness of a segment in studs
local SEGMENT_DEPTH = 4             -- depth/thickness (Z) so players can stand on it
local NUMBER_HEIGHT = 20            -- overall digit height
local NUMBER_WIDTH = 12             -- overall digit width
local OBJECT_SPACING = 3            -- spacing between the 6 and 7
local OBJECT_DURATION = 6           -- seconds before they disappear
local SEGMENT_COLOR = Color3.fromRGB(100, 100, 100)

-- Segment naming (classic 7-seg):
--    AAA
--   F   B
--   F   B
--    GGG
--   E   C
--   E   C
--    DDD
local SEGMENTS_FOR_DIGIT = {
	["6"] = {A=true, F=true, E=true, D=true, C=true, G=true}, -- NOTE: B is OFF (this is what makes it a "6")
	["7"] = {A=true, B=true, C=true},
}

local function createPart(size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.Anchored = true
	p.CanCollide = true
	p.CFrame = cf
	p.Parent = Workspace
	
	-- Apply 67 texture to all faces
	local textureId = "rbxassetid://93952266843954"
	for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
		local decal = Instance.new("Decal")
		decal.Texture = textureId
		decal.Face = face
		decal.Parent = p
	end
	
	return p
end

local function digitSegmentCFrames(centerCF: CFrame)
	-- Build 7-seg parts in local 2D (X/Y), extruded in Z.
	-- Use centerCF to orient the digit in world space (including yaw).
	local t = SEGMENT_THICKNESS
	local w = NUMBER_WIDTH
	local h = NUMBER_HEIGHT

	-- lengths of horizontal/vertical bars
	local horizLen = w - t
	local vertLen = (h - 3 * t) / 2

	-- local offsets from center (in digit local space)
	local yTop = (h / 2) - (t / 2)
	local yMid = 0
	local yBot = -(h / 2) + (t / 2)

	local xLeft  = -(w / 2) + (t / 2)
	local xRight =  (w / 2) - (t / 2)

	local yUpper = (h / 4) + (t / 2)
	local yLower = -(h / 4) - (t / 2)

	-- Each entry is: size, localCF
	local seg = {}

	-- A (top)
	seg.A = {
		size = Vector3.new(horizLen, t, SEGMENT_DEPTH),
		localCF = CFrame.new(0, yTop, 0),
	}
	-- D (bottom)
	seg.D = {
		size = Vector3.new(horizLen, t, SEGMENT_DEPTH),
		localCF = CFrame.new(0, yBot, 0),
	}
	-- G (middle)
	seg.G = {
		size = Vector3.new(horizLen, t, SEGMENT_DEPTH),
		localCF = CFrame.new(0, yMid, 0),
	}

	-- B (upper right)
	seg.B = {
		size = Vector3.new(t, vertLen, SEGMENT_DEPTH),
		localCF = CFrame.new(xRight, yUpper, 0),
	}
	-- C (lower right)
	seg.C = {
		size = Vector3.new(t, vertLen, SEGMENT_DEPTH),
		localCF = CFrame.new(xRight, yLower, 0),
	}
	-- F (upper left)
	seg.F = {
		size = Vector3.new(t, vertLen, SEGMENT_DEPTH),
		localCF = CFrame.new(xLeft, yUpper, 0),
	}
	-- E (lower left)
	seg.E = {
		size = Vector3.new(t, vertLen, SEGMENT_DEPTH),
		localCF = CFrame.new(xLeft, yLower, 0),
	}

	-- Convert localCFs into world CFs by multiplying by centerCF
	for k, v in pairs(seg) do
		v.worldCF = centerCF * v.localCF
	end

	return seg
end

local function createDigitModel(digitChar: string, centerCF: CFrame): Model
	local model = Instance.new("Model")
	model.Name = ("Digit%s_%d"):format(digitChar, os.clock() * 1000)
	model.Parent = Workspace

	local onMap = SEGMENTS_FOR_DIGIT[digitChar]
	if not onMap then
		warn(("Unknown digit '%s'"):format(digitChar))
		Debris:AddItem(model, OBJECT_DURATION)
		return model
	end

	local seg = digitSegmentCFrames(centerCF)

	for segName, isOn in pairs(onMap) do
		if isOn and seg[segName] then
			local p = createPart(seg[segName].size, seg[segName].worldCF, SEGMENT_COLOR)
			p.Parent = model
		end
	end

	Debris:AddItem(model, OBJECT_DURATION)
	return model
end

local function groundYBelow(position: Vector3): number
	-- Raycast down to place digits on ground; fallback to current Y.
	local origin = position + Vector3.new(0, 50, 0)
	local dir = Vector3.new(0, -200, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {} -- add character to blacklist at call site if desired

	local hit = Workspace:Raycast(origin, dir, params)
	if hit then
		return hit.Position.Y
	end
	return position.Y
end

function Ability.Description()
	return "67: Creates a big 6 and 7 next to each other that disappear after 6 seconds."
end

function Ability.Cooldown()
	return 10
end

function Ability.ActivateAbility(player: Player, character: Model)
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local look = hrp.CFrame.LookVector
	local right = hrp.CFrame.RightVector

	-- Base position a bit in front of the player
	local basePos = hrp.Position + look * (NUMBER_WIDTH + 6)

	-- Place on ground, then lift by half height so it sits on the floor
	local gy = groundYBelow(basePos)
	local centerY = gy + (NUMBER_HEIGHT / 2)

	-- Face the same direction as the player (yaw only)
	local yawCF = CFrame.lookAt(Vector3.new(0, 0, 0), Vector3.new(look.X, 0, look.Z))

	-- Side-by-side spacing (digit centers)
	local halfGap = (NUMBER_WIDTH + OBJECT_SPACING) / 2
	local pos6 = Vector3.new(basePos.X, centerY, basePos.Z) - right * halfGap
	local pos7 = Vector3.new(basePos.X, centerY, basePos.Z) + right * halfGap

	-- Build center CFrames with orientation
	local cf6 = CFrame.new(pos6) * yawCF.Rotation
	local cf7 = CFrame.new(pos7) * yawCF.Rotation

	-- Create digits (7-seg style: 6 is not "8", 7 is not diagonal)
	createDigitModel("6", cf6)
	createDigitModel("7", cf7)
end

function Ability.DeactivateAbility(player: Player, character: Model)
	-- Nothing to deactivate; debris removes models
end

return Ability
