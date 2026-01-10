local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local shopOpen = false

-- Function to open shop
local function openShop()
    shopOpen = true
    
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

-- Function to close shop
local function closeShop()
    shopOpen = false
    if _G.ShopUI and _G.ShopUI.toggleShop then
        _G.ShopUI.toggleShop(false)
    end
end

-- Listen for shop open/close requests from server (via ProximityPrompt)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local openShopRemote = remotes:WaitForChild("OpenShop", 10)
local closeShopRemote = remotes:WaitForChild("CloseShop", 10)

if openShopRemote then
    openShopRemote.OnClientEvent:Connect(function()
        openShop()
    end)
end

if closeShopRemote then
    closeShopRemote.OnClientEvent:Connect(function()
        closeShop()
    end)
end

-- Handle character respawning - reset shop state
player.CharacterAdded:Connect(function()
    shopOpen = false
end)
