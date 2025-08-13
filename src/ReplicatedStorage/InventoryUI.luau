-- InventoryUI.luau
-- Inventory display and management for the Marble Game

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))
local EquipMarble: RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipMarble")

-- UI element variables
local invFrame: Frame? = nil
local list: ScrollingFrame? = nil
local grid: UIGridLayout? = nil

-- State variables
local ownedSet: { [string]: boolean } = {}
local equippedId: string? = nil

local InventoryUI = {}

-- Ability descriptions by module name (simple mapping for now)
local ABILITY_DESCRIPTIONS: { [string]: string } = {
	Default = "No special ability.",
	SpeedBoost = "Temporarily increases rolling speed.",
	Red = "Red: A fiery burst that briefly increases acceleration.",
	Blue = "Blue: A calming shield that reduces deceleration briefly.",
	Green = "Green: A rejuvenating pulse that boosts control for a moment.",
	Spider = "Spider: Shoot a web to grapple and swing toward targets.",
	Gumball = "Gumball: A bouncy marble that can launch high into the air with explosive force.",
}

-- Texture fallbacks (should match controller)
local FALLBACK_DECALS: { [string]: string } = {
	Default = "rbxassetid://110926540048461",
	Red = "rbxassetid://99977275020564",
	Green = "rbxassetid://114474679212927",
	Blue = "rbxassetid://128223600665334",
	Spider = "rbxassetid://105354663033087",
	Gumball = "rbxassetid://92160789193138",
}

-- Function to apply textures to a part
local function applyTexturesToPart(part: BasePart, marbleId: string)
	-- Clear existing
	for _, ch in ipairs(part:GetChildren()) do
		if ch:IsA("Decal") or ch:IsA("Texture") then ch:Destroy() end
	end
	-- Preferred from ReplicatedStorage
	local texturesRoot = ReplicatedStorage:FindFirstChild("MarbleTextures")
	local folder = texturesRoot and texturesRoot:FindFirstChild(marbleId)
	local assets = {}
	if folder then
		for _, inst in ipairs(folder:GetChildren()) do
			if inst:IsA("Decal") or inst:IsA("Texture") then
				table.insert(assets, inst)
			end
		end
	end
	if #assets == 0 then
		local fallback = FALLBACK_DECALS[marbleId]
		if fallback then
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local d = Instance.new("Decal")
				d.Texture = fallback
				d.Face = face
				d.Parent = part
			end
		end
		return
	end
	if #assets == 1 then
		local src = assets[1]
		for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
			local clone = src:Clone()
			if clone:IsA("Decal") then
				(clone :: Decal).Face = face
			elseif clone:IsA("Texture") then
				(clone :: Texture).Face = face
			end
			clone.Parent = part
		end
		return
	end
	for _, src in ipairs(assets) do
		local clone = src:Clone()
		clone.Parent = part
	end
end

-- Function to get rarity text
local function getRarityText(def): string
	if def and def.rollable and def.dropDenominator and def.dropDenominator > 0 then
		return string.format(" (1/%d)", def.dropDenominator)
	end
	return ""
end

-- Function to get rarity only
local function getRarityOnly(def): string
	if def and def.rollable and def.dropDenominator and def.dropDenominator > 0 then
		return string.format("1/%d", def.dropDenominator)
	end
	return ""
end

-- Function to create a marble tile
local function createMarbleTile(def, ownedSet, equippedId)
	local isOwned = ownedSet[def.id] == true
	local isEquipped = def.id == equippedId

	local tile = Instance.new("Frame")
	tile.Size = UDim2.fromOffset(200, 200)
	tile.BackgroundColor3 = isEquipped and Color3.fromRGB(38, 110, 180) or Color3.fromRGB(40, 40, 40)
	tile.BorderSizePixel = 0

	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 8)
	corner2.Parent = tile

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1, -16, 1, -56)
	viewport.Position = UDim2.new(0, 8, 0, 8)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Parent = tile

	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(6, 6, 6)
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.Parent = world

	if isOwned then
		applyTexturesToPart(sphere, def.id)
		if #sphere:GetChildren() == 0 and def.color then
			sphere.Color = def.color
		end
	else
		-- Locked appearance: dark swatch with big question mark
		sphere.Color = Color3.fromRGB(60,60,60)
		local q = Instance.new("BillboardGui")
		q.Size = UDim2.fromOffset(120, 120)
		q.AlwaysOnTop = true
		q.Adornee = sphere
		q.Parent = world
		local ql = Instance.new("TextLabel")
		ql.BackgroundTransparency = 1
		ql.Text = "?"
		ql.TextScaled = true
		ql.Font = Enum.Font.GothamBold
		ql.TextColor3 = Color3.new(1,1,1)
		ql.Size = UDim2.fromScale(1,1)
		ql.Parent = q
	end

	-- Camera
	local cam = Instance.new("Camera")
	viewport.CurrentCamera = cam
	cam.Parent = viewport
	local center = Vector3.new(0, 0, 0)
	sphere.Position = center
	cam.CFrame = CFrame.new(center + Vector3.new(0, 0, 12), center)

	-- Name or rarity label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, -16, 0, 16)
	nameLabel.Position = UDim2.new(0, 8, 1, -44)
	nameLabel.Text = isOwned and (def.name .. getRarityText(def)) or getRarityOnly(def)
	nameLabel.TextColor3 = Color3.new(1,1,1)
	nameLabel.TextScaled = true
	nameLabel.Parent = tile

	-- Status label
	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Size = UDim2.new(1, -16, 0, 20)
	status.Position = UDim2.new(0, 8, 1, -24)
	status.TextScaled = true
	status.TextColor3 = isOwned and (isEquipped and Color3.fromRGB(180, 255, 180) or Color3.fromRGB(220, 220, 220)) or Color3.fromRGB(220, 180, 180)
	status.Text = isOwned and (isEquipped and "Equipped" or "Not Equipped") or "Locked"
	status.Parent = tile

	-- Equip interaction (only if owned)
	if isOwned then
		local equipButton = Instance.new("TextButton")
		equipButton.BackgroundTransparency = 1
		equipButton.Size = UDim2.fromScale(1, 1)
		equipButton.Text = ""
		equipButton.Parent = tile
		equipButton.MouseButton1Click:Connect(function()
			if def.id ~= equippedId then
				EquipMarble:FireServer(def.id)
			end
		end)
	end

	return tile
end

-- Function to refresh canvas size
local function refreshCanvasSize()
	-- Safety check: ensure required UI elements exist
	if not list or not grid then
		print("refreshCanvasSize: Required UI elements (list or grid) not available, skipping")
		return
	end
	
	local abs = grid.AbsoluteContentSize
	list.CanvasSize = UDim2.new(0, 0, 0, abs.Y + 12)
end

-- Function to rebuild inventory UI
function InventoryUI:rebuild(ownedSet, equippedId)
	-- Safety check: ensure required UI elements exist
	if not list or not grid then
		print("rebuildInventoryUI: Required UI elements (list or grid) not available, skipping")
		return
	end
	
	-- Safety check: ensure Marbles module is available
	if not Marbles or not Marbles.getAll then
		print("rebuildInventoryUI: Marbles module not available, skipping")
		return
	end
	
	-- Clear existing tiles but keep grid
	for _, child in ipairs(list:GetChildren()) do
		if child ~= grid then
			child:Destroy()
		end
	end
	for _, def in ipairs(Marbles.getAll()) do
		local tile = createMarbleTile(def, ownedSet, equippedId)
		tile.Parent = list
	end
	refreshCanvasSize()
end

-- Function to toggle inventory visibility
function InventoryUI:toggle()
	if invFrame then
		local newVisible = not invFrame.Visible
		invFrame.Visible = newVisible
		
		-- Play sound effect if opening
		if newVisible then
			-- Find the sound effect in the screen
			local screen = invFrame.Parent
			if screen then
				local invOpenSfx = screen:FindFirstChild("InventoryOpenSfx")
				if invOpenSfx and invOpenSfx:IsA("Sound") then
					pcall(function()
						invOpenSfx:Play()
					end)
				end
			end
		end
	end
end

-- Function to initialize the inventory UI
function InventoryUI:init(screen)
	print("Creating inventory frame...")
	invFrame = Instance.new("Frame")
	invFrame.Name = "InventoryFrame"
	invFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	invFrame.BackgroundTransparency = 0.2 -- semi-transparent
	invFrame.BorderSizePixel = 0
	invFrame.Size = UDim2.new(0, 720, 0, 520)
	invFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	invFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	invFrame.Visible = false
	invFrame.Parent = screen
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = invFrame

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, -24, 0, 40)
	header.Position = UDim2.new(0, 12, 0, 10)
	header.Font = Enum.Font.GothamBold
	header.TextXAlignment = Enum.TextXAlignment.Center
	header.Text = "Inventory"
	header.TextColor3 = Color3.new(1,1,1)
	header.TextSize = 24
	header.Parent = invFrame

	-- Close button (top-right)
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextScaled = true
	closeButton.Size = UDim2.fromOffset(36, 36)
	closeButton.Position = UDim2.new(1, -12, 0, 12)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	closeButton.TextColor3 = Color3.new(1,1,1)
	closeButton.Parent = invFrame
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	closeButton.MouseButton1Click:Connect(function()
		invFrame.Visible = false
	end)

	list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Size = UDim2.new(1, -24, 1, -80)
	list.Position = UDim2.new(0, 12, 0, 60)
	list.ScrollBarThickness = 8
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.BackgroundTransparency = 1
	list.Parent = invFrame

	grid = Instance.new("UIGridLayout")
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.FillDirectionMaxCells = 3 -- 3 columns
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.CellSize = UDim2.fromOffset(200, 200)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center -- Center the grid horizontally
	grid.Parent = list

	-- Connect canvas size refresh
	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvasSize)
	
	print("=== Inventory UI Created ===")
end

return InventoryUI
