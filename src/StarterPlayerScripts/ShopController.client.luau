local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = nil
local humanoidRootPart = nil
local shop = nil
local shopProximity = 25 -- Distance to detect shop proximity2

local isNearShop = false
local shopOpen = false

-- Hover UI elements
local hoverGui = nil
local hoverLabel = nil

-- Function to create hover UI
local function createHoverUI()
    if hoverGui then return end
    
    hoverGui = Instance.new("ScreenGui")
    hoverGui.Name = "ShopHoverGUI"
    hoverGui.ResetOnSpawn = false
    hoverGui.Parent = player:WaitForChild("PlayerGui")
    
    hoverLabel = Instance.new("TextLabel")
    hoverLabel.Name = "HoverLabel"
    hoverLabel.Size = UDim2.new(0, 200, 0, 50)
    hoverLabel.Position = UDim2.new(0.5, -100, 0.7, 0)
    hoverLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    hoverLabel.BackgroundTransparency = 0.3
    hoverLabel.BorderSizePixel = 0
    hoverLabel.Text = "Press E to Open Shop"
    hoverLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    hoverLabel.TextScaled = true
    hoverLabel.Font = Enum.Font.GothamBold
    hoverLabel.Parent = hoverGui
    
    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = hoverLabel
    
    -- Initially hide
    hoverGui.Enabled = false
end

-- Function to show/hide hover
local function toggleHover(show)
    if hoverGui then
        hoverGui.Enabled = show
    end
end

-- Function to initialize character
local function initializeCharacter()
    if player.Character then
        character = player.Character
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        
        -- If HumanoidRootPart isn't found immediately, wait a bit but with timeout
        if not humanoidRootPart then
            local startTime = tick()
            local timeout = 5 -- 5 second timeout for initial character
            
            local function waitForInitialHumanoidRootPart()
                if tick() - startTime > timeout then
                    warn("Timeout waiting for initial HumanoidRootPart")
                    return
                end
                
                humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if not humanoidRootPart then
                    wait(0.1)
                    waitForInitialHumanoidRootPart()
                end
            end
            
            waitForInitialHumanoidRootPart()
        end
    end
end

-- Function to find shop safely
local function findShop()
    local spawn = workspace:FindFirstChild("Spawn")
    if spawn then
        local shopModel = spawn:FindFirstChild("Shop")
        if shopModel and shopModel.PrimaryPart then
            return shopModel
        end
    end
    return nil
end

-- Function to check if player is near shop
local function checkProximity()
    if not character or not humanoidRootPart or not shop then
        return
    end
    
    if shop.PrimaryPart then
        local distance = (humanoidRootPart.Position - shop.PrimaryPart.Position).Magnitude
        local wasNearShop = isNearShop
        isNearShop = distance <= shopProximity
        
        -- Show/hide hover based on proximity
        if isNearShop and not wasNearShop then
            toggleHover(true)
        elseif not isNearShop and wasNearShop then
            toggleHover(false)
        end
    end
end

-- Function to open shop
local function openShop()
    if isNearShop and not shopOpen then
        shopOpen = true
        toggleHover(false) -- Hide hover when shop is open
        
        -- Wait for ShopUI to be available
        local attempts = 0
        local maxAttempts = 10
        
        local function tryOpenShop()
            if _G.ShopUI and _G.ShopUI.toggleShop then
                _G.ShopUI.toggleShop(true)
                return true
            elseif attempts < maxAttempts then
                attempts = attempts + 1
                wait(0.1)
                tryOpenShop()
            end
        end
        
        tryOpenShop()
    end
end

-- Function to close shop
local function closeShop()
    if shopOpen then
        shopOpen = false
        if _G.ShopUI and _G.ShopUI.toggleShop then
            _G.ShopUI.toggleShop(false)
        end
        
        -- Show hover again if still near shop
        if isNearShop then
            toggleHover(true)
        end
    end
end

-- Handle E key press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        if isNearShop then
            if shopOpen then
                closeShop()
            else
                openShop()
            end
        end
    end
end)

-- Handle character respawning
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    -- Use FindFirstChild with a timeout instead of WaitForChild
    local startTime = tick()
    local timeout = 10 -- 10 second timeout
    
    local function waitForHumanoidRootPart()
        if tick() - startTime > timeout then
            warn("Timeout waiting for HumanoidRootPart")
            return
        end
        
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            shopOpen = false
            isNearShop = false
        else
            wait(0.1)
            waitForHumanoidRootPart()
        end
    end
    
    waitForHumanoidRootPart()
end)

-- Initialize character if it already exists
initializeCharacter()

-- Create hover UI
createHoverUI()

-- Find shop
shop = findShop()

-- Check proximity every frame
RunService.Heartbeat:Connect(function()
    if not shop then
        shop = findShop()
    end
    
    if shop then
        checkProximity()
    end
end)
