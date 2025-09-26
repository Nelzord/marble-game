local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Shop Service
local ShopService = {}

-- Lucky potion system
local playerLuckyPotions = {} -- { [Player] = { multiplier = number, endTime = number } }
local POTION_DURATION = 300 -- 5 minutes in seconds

-- Shop items data (you can expand this)
local shopItems = {
    {
        name = "Speed Boost",
        price = 100,
        description = "Increases marble speed",
        itemType = "ability"
    },
    {
        name = "Extra Life",
        price = 50,
        description = "Gives you an extra life",
        itemType = "consumable"
    },
    {
        name = "Lucky Potion (1.25x)",
        price = 50,
        description = "Increases luck by 1.25x for 5 minutes",
        itemType = "lucky_potion",
        luckMultiplier = 1.25
    },
    {
        name = "Lucky Potion (1.5x)",
        price = 75,
        description = "Increases luck by 1.5x for 5 minutes",
        itemType = "lucky_potion",
        luckMultiplier = 1.5
    },
    {
        name = "Lucky Potion (2x)",
        price = 100,
        description = "Increases luck by 2x for 5 minutes",
        itemType = "lucky_potion",
        luckMultiplier = 2
    }
}

-- Function to get shop items
function ShopService:GetShopItems()
    return shopItems
end

-- Function to get player's current luck multiplier (including permanent bonus)
function ShopService:GetPlayerLuckMultiplier(player)
    local potion = playerLuckyPotions[player]
    local potionMultiplier = 1
    if potion and os.time() < potion.endTime then
        potionMultiplier = potion.multiplier
    end
    
    -- Get permanent luck bonus from RobuxService (with safe require)
    local permanentBonus = 1 -- Default to 1x if RobuxService not available
    
    -- Try to get RobuxService, but don't fail if it's not available
    local success, result = pcall(function()
        local RobuxService = require(script.Parent.RobuxService)
        if RobuxService and RobuxService.GetPlayerTotalLuckMultiplier then
            return RobuxService:GetPlayerTotalLuckMultiplier(player)
        end
        return 1
    end)
    
    if success then
        permanentBonus = result
    end
    
    -- Combine permanent bonus with potion multiplier
    return permanentBonus * potionMultiplier
end

-- Function to send luck update to client
local function sendLuckUpdate(player)
    local luckMultiplier = ShopService:GetPlayerLuckMultiplier(player)
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if Remotes and Remotes:FindFirstChild("LuckUpdate") then
        local potion = playerLuckyPotions[player]
        local timeLeft = 0
        if potion and os.time() < potion.endTime then
            timeLeft = potion.endTime - os.time()
        end
        Remotes.LuckUpdate:FireClient(player, luckMultiplier, timeLeft)
    end
end

-- Function to purchase item
function ShopService:PurchaseItem(player, itemName)
    print("[ShopService] PurchaseItem called for " .. player.Name .. " - " .. itemName)
    
    -- Find the item
    local item = nil
    for _, shopItem in ipairs(shopItems) do
        if shopItem.name == itemName then
            item = shopItem
            break
        end
    end
    
    if not item then
        print("[ShopService] Item not found: " .. itemName)
        return false, "Item not found"
    end
    
    print("[ShopService] Found item: " .. item.name .. " (price: " .. item.price .. ")")
    
    -- Get CoinService (with safe require)
    local success, CoinService = pcall(function()
        return require(script.Parent.CoinService)
    end)
    
    if not success or not CoinService then
        print("[ShopService] Failed to require CoinService")
        return false, "Service unavailable"
    end
    
    -- Check if player has enough coins
    local currentCoins = CoinService:GetCoins(player)
    print("[ShopService] Player " .. player.Name .. " has " .. currentCoins .. " coins, needs " .. item.price)
    
    if currentCoins < item.price then
        return false, "Not enough coins"
    end
    
    -- Handle different item types
    if item.itemType == "lucky_potion" then
        -- Remove old potion if exists
        playerLuckyPotions[player] = nil
        
        -- Add new potion
        playerLuckyPotions[player] = {
            multiplier = item.luckMultiplier,
            endTime = os.time() + POTION_DURATION
        }
        
        -- Deduct coins
        CoinService:RemoveCoins(player, item.price)
        
        -- Send luck update to client
        sendLuckUpdate(player)
        
        print(player.Name .. " purchased " .. itemName .. " for " .. item.price .. " coins")
        return true, "Lucky potion activated!"
    else
        -- Handle other item types here in the future
        return false, "Item type not implemented yet"
    end
end

-- Function to clean up expired potions
local function cleanupExpiredPotions()
    local currentTime = os.time()
    for player, potion in pairs(playerLuckyPotions) do
        if currentTime >= potion.endTime then
            playerLuckyPotions[player] = nil
        end
    end
end

-- Function to get player coins (for UI display)
function ShopService:GetPlayerCoins(player)
    local success, CoinService = pcall(function()
        return require(script.Parent.CoinService)
    end)
    
    if success and CoinService then
        return CoinService:GetCoins(player)
    else
        return 0 -- Default to 0 coins if service unavailable
    end
end

-- Initialize the service
function ShopService:Init()
    print("Shop Service initialized")
    
    -- Create/fetch remotes
    local function getOrCreateRemotes()
        local folder = ReplicatedStorage:FindFirstChild("Remotes")
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = "Remotes"
            folder.Parent = ReplicatedStorage
        end
        local function ensureEvent(name: string)
            local evt = folder:FindFirstChild(name)
            if not evt then
                evt = Instance.new("RemoteEvent")
                evt.Name = name
                evt.Parent = folder
            end
            return evt :: RemoteEvent
        end
        return {
            ShopPurchase = ensureEvent("ShopPurchase"),
            LuckUpdate = ensureEvent("LuckUpdate"),
        }
    end
    
    local Remotes = getOrCreateRemotes()
    
    -- Handle shop purchases
    Remotes.ShopPurchase.OnServerEvent:Connect(function(player, itemName)
        print("[ShopService] Received purchase request from " .. player.Name .. " for " .. itemName)
        local success, message = ShopService:PurchaseItem(player, itemName)
        if success then
            print(player.Name .. " successfully purchased " .. itemName)
        else
            print(player.Name .. " failed to purchase " .. itemName .. ": " .. message)
        end
    end)
    
    -- Send initial luck update when player joins
    Players.PlayerAdded:Connect(function(player)
        wait(1) -- Wait a moment for client to be ready
        sendLuckUpdate(player)
    end)
    
    -- Clean up expired potions every minute
    spawn(function()
        while true do
            cleanupExpiredPotions()
            wait(60) -- Check every minute
        end
    end)
end

-- Start the service
ShopService:Init()

return ShopService
