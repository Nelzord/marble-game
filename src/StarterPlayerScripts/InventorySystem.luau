-- InventorySystem.luau
-- Handles all inventory-related functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventorySystem = {}

-- State variables
local ownedSet: { [string]: boolean } = {}
local equippedId: string? = nil
local pendingInventoryUpdate: { owned: {string}, equipped: string }? = nil

-- Ability descriptions by module name
local ABILITY_DESCRIPTIONS: { [string]: string } = {
	Default = "No special ability.",
	SpeedBoost = "Temporarily increases rolling speed.",
	Red = "Red: A fiery burst that briefly increases acceleration.",
	Blue = "Blue: A calming shield that reduces deceleration briefly.",
	Green = "Green: A rejuvenating pulse that boosts control for a moment.",
	Spider = "Spider: Shoot a web to grapple and swing toward targets.",
	Gumball = "Gumball: A bouncy marble that can launch high into the air with explosive force.",
	TimeTravel = "TimeTravel: Go back in time 5 seconds to your previous position.",
	Moon = "Moon: Lower gravity for slower falling and floating lunar-like movement.",
	Jumper = "Jumper: Press E to perform a double jump when in mid-air.",
	Gold = "Gold: Doubles all coins collected while active.",
	Diamond = "Diamond: Triples all coins collected while active.",
	Teleporting = "Teleporting: Teleport upward in the air to gain height advantage.",
	Leaf = "Leaf: Create a gust of swirling leaves that lifts you into the air.",
}

-- Texture fallbacks (should match controller)
local FALLBACK_DECALS: { [string]: string } = {
	Default = "rbxassetid://110926540048461",
	Red = "rbxassetid://99977275020564",
	Green = "rbxassetid://114474679212927",
	Blue = "rbxassetid://128223600665334",
	Spider = "rbxassetid://105354663033087",
	Gumball = "rbxassetid://92160789193138",
	TimeTravel = "rbxassetid://115652916108662",
	Moon = "rbxassetid://95370471502854",
	Jumper = "rbxassetid://81030833444551",
	Glass = "rbxassetid://101699002274981", -- Glass texture
	Gold = "rbxassetid://84142305330257", -- Gold texture
	Diamond = "rbxassetid://95881293008595", -- Diamond texture
	Teleporting = "rbxassetid://73544653958153", -- Teleporting texture
	Pharaoh = "rbxassetid://138858793251784", -- Pharaoh texture
	Leaf = "rbxassetid://107199178243113", -- Leaf texture
}

-- Function to apply textures to a part
local function applyTexturesToPart(part: BasePart, marbleId: string)
	-- Clear existing
	for _, ch in ipairs(part:GetChildren()) do
		if ch:IsA("Decal") or ch:IsA("Texture") then 
			ch:Destroy() 
		end
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

-- Function to get rarity color based on drop denominator
local function getRarityColor(def): Color3
	if not def or not def.rollable or not def.dropDenominator or def.dropDenominator <= 0 then
		return Color3.fromRGB(200, 200, 200) -- Common gray
	end
	
	local denominator = def.dropDenominator
	
	-- Rarity colors based on drop chance
	if denominator <= 2 then
		-- Common: 1/1, 1/2
		return Color3.fromRGB(200, 200, 200)
	elseif denominator <= 5 then
		-- Uncommon: 1/3, 1/4, 1/5
		return Color3.fromRGB(100, 200, 100)
	elseif denominator <= 9 then
		-- Rare: 1/6, 1/7, 1/8, 1/9
		return Color3.fromRGB(100, 150, 255)
	elseif denominator <= 49 then
		-- Epic: 1/10 to 1/49
		return Color3.fromRGB(200, 100, 255)
	elseif denominator <= 199 then
		-- Legendary: 1/50 to 1/199
		return Color3.fromRGB(255, 200, 50)
	else
		-- Mythic: 1/200 to 1/2500
		return Color3.fromRGB(255, 50, 50)
	end
end

-- Function to create a marble tile
function InventorySystem.createMarbleTile(def, list, grid, EquipMarble)
	local isOwned = ownedSet[def.id] == true
	local isEquipped = def.id == equippedId

	local tile = Instance.new("Frame")
	tile.Size = UDim2.fromOffset(200, 200)
	tile.BackgroundColor3 = isEquipped and Color3.fromRGB(38, 110, 180) or Color3.fromRGB(40, 40, 40)
	tile.BorderSizePixel = 0

	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 8)
	corner2.Parent = tile

	-- Add green ring for equipped marbles
	if isEquipped then
		local ring = Instance.new("Frame")
		ring.Name = "EquippedRing"
		ring.Size = UDim2.new(1, 4, 1, 4)
		ring.Position = UDim2.new(0, -2, 0, -2)
		ring.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		ring.BorderSizePixel = 0
		ring.Parent = tile
		
		local ringCorner = Instance.new("UICorner")
		ringCorner.CornerRadius = UDim.new(0, 10)
		ringCorner.Parent = ring
		
		-- Move ring behind the main tile
		ring.ZIndex = tile.ZIndex - 1
	end

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
		sphere.Color = Color3.fromRGB(60, 60, 60)
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
		ql.TextColor3 = Color3.new(1, 1, 1)
		ql.Size = UDim2.fromScale(1, 1)
		ql.Parent = q
	end

	-- Camera
	local cam = Instance.new("Camera")
	viewport.CurrentCamera = cam
	cam.Parent = viewport
	local center = Vector3.new(0, 0, 0)
	sphere.Position = center
	cam.CFrame = CFrame.new(center + Vector3.new(0, 0, 12), center)

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, -16, 0, 16)
	nameLabel.Position = UDim2.new(0, 8, 1, -44)
	nameLabel.Text = isOwned and def.name or "???"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Parent = tile

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Size = UDim2.new(1, -16, 0, 20)
	rarityLabel.Position = UDim2.new(0, 8, 1, -24)
	rarityLabel.TextScaled = true
	rarityLabel.TextColor3 = isOwned and getRarityColor(def) or Color3.fromRGB(220, 180, 180)
	rarityLabel.Text = isOwned and getRarityText(def) or "Locked"
	rarityLabel.Parent = tile

	-- Equip interaction (only if owned)
	if isOwned then
		local equipButton = Instance.new("TextButton")
		equipButton.BackgroundTransparency = 1
		equipButton.Size = UDim2.fromScale(1, 1)
		equipButton.Text = ""
		equipButton.Parent = tile
		equipButton.MouseButton1Click:Connect(function()
			if def.id ~= equippedId and EquipMarble then
				EquipMarble:FireServer(def.id)
			elseif not EquipMarble then
				print("Warning: EquipMarble remote event not available")
			end
		end)
	end

	return tile
end

-- Function to refresh canvas size
function InventorySystem.refreshCanvasSize(list, grid)
	-- Safety check: ensure required UI elements exist
	if not list or not grid then
		print("refreshCanvasSize: Required UI elements (list or grid) not available, skipping")
		return
	end
	
	local abs = grid.AbsoluteContentSize
	list.CanvasSize = UDim2.new(0, 0, 0, abs.Y + 12)
end

-- Function to rebuild inventory UI
function InventorySystem.rebuildInventoryUI(list, grid, Marbles, EquipMarble)
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
	
	-- Safety check: ensure EquipMarble remote event is available
	if not EquipMarble then
		print("rebuildInventoryUI: EquipMarble remote event not available, skipping")
		return
	end
	
	-- Clear existing tiles but keep grid
	for _, child in ipairs(list:GetChildren()) do
		if child ~= grid then
			child:Destroy()
		end
	end
	
	for _, def in ipairs(Marbles.getAll()) do
		local tile = InventorySystem.createMarbleTile(def, list, grid, EquipMarble)
		tile.Parent = list
	end
	
	InventorySystem.refreshCanvasSize(list, grid)
end

-- Function to update inventory data
function InventorySystem.updateInventory(payload)
	print("InventorySystem.updateInventory called")
	print("payload.owned:", payload.owned)
	print("payload.equipped:", payload.equipped)
	
	ownedSet = {}
	for _, id in ipairs(payload.owned :: {string}) do
		ownedSet[id] = true
		print("Added to ownedSet:", id)
	end
	equippedId = payload.equipped
	print("equippedId set to:", equippedId)
	
	-- Expose owned marbles globally for shop UI to check ownership
	_G.ownedMarbles = ownedSet
	
	-- Debug: Check what marble definition we get for Spider
	if equippedId == "Spider" then
		print("Spider marble equipped - checking definition")
	end
end

-- Function to process pending inventory updates
function InventorySystem.processPendingInventoryUpdate()
	if pendingInventoryUpdate then
		print("Processing pending inventory update for equipped marble:", pendingInventoryUpdate.equipped)
		
		-- Apply the pending inventory update
		ownedSet = {}
		for _, id in ipairs(pendingInventoryUpdate.owned) do
			ownedSet[id] = true
			print("Added to ownedSet:", id)
		end
		equippedId = pendingInventoryUpdate.equipped
		print("equippedId set to:", equippedId)
		
		-- Clear the pending update
		pendingInventoryUpdate = nil
		
		return true
	end
	return false
end

-- Function to queue inventory update for later processing
function InventorySystem.queueInventoryUpdate(payload)
	print("InventorySystem: UI not ready, storing update for later processing")
	pendingInventoryUpdate = {
		owned = payload.owned,
		equipped = payload.equipped
	}
end

-- Function to get equipped marble ID
function InventorySystem.getEquippedId()
	return equippedId
end

-- Function to check if a marble is owned
function InventorySystem.isOwned(marbleId: string): boolean
	return ownedSet[marbleId] == true
end

-- Function to check if a marble is equipped
function InventorySystem.isEquipped(marbleId: string): boolean
	return equippedId == marbleId
end

-- Function to get all owned marbles
function InventorySystem.getOwnedMarbles(): {string}
	local owned = {}
	for id, _ in pairs(ownedSet) do
		table.insert(owned, id)
	end
	return owned
end

return InventorySystem
