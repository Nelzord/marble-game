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
    },
    {
        name = "Meteor Marble",
        price = 100,
        description = "Unlock the Meteor Marble - Teleport high into the sky as meteors rain down around you",
        itemType = "meteor_marble",
        marbleId = "Meteor"
    },
    {
        name = "Tsunami Marble",
        price = 200,
        description = "Unlock the Tsunami Marble - Summon a massive wave from below that launches you skyward",
        itemType = "tsunami_marble",
        marbleId = "Tsunami"
    },
    {
        name = "Glass Marble",
        price = 300,
        description = "Unlock the Glass Marble - Leaves behind a glass trail while moving that makes marbles slip",
        itemType = "glass_marble",
        marbleId = "Glass"
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
    
    -- Get permanent luck bonus from RobuxService
    local permanentBonus = 1 -- Default to 1x if RobuxService not available
    
    -- Try to get RobuxService from _G first, then try requiring it
    local RobuxService = _G.RobuxService
    if not RobuxService then
        local success, result = pcall(function()
            return require(script.Parent.RobuxService)
        end)
        if success and result then
            RobuxService = result
        end
    end
    
    if RobuxService and RobuxService.GetPlayerTotalLuckMultiplier then
        local success, result = pcall(function()
            return RobuxService:GetPlayerTotalLuckMultiplier(player)
        end)
        if success and result then
            permanentBonus = result
        end
    end
    
    -- Combine permanent bonus with potion multiplier
    local totalMultiplier = permanentBonus * potionMultiplier
    print("[ShopService] Luck calculation for " .. player.Name .. ": permanent=" .. permanentBonus .. "x, potion=" .. potionMultiplier .. "x, total=" .. totalMultiplier .. "x")
    return totalMultiplier
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

-- Export sendLuckUpdate for other services to use
ShopService.sendLuckUpdate = sendLuckUpdate

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
    elseif item.itemType == "meteor_marble" or item.itemType == "tsunami_marble" or item.itemType == "glass_marble" then
        -- Handle marble purchases
        local marbleId = item.marbleId
        if not marbleId then
            return false, "Marble ID not specified"
        end
        
        -- Get MarbleService
        local MarbleService = _G.MarbleService
        if not MarbleService then
            -- Try to require it
            local success, result = pcall(function()
                return require(script.Parent.MarbleService)
            end)
            if success and result then
                MarbleService = result
            end
        end
        
        if not MarbleService then
            return false, "MarbleService unavailable"
        end
        
        -- Check if player already has the marble
        if MarbleService.HasMarble and MarbleService.HasMarble(player, marbleId) then
            return false, "You already own this marble!"
        end
        
        -- Grant the marble
        if MarbleService.GrantMarble then
            local success = MarbleService.GrantMarble(player, marbleId)
            if success then
                -- Deduct coins
                CoinService:RemoveCoins(player, item.price)
                print(player.Name .. " purchased " .. itemName .. " for " .. item.price .. " coins")
                return true, "Marble unlocked!"
            else
                return false, "Failed to grant marble"
            end
        else
            return false, "MarbleService.GrantMarble not available"
        end
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
            OpenShop = ensureEvent("OpenShop"),
            CloseShop = ensureEvent("CloseShop"),
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
    
    -- Set up ProximityPrompt for shop
    local function setupShopProximityPrompt(proximityPrompt: ProximityPrompt)
        -- Track if this specific prompt has already been set up to avoid duplicate connections
        if proximityPrompt:GetAttribute("ShopPromptSetup") then
            return
        end
        proximityPrompt:SetAttribute("ShopPromptSetup", true)
        
        -- Connect to the Triggered event
        proximityPrompt.Triggered:Connect(function(player: Player)
            print("[ShopService] Shop proximity prompt triggered by", player.Name)
            -- Always open the shop when ProximityPrompt is triggered
            -- The close button in the UI will handle closing
            Remotes.OpenShop:FireClient(player)
        end)
        
        print("[ShopService] Set up shop proximity prompt:", proximityPrompt:GetFullName())
    end
    
    -- Function to find and set up shop proximity prompts
    local function findAndSetupShopProximityPrompts()
        local count = 0
        
        -- Search through all descendants in workspace
        for _, descendant in pairs(workspace:GetDescendants()) do
            if descendant:IsA("ProximityPrompt") then
                local name = descendant.Name:lower()
                -- Match prompts with "shop" in the name (case-insensitive)
                if name:find("shop") and not name:find("community") then
                    setupShopProximityPrompt(descendant)
                    count = count + 1
                end
            end
        end
        
        print("[ShopService] Found and set up", count, "shop proximity prompts")
        return count
    end
    
    -- Handle new proximity prompts that get added dynamically
    local function onDescendantAdded(descendant: Instance)
        if descendant:IsA("ProximityPrompt") then
            local name = descendant.Name:lower()
            if name:find("shop") and not name:find("community") then
                -- Small delay to ensure the prompt is fully initialized
                task.defer(function()
                    setupShopProximityPrompt(descendant)
                end)
            end
        end
    end
    
    -- Set up existing proximity prompts
    local promptCount = findAndSetupShopProximityPrompts()
    
    -- Listen for new proximity prompts added to workspace
    workspace.DescendantAdded:Connect(onDescendantAdded)
    
    -- If no prompts were found, log a helpful message
    if promptCount == 0 then
        print("[ShopService] WARNING: No shop proximity prompts found!")
        print("[ShopService] Make sure your ProximityPrompts have 'shop' in their name")
        print("[ShopService] For example: 'Shop Proximity Prompt' or 'ShopProximityPrompt'")
    end
end

-- Start the service
ShopService:Init()

return ShopService
