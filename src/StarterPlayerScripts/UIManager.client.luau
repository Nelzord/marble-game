-- UIManager.client.luau
-- Main UI coordination and state management for the Marble Game

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Wait for PlayerGui to be ready
if not playerGui then
	error("PlayerGui not found after WaitForChild!")
end

-- Wait a bit more to ensure PlayerGui is fully initialized
task.wait(0.1)

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RollForMarble: RemoteEvent = RemotesFolder:WaitForChild("RollForMarble")
local EquipMarble: RemoteEvent = RemotesFolder:WaitForChild("EquipMarble")
local InventoryUpdate: RemoteEvent = RemotesFolder:WaitForChild("InventoryUpdate")
local RollResult: RemoteEvent = RemotesFolder:WaitForChild("RollResult")
local RequestInventory: RemoteEvent = RemotesFolder:WaitForChild("RequestInventory")
local ActivateAbility: RemoteEvent = RemotesFolder:WaitForChild("ActivateAbility")
local AbilityCooldown: RemoteEvent = RemotesFolder:WaitForChild("AbilityCooldown")

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))

-- State variables
local ownedSet: { [string]: boolean } = {}
local equippedId: string? = nil
local isRolling = false

-- UI element references
local screen: ScreenGui? = nil
local rollButton: TextButton? = nil
local inventoryButton: TextButton? = nil
local resultLabel: TextLabel? = nil
local invFrame: Frame? = nil

-- Module references (will be set by UIManager:init)
local PowerButton: any = nil
local RollAnimation: any = nil
local InventoryUI: any = nil

local UIManager = {}

-- Function to check if UI is fully ready
function UIManager:isUIReady()
	return screen and screen.Parent and PowerButton and PowerButton:isReady()
end

-- Function to wait for UI to be ready
function UIManager:waitForUIReady()
	local maxAttempts = 50 -- Wait up to 5 seconds
	local attempts = 0
	
	print("UIManager:waitForUIReady: Starting wait loop...")
	
	while not self:isUIReady() and attempts < maxAttempts do
		attempts = attempts + 1
		print("Waiting for UI to be ready, attempt:", attempts, "/", maxAttempts)
		task.wait(0.1)
	end
	
	if self:isUIReady() then
		print("UI is now ready!")
		return true
	else
		print("UI failed to become ready after", maxAttempts, "attempts")
		return false
	end
end

-- Function to create the main screen
function UIManager:createMainScreen()
	print("=== Starting UI Construction ===")
	
	screen = Instance.new("ScreenGui")
	screen.Name = "MarbleUI"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = false
	screen.Parent = playerGui
	
	-- Inventory open SFX
	local invOpenSfx = Instance.new("Sound")
	invOpenSfx.Name = "InventoryOpenSfx"
	invOpenSfx.SoundId = "rbxassetid://127877437691780"
	invOpenSfx.Volume = 0.6
	invOpenSfx.Parent = screen
	
	print("=== Main Screen Created ===")
	return screen
end

-- Function to create basic UI elements
function UIManager:createBasicUI()
	-- Roll button
	rollButton = Instance.new("TextButton")
	rollButton.Name = "RollButton"
	rollButton.Text = "Roll for Marble"
	rollButton.TextScaled = true
	rollButton.Size = UDim2.fromOffset(200, 56)
	rollButton.Position = UDim2.new(0.5, 110, 1, -24)
	rollButton.AnchorPoint = Vector2.new(0.5, 1)
	rollButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	rollButton.TextColor3 = Color3.new(1,1,1)
	rollButton.Font = Enum.Font.GothamBold
	rollButton.Parent = screen
	
	local rollCorner = Instance.new("UICorner")
	rollCorner.CornerRadius = UDim.new(0, 8)
	rollCorner.Parent = rollButton
	
	-- Inventory button
	inventoryButton = Instance.new("TextButton")
	inventoryButton.Name = "InventoryButton"
	inventoryButton.Text = "Inventory"
	inventoryButton.TextScaled = true
	inventoryButton.Size = UDim2.fromOffset(160, 40)
	inventoryButton.Position = UDim2.new(0, 16, 0, 16)
	inventoryButton.AnchorPoint = Vector2.new(0, 0)
	inventoryButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	inventoryButton.TextColor3 = Color3.new(1,1,1)
	inventoryButton.Font = Enum.Font.GothamBold
	inventoryButton.Parent = screen
	
	local invBtnCorner = Instance.new("UICorner")
	invBtnCorner.CornerRadius = UDim.new(0, 8)
	invBtnCorner.Parent = inventoryButton
	
	-- Result label
	resultLabel = Instance.new("TextLabel")
	resultLabel.Name = "ResultLabel"
	resultLabel.Text = ""
	resultLabel.TextScaled = true
	resultLabel.BackgroundTransparency = 1
	resultLabel.TextColor3 = Color3.new(1,1,1)
	resultLabel.Size = UDim2.fromOffset(480, 40)
	resultLabel.Position = UDim2.new(0.5, 0, 1, -88)
	resultLabel.AnchorPoint = Vector2.new(0.5, 1)
	resultLabel.Parent = screen
	
	print("=== Basic UI Created ===")
end

-- Function to wire up event handlers
function UIManager:wireEvents()
	-- Roll button click
	rollButton.MouseButton1Click:Connect(function()
		if RollAnimation then
			RollAnimation:startRoll()
		end
	end)
	
	-- Inventory button click
	inventoryButton.MouseButton1Click:Connect(function()
		if InventoryUI then
			InventoryUI:toggle()
		end
	end)
	
	-- Inventory update event
	InventoryUpdate.OnClientEvent:Connect(function(payload)
		print("InventoryUpdate received")
		print("payload.owned:", payload.owned)
		print("payload.equipped:", payload.equipped)
		
		ownedSet = {}
		for _, id in ipairs(payload.owned :: {string}) do
			ownedSet[id] = true
			print("Added to ownedSet:", id)
		end
		equippedId = payload.equipped
		print("equippedId set to:", equippedId)
		
		-- Update inventory UI
		if InventoryUI then
			InventoryUI:rebuild(ownedSet, equippedId)
		end
		
		-- Update power button
		if PowerButton then
			PowerButton:updateForMarble(equippedId)
		end
	end)
	
	-- Roll result event
	RollResult.OnClientEvent:Connect(function(result)
		print("RollResult received:", result.success, result.marbleName or result.marbleId or "nil")
		
		if RollAnimation then
			RollAnimation:showResult(result)
		end
	end)
	
	-- Ability cooldown event
	AbilityCooldown.OnClientEvent:Connect(function(cooldownData)
		print("AbilityCooldown received:", cooldownData.duration, "seconds")
		
		if PowerButton then
			PowerButton:startCooldown(cooldownData.duration)
		end
	end)
	
	-- Ability activation keybind (E key)
	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		
		if input.KeyCode == Enum.KeyCode.E then
			if PowerButton then
				PowerButton:activateAbility(equippedId)
			end
		end
		
		-- Debug: Force reset cooldown with R key
		if input.KeyCode == Enum.KeyCode.R then
			print("R key pressed - forcing cooldown reset")
			if PowerButton then
				PowerButton:forceResetCooldown()
			end
		end
	end)
	
	print("=== Events Wired ===")
end

-- Function to initialize the UI manager
function UIManager:init()
	-- Create main screen
	self:createMainScreen()
	
	-- Create basic UI elements
	self:createBasicUI()
	
	-- Initialize modules (these will be set by the main script)
	if PowerButton then
		PowerButton:init(screen)
	end
	
	if RollAnimation then
		RollAnimation:init(screen)
	end
	
	if InventoryUI then
		InventoryUI:init(screen)
	end
	
	-- Wire up events
	self:wireEvents()
	
	-- Wait for UI to be ready
	if self:waitForUIReady() then
		print("UI is fully ready and initialized!")
		-- Request initial inventory
		RequestInventory:FireServer()
	else
		print("WARNING: UI failed to become ready!")
	end
	
	print("=== UIManager Initialization Complete ===")
end

-- Function to set module references
function UIManager:setModules(powerButtonModule, rollAnimationModule, inventoryUIModule)
	PowerButton = powerButtonModule
	RollAnimation = rollAnimationModule
	InventoryUI = inventoryUIModule
end

-- Function to get owned marbles
function UIManager:getOwnedMarbles()
	return ownedSet
end

-- Function to get equipped marble ID
function UIManager:getEquippedMarbleId()
	return equippedId
end

-- Function to check if a marble is owned
function UIManager:isMarbleOwned(marbleId)
	return ownedSet[marbleId] == true
end

-- Function to check if a marble is equipped
function UIManager:isMarbleEquipped(marbleId)
	return equippedId == marbleId
end

return UIManager
