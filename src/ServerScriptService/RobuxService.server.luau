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
}

-- Robux prices (these should match your Roblox Studio settings)
local ROBUX_PRICES = {
    NukeAll = 100,
    Permanent2xLuck = 200, -- Adjust price as needed
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
        
        -- Check game pass ownership (only in normal mode)
        if not RESET_PREMIUM_ITEMS and not GIVE_PREMIUM_ITEMS then
            RobuxService:CheckGamePassOwnership(player)
        end
        
        -- Save data if debug flags are enabled
        if RESET_PREMIUM_ITEMS or GIVE_PREMIUM_ITEMS then
            savePlayerData(player)
        end
        
        -- Send data to client
        local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if Remotes and Remotes:FindFirstChild("RobuxDataUpdate") then
            Remotes.RobuxDataUpdate:FireClient(player, data.permanentLuckBonus, data.hasNukeAll)
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
    
    local success, ownsGamePass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PRODUCT_IDS.Permanent2xLuck)
    end)
    
    if success and ownsGamePass then
        -- Update player data if they own the game pass
        local data = getPlayerData(player)
        if data.permanentLuckBonus < 2 then
            data.permanentLuckBonus = 2
            savePlayerData(player)
            sendPlayerDataUpdate(player)
            clog("Player " .. player.Name .. " owns the 2x luck game pass, updating data")
        end
        return true
    elseif not success then
        clog("Failed to check game pass ownership for " .. player.Name .. ": " .. tostring(ownsGamePass))
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
        }
    end
    
    local Remotes = getOrCreateRemotes()
    
    -- Handle Robux purchases
    Remotes.RobuxPurchase.OnServerEvent:Connect(function(player, itemType)
        print("[RobuxService] Received purchase request from " .. player.Name .. " for " .. itemType)
        
        local success, message = false, "Unknown item type"
        
        if itemType == "permanent_luck" then
            success, message = RobuxService:PurchasePermanent2xLuck(player)
        elseif itemType == "nuke_all" then
            success, message = RobuxService:PurchaseNukeAll(player)
        end
        
        if success then
            print(player.Name .. " purchase prompt shown for " .. itemType)
        else
            print(player.Name .. " failed to show purchase prompt for " .. itemType .. ": " .. message)
        end
    end)
    
    -- Handle nuke all usage
    Remotes.UseNukeAll.OnServerEvent:Connect(function(player)
        print("[RobuxService] " .. player.Name .. " is using nuke all")
        local success, message = RobuxService:UseNukeAll(player)
        print(message)
    end)
    
    -- Handle MarketplaceService events
    -- Game pass purchase completed
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(playerId, gamePassId, wasPurchased)
        local player = Players:GetPlayerByUserId(playerId)
        if not player then
            clog("Player not found for UserId: " .. tostring(playerId))
            return
        end
        
        clog("Game pass purchase finished: Player=" .. player.Name .. ", GamePassId=" .. tostring(gamePassId) .. ", WasPurchased=" .. tostring(wasPurchased))
        
        if gamePassId == PRODUCT_IDS.Permanent2xLuck and wasPurchased then
            local data = getPlayerData(player)
            data.permanentLuckBonus = 2
            savePlayerData(player)
            sendPlayerDataUpdate(player)
            clog("Player " .. player.Name .. " purchased permanent 2x luck game pass!")
        else
            clog("Purchase not for permanent luck or not purchased. GamePassId: " .. tostring(gamePassId) .. ", Expected: " .. tostring(PRODUCT_IDS.Permanent2xLuck) .. ", WasPurchased: " .. tostring(wasPurchased))
        end
    end)
    
    -- Consumable purchase completed
    MarketplaceService.PromptProductPurchaseFinished:Connect(function(playerId, productId, wasPurchased)
        local player = Players:GetPlayerByUserId(playerId)
        if not player then
            clog("Player not found for UserId: " .. tostring(playerId))
            return
        end
        
        clog("Product purchase finished: Player=" .. player.Name .. ", ProductId=" .. tostring(productId) .. ", WasPurchased=" .. tostring(wasPurchased))
        
        if productId == PRODUCT_IDS.NukeAll and wasPurchased then
            clog("Nuke all purchase confirmed for " .. player.Name)
            
            -- Give the player nuke all and immediately activate it
            local data = getPlayerData(player)
            data.hasNukeAll = true
            savePlayerData(player)
            sendPlayerDataUpdate(player)
            
            -- Immediately activate the nuke
            local success, message = RobuxService:UseNukeAll(player)
            clog("Player " .. player.Name .. " purchased nuke all consumable and activated it! Success: " .. tostring(success) .. ", Message: " .. tostring(message))
        else
            clog("Purchase not for nuke all or not purchased. ProductId: " .. tostring(productId) .. ", Expected: " .. tostring(PRODUCT_IDS.NukeAll) .. ", WasPurchased: " .. tostring(wasPurchased))
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
