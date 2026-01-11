-- RobuxService: Handles Robux purchases and player data persistence
--
-- DEBUG FLAGS (for testing):
-- RESET_PREMIUM_ITEMS = true  -> Removes all premium items from players on join
-- GIVE_PREMIUM_ITEMS = true   -> Gives all premium items to players on join
-- Set both to false for normal production behavior

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

local RobuxService = {}

-- Debug flags for testing
local RESET_PREMIUM_ITEMS = true -- Set to true to remove premium items on player join for testing
local GIVE_PREMIUM_ITEMS = false -- Set to true to give premium items to players for testing

local function clog(...)
    print("[RobuxService]", ...)
end

-- Debug: Log if the reset flag is enabled
if RESET_PREMIUM_ITEMS then
    print("[RobuxService] DEBUG MODE: Premium items will be reset on player join")
end

-- Debug: Log if the give flag is enabled
if GIVE_PREMIUM_ITEMS then
    print("[RobuxService] DEBUG MODE: Players will receive premium items automatically")
end

-- Data stores
local playerDataStore = DataStoreService:GetDataStore("MarblePlayerData")

-- Player data cache
local playerData: { [Player]: { permanentLuckBonus: number, hasNukeAll: boolean } } = {}

-- Robux product IDs
local PRODUCT_IDS = {
    NukeAll = 3414278070, -- Consumable product ID for nuke all
    Permanent2xLuck = 1496268446, -- Game pass ID for 2x luck
    GoldMarble = 3505060302, -- Developer Product ID for Gold Marble (one-time purchase)
    DiamondMarble = 3505060590, -- Developer Product ID for Diamond Marble (one-time purchase)
    CoinMarble = 3510527115, -- Developer Product ID for Coin Marble (one-time purchase)
}

-- Robux prices (these should match your Roblox Studio settings)
local ROBUX_PRICES = {
    NukeAll = 100,
    Permanent2xLuck = 200, -- Sale price (original: 500)
    GoldMarble = 300,
    DiamondMarble = 500,
    CoinMarble = 350, -- Sale price (original: 1000)
}

-- Function to get or create player data
local function getPlayerData(player: Player)
    if not playerData[player] then
        playerData[player] = {
            permanentLuckBonus = 1, -- Default 1x luck
            hasNukeAll = false
        }
    end
    return playerData[player]
end

-- Function to save player data
local function savePlayerData(player: Player)
    local data = getPlayerData(player)
    task.spawn(function()
        pcall(function()
            playerDataStore:SetAsync("data_" .. player.UserId, data)
        end)
    end)
end

-- Function to load player data
local function loadPlayerData(player: Player)
    task.spawn(function()
        local data = nil
        
        -- Handle debug flags
        if RESET_PREMIUM_ITEMS then
            -- Reset premium items for testing
            data = {
                permanentLuckBonus = 1,
                hasNukeAll = false
            }
            clog("Reset premium items for player:", player.Name)
        elseif GIVE_PREMIUM_ITEMS then
            -- Give premium items for testing
            data = {
                permanentLuckBonus = 2,
                hasNukeAll = true
            }
            clog("Gave premium items to player:", player.Name)
        else
            -- Normal data loading
            local success, loadedData = pcall(function()
                return playerDataStore:GetAsync("data_" .. player.UserId)
            end)
            
            if success and loadedData then
                data = loadedData
            else
                -- Default data
                data = {
                    permanentLuckBonus = 1,
                    hasNukeAll = false
                }
            end
        end
        
        -- Set player data
        playerData[player] = data
        
        -- Check game pass ownership (only in normal mode) and wait for it to complete
        if not RESET_PREMIUM_ITEMS and not GIVE_PREMIUM_ITEMS then
            -- Check gamepass ownership synchronously before sending data
            local success, ownsGamePass = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PRODUCT_IDS.Permanent2xLuck)
            end)
            
            if success and ownsGamePass then
                -- Update player data if they own the game pass
                if data.permanentLuckBonus < 2 then
                    data.permanentLuckBonus = 2
                    savePlayerData(player)
                    clog("Player " .. player.Name .. " owns the 2x luck game pass, updating data on join")
                end
            elseif not success then
                clog("Failed to check game pass ownership for " .. player.Name .. " on join: " .. tostring(ownsGamePass))
            end
            
            -- Also check in the background in case the async check above failed
            RobuxService:CheckGamePassOwnership(player)
        end
        
        -- Save data if debug flags are enabled
        if RESET_PREMIUM_ITEMS or GIVE_PREMIUM_ITEMS then
            savePlayerData(player)
        end
        
        -- Send data to client AFTER gamepass check
        local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if Remotes and Remotes:FindFirstChild("RobuxDataUpdate") then
            Remotes.RobuxDataUpdate:FireClient(player, data.permanentLuckBonus, data.hasNukeAll)
            clog("Sent RobuxDataUpdate to " .. player.Name .. " with permanentLuckBonus: " .. tostring(data.permanentLuckBonus))
        end
    end)
end

-- Function to send player data update to client
local function sendPlayerDataUpdate(player: Player)
    local data = getPlayerData(player)
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if Remotes and Remotes:FindFirstChild("RobuxDataUpdate") then
        Remotes.RobuxDataUpdate:FireClient(player, data.permanentLuckBonus, data.hasNukeAll)
    end
    
    -- Also send luck update to reflect permanent bonus change
    -- Use ShopService's GetPlayerLuckMultiplier which handles potions internally
    local success, ShopService = pcall(function()
        return require(script.Parent.ShopService)
    end)
    if success and ShopService and ShopService.GetPlayerLuckMultiplier then
        local luckMultiplier = ShopService:GetPlayerLuckMultiplier(player)
        if Remotes and Remotes:FindFirstChild("LuckUpdate") then
            -- Calculate time left for potion (ShopService handles this internally)
            -- We'll send a request to ShopService to send the update, or calculate it here
            -- For now, just send the multiplier and let ShopService handle the time
            -- Actually, let's trigger ShopService's sendLuckUpdate function if it exists
            if ShopService.sendLuckUpdate then
                ShopService.sendLuckUpdate(player)
            else
                -- Fallback: send with 0 time left (permanent bonus only)
                Remotes.LuckUpdate:FireClient(player, luckMultiplier, 0)
            end
        end
    end
end

-- Function to get player's total luck multiplier (including permanent bonus)
function RobuxService:GetPlayerTotalLuckMultiplier(player: Player)
    local data = getPlayerData(player)
    return data.permanentLuckBonus
end

-- Function to check if player owns the game pass
function RobuxService:CheckGamePassOwnership(player: Player)
    if not player or not player.Parent then
        clog("Player is not valid for game pass check")
        return false
    end
    
    clog("Checking gamepass ownership for player: " .. player.Name .. " (UserId: " .. tostring(player.UserId) .. ")")
    
    local success, ownsGamePass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PRODUCT_IDS.Permanent2xLuck)
    end)
    
    clog("Gamepass check result for " .. player.Name .. ": success=" .. tostring(success) .. ", ownsGamePass=" .. tostring(ownsGamePass))
    
    if success and ownsGamePass then
        -- Update player data if they own the game pass
        local data = getPlayerData(player)
        clog("Current permanentLuckBonus for " .. player.Name .. ": " .. tostring(data.permanentLuckBonus))
        if data.permanentLuckBonus < 2 then
            data.permanentLuckBonus = 2
            savePlayerData(player)
            sendPlayerDataUpdate(player)
            clog("Player " .. player.Name .. " owns the 2x luck game pass, updated data from " .. tostring(data.permanentLuckBonus) .. " to 2")
        else
            clog("Player " .. player.Name .. " already has permanentLuckBonus >= 2, no update needed")
        end
        return true
    elseif not success then
        clog("Failed to check game pass ownership for " .. player.Name .. ": " .. tostring(ownsGamePass))
    else
        clog("Player " .. player.Name .. " does not own the 2x luck game pass")
    end
    
    return false
end

-- Function to check if player has nuke all
function RobuxService:HasNukeAll(player: Player)
    local data = getPlayerData(player)
    return data.hasNukeAll
end

-- Function to purchase permanent 2x luck (Game Pass)
function RobuxService:PurchasePermanent2xLuck(player: Player)
    local data = getPlayerData(player)
    if data.permanentLuckBonus >= 2 then
        return false, "You already have 2x luck or better!"
    end
    
    -- Prompt the user to purchase the game pass
    MarketplaceService:PromptGamePassPurchase(player, PRODUCT_IDS.Permanent2xLuck)
    return true, "Game pass purchase prompt shown!"
end

-- Function to purchase nuke all (Consumable)
function RobuxService:PurchaseNukeAll(player: Player)
    -- Prompt the user to purchase the consumable
    MarketplaceService:PromptProductPurchase(player, PRODUCT_IDS.NukeAll)
    return true, "Consumable purchase prompt shown!"
end

-- Function to purchase Gold Marble (Developer Product - one-time purchase)
function RobuxService:PurchaseGoldMarble(player: Player)
    clog("PurchaseGoldMarble called for player:", player.Name)
    
    -- Check if player already owns the marble
    local MarbleService = _G.MarbleService
    if MarbleService and MarbleService.HasMarble then
        local hasMarble = MarbleService.HasMarble(player, "Gold")
        clog("Player has Gold Marble:", hasMarble)
        if hasMarble then
            return false, "You already own the Gold Marble!"
        end
    else
        clog("MarbleService not available for ownership check, proceeding with purchase")
    end
    
    -- Prompt the user to purchase the developer product
    local productId = PRODUCT_IDS.GoldMarble
    clog("Prompting developer product purchase for Gold Marble, Product ID:", productId)
    
    local success, errorMsg = pcall(function()
        MarketplaceService:PromptProductPurchase(player, productId)
    end)
    
    if not success then
        clog("Error prompting product purchase:", errorMsg)
        return false, "Failed to show purchase prompt: " .. tostring(errorMsg)
    end
    
    clog("Developer product purchase prompt shown successfully for Gold Marble")
    return true, "Purchase prompt shown!"
end

-- Function to purchase Diamond Marble (Developer Product - one-time purchase)
function RobuxService:PurchaseDiamondMarble(player: Player)
    clog("PurchaseDiamondMarble called for player:", player.Name)
    
    -- Check if player already owns the marble
    local MarbleService = _G.MarbleService
    if MarbleService and MarbleService.HasMarble then
        local hasMarble = MarbleService.HasMarble(player, "Diamond")
        clog("Player has Diamond Marble:", hasMarble)
        if hasMarble then
            return false, "You already own the Diamond Marble!"
        end
    else
        clog("MarbleService not available for ownership check, proceeding with purchase")
    end
    
    -- Prompt the user to purchase the developer product
    local productId = PRODUCT_IDS.DiamondMarble
    clog("Prompting developer product purchase for Diamond Marble, Product ID:", productId)
    
    local success, errorMsg = pcall(function()
        MarketplaceService:PromptProductPurchase(player, productId)
    end)
    
    if not success then
        clog("Error prompting product purchase:", errorMsg)
        return false, "Failed to show purchase prompt: " .. tostring(errorMsg)
    end
    
    clog("Developer product purchase prompt shown successfully for Diamond Marble")
    return true, "Purchase prompt shown!"
end

-- Function to purchase Coin Marble (Developer Product - one-time purchase)
function RobuxService:PurchaseCoinMarble(player: Player)
    clog("PurchaseCoinMarble called for player:", player.Name)
    
    -- Check if player already owns the marble
    local MarbleService = _G.MarbleService
    if MarbleService and MarbleService.HasMarble then
        local hasMarble = MarbleService.HasMarble(player, "Coin")
        clog("Player has Coin Marble:", hasMarble)
        if hasMarble then
            return false, "You already own the Coin Marble!"
        end
    else
        clog("MarbleService not available for ownership check, proceeding with purchase")
    end
    
    -- Prompt the user to purchase the developer product
    local productId = PRODUCT_IDS.CoinMarble
    clog("Prompting developer product purchase for Coin Marble, Product ID:", productId)
    
    local success, errorMsg = pcall(function()
        MarketplaceService:PromptProductPurchase(player, productId)
    end)
    
    if not success then
        clog("Error prompting product purchase:", errorMsg)
        return false, "Failed to show purchase prompt: " .. tostring(errorMsg)
    end
    
    clog("Developer product purchase prompt shown successfully for Coin Marble")
    return true, "Purchase prompt shown!"
end

-- Function to grant a marble to a player
function RobuxService:GrantMarble(player: Player, marbleId: string)
    clog("GrantMarble called for player:", player.Name, "marbleId:", marbleId)
    
    -- Try to get MarbleService from _G first, then try requiring it
    local MarbleService = _G.MarbleService
    if not MarbleService then
        clog("MarbleService not in _G, trying to require it")
        local success, result = pcall(function()
            return require(script.Parent.MarbleService)
        end)
        if success and result then
            MarbleService = result
            clog("Successfully required MarbleService")
        else
            clog("Failed to require MarbleService:", result)
        end
    end
    
    if MarbleService and MarbleService.GrantMarble then
        clog("MarbleService found, calling GrantMarble function")
        -- Use . instead of : since GrantMarble is a function, not a method
        local success = MarbleService.GrantMarble(player, marbleId)
        if success then
            clog("Successfully granted " .. marbleId .. " marble to player:", player.Name)
        else
            clog("GrantMarble returned false for " .. marbleId .. " marble")
        end
        return success
    else
        clog("Failed to grant marble - MarbleService not available or missing GrantMarble function")
        clog("MarbleService available:", MarbleService ~= nil)
        if MarbleService then
            clog("GrantMarble function available:", MarbleService.GrantMarble ~= nil)
        end
        return false
    end
end

-- Function to use nuke all
function RobuxService:UseNukeAll(player: Player)
    local data = getPlayerData(player)
    if not data.hasNukeAll then
        return false, "You don't have nuke all!"
    end
    
    -- Find spawn plate for explosion effect
    local spawnPlate = workspace:FindFirstChild("Baseplate")
    local explosionPosition = Vector3.new(0, 0, 0) -- Default position
    if spawnPlate and spawnPlate:IsA("BasePart") then
        explosionPosition = spawnPlate.Position + Vector3.new(0, 5, 0)
    end
    
    -- Create explosion effect
    local explosion = Instance.new("Explosion")
    explosion.Position = explosionPosition
    explosion.BlastRadius = 200 -- Large explosion radius
    explosion.BlastPressure = 1000000 -- High pressure to ensure kills
    explosion.Visible = true
    explosion.Parent = workspace
    
    -- Create visual explosion effect
    local explosionPart = Instance.new("Part")
    explosionPart.Name = "NukeExplosion"
    explosionPart.Size = Vector3.new(50, 50, 50)
    explosionPart.Position = explosionPosition
    explosionPart.Shape = Enum.PartType.Ball
    explosionPart.Material = Enum.Material.Neon
    explosionPart.Color = Color3.fromRGB(255, 100, 0) -- Orange/red color
    explosionPart.Anchored = true
    explosionPart.CanCollide = false
    explosionPart.Parent = workspace
    
    -- Add fire effect
    local fire = Instance.new("Fire")
    fire.Size = 50
    fire.Heat = 50
    fire.Color = Color3.fromRGB(255, 100, 0)
    fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
    fire.Parent = explosionPart
    
    -- Add smoke effect
    local smoke = Instance.new("Smoke")
    smoke.Size = 50
    smoke.Opacity = 0.8
    smoke.Color = Color3.fromRGB(100, 100, 100)
    smoke.Parent = explosionPart
    
    -- Add explosion sound effect
    local explosionSound = Instance.new("Sound")
    explosionSound.SoundId = "rbxassetid://131961136" -- Explosion sound
    explosionSound.Volume = 1
    explosionSound.RollOffMaxDistance = 500
    explosionSound.Parent = explosionPart
    explosionSound:Play()
    
    -- Trigger screen shake for all players
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if Remotes then
        local screenShake = Remotes:FindFirstChild("ScreenShake")
        if screenShake then
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                screenShake:FireClient(targetPlayer, 5, 2) -- Intensity 5, duration 2 seconds
            end
        end
    end
    
    -- Kill ALL players including the one who used it
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer.Character then
            local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end
    
    -- CONSUME THE NUKE ALL (one-time use)
    data.hasNukeAll = false
    savePlayerData(player)
    sendPlayerDataUpdate(player)
    clog("Nuke all consumed for player:", player.Name)
    
    -- Clean up explosion effect after 10 seconds
    task.delay(10, function()
        if explosionPart then
            explosionPart:Destroy()
        end
    end)
    
    return true, "Nuke all activated! Everyone has been eliminated in a massive explosion! (One-time use consumed)"
end

-- Function to get Robux shop items
function RobuxService:GetRobuxShopItems()
    return {
        {
            name = "Nuke All",
            price = ROBUX_PRICES.NukeAll,
            description = "Instantly kill everyone including yourself with a massive explosion! (One-time use)",
            itemType = "nuke_all",
            productId = PRODUCT_IDS.NukeAll
        },
        {
            name = "Permanent 2x Luck",
            price = ROBUX_PRICES.Permanent2xLuck,
            description = "Permanent 2x luck bonus (applies to all potions)",
            itemType = "permanent_luck",
            productId = PRODUCT_IDS.Permanent2xLuck
        }
    }
end

-- Function to reset player's premium items (for testing)
function RobuxService:ResetPlayerPremiumItems(player: Player)
    local data = getPlayerData(player)
    data.permanentLuckBonus = 1
    data.hasNukeAll = false
    savePlayerData(player)
    sendPlayerDataUpdate(player)
    clog("Reset premium items for player:", player.Name)
    return true, "Premium items reset"
end

-- Function to give player all premium items (for testing)
function RobuxService:GivePlayerPremiumItems(player: Player)
    local data = getPlayerData(player)
    data.permanentLuckBonus = 2
    data.hasNukeAll = true
    savePlayerData(player)
    sendPlayerDataUpdate(player)
    clog("Gave premium items to player:", player.Name)
    return true, "Premium items granted"
end

-- Initialize the service
function RobuxService:Init()
    print("RobuxService initialized")
    
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
            RobuxPurchase = ensureEvent("RobuxPurchase"),
            RobuxDataUpdate = ensureEvent("RobuxDataUpdate"),
            UseNukeAll = ensureEvent("UseNukeAll"),
            ScreenShake = ensureEvent("ScreenShake"),
            RequestRobuxData = ensureEvent("RequestRobuxData"),
        }
    end
    
    local Remotes = getOrCreateRemotes()
    
    -- Handle Robux purchases
    Remotes.RobuxPurchase.OnServerEvent:Connect(function(player, itemType)
        clog("Received purchase request from " .. player.Name .. " for " .. tostring(itemType))
        
        local success, message = false, "Unknown item type"
        
        if itemType == "permanent_luck" then
            success, message = RobuxService:PurchasePermanent2xLuck(player)
        elseif itemType == "nuke_all" then
            success, message = RobuxService:PurchaseNukeAll(player)
        elseif itemType == "gold_marble" then
            clog("Handling gold_marble purchase request")
            success, message = RobuxService:PurchaseGoldMarble(player)
        elseif itemType == "diamond_marble" then
            clog("Handling diamond_marble purchase request")
            success, message = RobuxService:PurchaseDiamondMarble(player)
        elseif itemType == "coin_marble" then
            clog("Handling coin_marble purchase request")
            success, message = RobuxService:PurchaseCoinMarble(player)
        else
            clog("Unknown item type received:", itemType)
        end
        
        if success then
            clog(player.Name .. " purchase prompt shown for " .. itemType)
        else
            clog(player.Name .. " failed to show purchase prompt for " .. itemType .. ": " .. tostring(message))
        end
    end)
    
    -- Handle nuke all usage
    Remotes.UseNukeAll.OnServerEvent:Connect(function(player)
        print("[RobuxService] " .. player.Name .. " is using nuke all")
        local success, message = RobuxService:UseNukeAll(player)
        print(message)
    end)
    
    -- Handle client requesting their Robux data (for refreshing shop ownership display)
    Remotes.RequestRobuxData.OnServerEvent:Connect(function(player)
        clog("Player " .. player.Name .. " requested Robux data refresh")
        
        -- Check gamepass ownership first to ensure we have latest data
        RobuxService:CheckGamePassOwnership(player)
        
        -- Send current data to client
        local data = getPlayerData(player)
        Remotes.RobuxDataUpdate:FireClient(player, data.permanentLuckBonus, data.hasNukeAll)
        clog("Sent RobuxDataUpdate to " .. player.Name .. " on request: permanentLuckBonus=" .. tostring(data.permanentLuckBonus))
    end)
    
    -- Handle MarketplaceService events
    -- Game pass purchase completed
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(playerId, gamePassId, wasPurchased)
        -- Handle both Player object and UserId number
        local player = nil
        if typeof(playerId) == "Instance" and playerId:IsA("Player") then
            player = playerId
            clog("Received Player object directly: " .. player.Name)
        else
            local userId = tonumber(playerId)
            if not userId then
                clog("Invalid playerId received: " .. tostring(playerId) .. " (type: " .. typeof(playerId) .. ")")
                return
            end
            player = Players:GetPlayerByUserId(userId)
            if not player then
                clog("Player not found for UserId: " .. tostring(userId))
                return
            end
        end
        
        -- Convert gamePassId to number if needed
        local passId = tonumber(gamePassId)
        if not passId then
            clog("Invalid gamePassId received: " .. tostring(gamePassId) .. " (type: " .. typeof(gamePassId) .. ")")
            return
        end
        
        clog("Game pass purchase finished: Player=" .. player.Name .. ", GamePassId=" .. tostring(passId) .. ", WasPurchased=" .. tostring(wasPurchased))
        
        -- Only handle Permanent2xLuck here (it's a game pass)
        -- Gold and Diamond marbles are developer products, handled in PromptProductPurchaseFinished
        if passId == PRODUCT_IDS.Permanent2xLuck then
            -- Check if player owns the game pass (even if wasPurchased is false, they might already own it)
            local ownsGamePass = false
            local success, result = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
            end)
            if success then
                ownsGamePass = result
                clog("Player " .. player.Name .. " owns game pass " .. tostring(passId) .. ": " .. tostring(ownsGamePass))
            else
                clog("Failed to check game pass ownership: " .. tostring(result))
            end
            
            -- Grant the bonus if they own it (either just purchased or already owned)
            if wasPurchased or ownsGamePass then
                local data = getPlayerData(player)
                if data.permanentLuckBonus < 2 then
                    data.permanentLuckBonus = 2
                    savePlayerData(player)
                    sendPlayerDataUpdate(player)
                    if wasPurchased then
                        clog("Player " .. player.Name .. " purchased permanent 2x luck game pass!")
                    else
                        clog("Player " .. player.Name .. " already owns permanent 2x luck game pass, granting bonus!")
                    end
                else
                    clog("Player " .. player.Name .. " already has 2x luck bonus")
                end
            else
                clog("Permanent 2x luck purchase not completed and player doesn't own gamepass. GamePassId: " .. tostring(passId) .. ", WasPurchased: " .. tostring(wasPurchased) .. ", OwnsGamePass: " .. tostring(ownsGamePass))
            end
        else
            clog("Game pass not recognized. GamePassId: " .. tostring(passId) .. " (expected: " .. tostring(PRODUCT_IDS.Permanent2xLuck) .. "), WasPurchased: " .. tostring(wasPurchased))
        end
    end)
    
    -- Consumable purchase completed
    MarketplaceService.PromptProductPurchaseFinished:Connect(function(playerId, productId, wasPurchased)
        -- Handle both Player object and UserId number
        local player = nil
        if typeof(playerId) == "Instance" and playerId:IsA("Player") then
            player = playerId
            clog("Received Player object directly: " .. player.Name)
        else
            local userId = tonumber(playerId)
            if not userId then
                clog("Invalid playerId received: " .. tostring(playerId) .. " (type: " .. typeof(playerId) .. ")")
                return
            end
            player = Players:GetPlayerByUserId(userId)
            if not player then
                clog("Player not found for UserId: " .. tostring(userId))
                return
            end
        end
        
        -- Convert productId to number if needed
        local prodId = tonumber(productId)
        if not prodId then
            clog("Invalid productId received: " .. tostring(productId) .. " (type: " .. typeof(productId) .. ")")
            return
        end
        
        clog("Product purchase finished: Player=" .. player.Name .. ", ProductId=" .. tostring(prodId) .. ", WasPurchased=" .. tostring(wasPurchased))
        
        if prodId == PRODUCT_IDS.NukeAll and wasPurchased then
            clog("Nuke all purchase confirmed for " .. player.Name)
            
            -- Give the player nuke all and immediately activate it
            local data = getPlayerData(player)
            data.hasNukeAll = true
            savePlayerData(player)
            sendPlayerDataUpdate(player)
            
            -- Immediately activate the nuke
            local success, message = RobuxService:UseNukeAll(player)
            clog("Player " .. player.Name .. " purchased nuke all consumable and activated it! Success: " .. tostring(success) .. ", Message: " .. tostring(message))
        elseif prodId == PRODUCT_IDS.GoldMarble and wasPurchased then
            clog("Gold Marble purchase confirmed for " .. player.Name)
            
            -- Check if player already has the marble
            local MarbleService = _G.MarbleService
            if MarbleService and MarbleService.HasMarble then
                if not MarbleService.HasMarble(player, "Gold") then
                    RobuxService:GrantMarble(player, "Gold")
                    clog("Player " .. player.Name .. " purchased Gold Marble developer product!")
                else
                    clog("Player " .. player.Name .. " already has Gold Marble")
                end
            else
                -- Grant anyway if MarbleService not available
                RobuxService:GrantMarble(player, "Gold")
                clog("Player " .. player.Name .. " purchased Gold Marble developer product!")
            end
        elseif prodId == PRODUCT_IDS.DiamondMarble and wasPurchased then
            clog("Diamond Marble purchase confirmed for " .. player.Name)
            
            -- Check if player already has the marble
            local MarbleService = _G.MarbleService
            if MarbleService and MarbleService.HasMarble then
                if not MarbleService.HasMarble(player, "Diamond") then
                    RobuxService:GrantMarble(player, "Diamond")
                    clog("Player " .. player.Name .. " purchased Diamond Marble developer product!")
                else
                    clog("Player " .. player.Name .. " already has Diamond Marble")
                end
            else
                -- Grant anyway if MarbleService not available
                RobuxService:GrantMarble(player, "Diamond")
                clog("Player " .. player.Name .. " purchased Diamond Marble developer product!")
            end
        elseif prodId == PRODUCT_IDS.CoinMarble and wasPurchased then
            clog("Coin Marble purchase confirmed for " .. player.Name)
            
            -- Check if player already has the marble
            local MarbleService = _G.MarbleService
            if MarbleService and MarbleService.HasMarble then
                if not MarbleService.HasMarble(player, "Coin") then
                    RobuxService:GrantMarble(player, "Coin")
                    clog("Player " .. player.Name .. " purchased Coin Marble developer product!")
                else
                    clog("Player " .. player.Name .. " already has Coin Marble")
                end
            else
                -- Grant anyway if MarbleService not available
                RobuxService:GrantMarble(player, "Coin")
                clog("Player " .. player.Name .. " purchased Coin Marble developer product!")
            end
        else
            if prodId == PRODUCT_IDS.NukeAll or prodId == PRODUCT_IDS.GoldMarble or prodId == PRODUCT_IDS.DiamondMarble or prodId == PRODUCT_IDS.CoinMarble then
                clog("Product recognized but purchase not completed. ProductId: " .. tostring(prodId) .. ", WasPurchased: " .. tostring(wasPurchased))
            else
                clog("Product not recognized. ProductId: " .. tostring(prodId) .. " (expected NukeAll: " .. tostring(PRODUCT_IDS.NukeAll) .. ", Gold: " .. tostring(PRODUCT_IDS.GoldMarble) .. ", Diamond: " .. tostring(PRODUCT_IDS.DiamondMarble) .. ", Coin: " .. tostring(PRODUCT_IDS.CoinMarble) .. "), WasPurchased: " .. tostring(wasPurchased))
            end
        end
    end)
    
    -- Load player data when they join
    Players.PlayerAdded:Connect(function(player)
        loadPlayerData(player)
    end)
    
    -- Clean up when player leaves
    Players.PlayerRemoving:Connect(function(player)
        playerData[player] = nil
    end)
end

-- Start the service
RobuxService:Init()

return RobuxService
