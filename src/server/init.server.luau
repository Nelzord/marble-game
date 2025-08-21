print("Hello world, from server!")

-- Start the atmosphere service for better sky and lighting
local AtmosphereService = require(script.Parent.Parent.ServerScriptService.AtmosphereService)
AtmosphereService:Start()

print("AtmosphereService started successfully!")