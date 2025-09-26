print("Hello world, from server!")

-- Start the atmosphere service for better sky and lighting
local AtmosphereService = require(script.Parent.Parent.ServerScriptService.AtmosphereService)
AtmosphereService:Start()
print("AtmosphereService started successfully!")

-- Initialize CoinService
local CoinService = require(script.Parent.Parent.ServerScriptService.CoinService)
print("CoinService loaded successfully!")

-- Initialize MarbleService
local MarbleService = require(script.Parent.Parent.ServerScriptService.MarbleService)
print("MarbleService loaded successfully!")

-- Initialize BadgeService
local BadgeService = require(script.Parent.Parent.ServerScriptService.BadgeService)
print("BadgeService loaded successfully!")

-- Initialize ShopService
local ShopService = require(script.Parent.Parent.ServerScriptService.ShopService)
print("ShopService loaded successfully!")