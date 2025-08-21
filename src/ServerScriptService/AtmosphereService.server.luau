-- AtmosphereService.server.luau
-- Manages sky, lighting, and atmospheric effects for the marble game

local AtmosphereService = {}

-- Services
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local CONFIG = {
	-- Sky settings
	SKY_BRIGHTNESS = 0.8,
	SKY_COLOR = Color3.fromRGB(135, 206, 235), -- Sky blue
	SKY_HAZE = 0.1,
	SKY_DENSITY = 0.1,
	
	-- Sun settings
	SUN_ANGLE = math.rad(45), -- 45 degrees above horizon
	SUN_BRIGHTNESS = 2.0,
	SUN_COLOR = Color3.fromRGB(255, 255, 200), -- Warm white
	SUN_SIZE = 21,
	
	-- Moon settings
	MOON_ANGLE = math.rad(135), -- Opposite to sun
	MOON_BRIGHTNESS = 0.3,
	MOON_COLOR = Color3.fromRGB(200, 200, 255), -- Cool white
	MOON_SIZE = 11,
	
	-- Cloud settings
	CLOUD_COVERAGE = 0.3,
	CLOUD_SPEED = 0.5,
	CLOUD_DENSITY = 0.8,
	
	-- Atmospheric settings
	FOG_DENSITY = 0.01,
	FOG_COLOR = Color3.fromRGB(200, 220, 255),
	FOG_START = 100,
	FOG_END = 1000,
	
	-- Time cycle settings
	DAY_LENGTH = 300, -- 5 minutes for a full day cycle
	TRANSITION_TIME = 10, -- 10 seconds for transitions
}

-- Private variables
local currentTime = 0 -- 0 = dawn, 0.5 = noon, 1 = dusk
local isDay = true
local atmosphereEnabled = false

-- Helper function to create smooth color transitions
local function lerpColor(color1, color2, alpha)
	return Color3.new(
		color1.R + (color2.R - color1.R) * alpha,
		color1.G + (color2.G - color1.G) * alpha,
		color1.B + (color2.B - color1.B) * alpha
	)
end

-- Helper function to create smooth number transitions
local function lerpNumber(num1, num2, alpha)
	return num1 + (num2 - num1) * alpha
end

-- Initialize the sky system
function AtmosphereService:InitializeSky()
	print("AtmosphereService: Initializing sky system...")
	
	-- Set up the sky
	Lighting.Sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
	Lighting.Sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
	Lighting.Sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
	Lighting.Sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
	Lighting.Sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
	Lighting.Sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
	
	-- Set initial sky properties
	Lighting.Sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
	Lighting.Sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
	Lighting.Sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
	Lighting.Sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
	Lighting.Sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
	Lighting.Sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
	
	-- Set up atmosphere
	Lighting.Atmosphere.Density = CONFIG.SKY_DENSITY
	Lighting.Atmosphere.Offset = 0.25
	Lighting.Atmosphere.Color = CONFIG.SKY_COLOR
	Lighting.Atmosphere.Decay = Color3.fromRGB(106, 112, 125)
	Lighting.Atmosphere.Glare = 0
	Lighting.Atmosphere.Haze = CONFIG.SKY_HAZE
	
	-- Set up fog
	Lighting.FogStart = CONFIG.FOG_START
	Lighting.FogEnd = CONFIG.FOG_END
	Lighting.FogColor = CONFIG.FOG_COLOR
	
	-- Set up sun
	Lighting.SunAngularSize = CONFIG.SUN_SIZE
	Lighting.SunColor = CONFIG.SUN_COLOR
	Lighting.SunBrightness = CONFIG.SUN_BRIGHTNESS
	
	-- Set up moon
	Lighting.MoonAngularSize = CONFIG.MOON_SIZE
	Lighting.MoonColor = CONFIG.MOON_COLOR
	Lighting.MoonBrightness = CONFIG.MOON_BRIGHTNESS
	
	-- Set up global lighting
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.2
	Lighting.Brightness = 2
	Lighting.ClockTime = 12 -- Start at noon
	Lighting.GeographicLatitude = 41.9 -- New York latitude for nice seasonal changes
	
	print("AtmosphereService: Sky system initialized successfully")
end

-- Update lighting based on time of day
function AtmosphereService:UpdateLighting(time)
	local alpha = time
	
	-- Day lighting (0 to 0.5)
	if alpha <= 0.5 then
		local dayAlpha = alpha * 2 -- 0 to 1 for day
		
		-- Sun rises from dawn to noon
		Lighting.ClockTime = 6 + (dayAlpha * 6) -- 6 AM to 12 PM
		
		-- Sky gets brighter
		Lighting.Brightness = lerpNumber(1, 2, dayAlpha)
		Lighting.SunBrightness = lerpNumber(0.5, CONFIG.SUN_BRIGHTNESS, dayAlpha)
		
		-- Sky color transitions from dawn to day
		local dawnColor = Color3.fromRGB(255, 183, 77) -- Orange dawn
		local dayColor = CONFIG.SKY_COLOR
		Lighting.Sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
		Lighting.Atmosphere.Color = lerpColor(dawnColor, dayColor, dayAlpha)
		
		-- Fog becomes more transparent
		Lighting.FogEnd = lerpNumber(500, CONFIG.FOG_END, dayAlpha)
		
	-- Night lighting (0.5 to 1)
	else
		local nightAlpha = (alpha - 0.5) * 2 -- 0 to 1 for night
		
		-- Sun sets from noon to dusk
		Lighting.ClockTime = 12 + (nightAlpha * 6) -- 12 PM to 6 PM
		
		-- Sky gets darker
		Lighting.Brightness = lerpNumber(2, 0.5, nightAlpha)
		Lighting.SunBrightness = lerpNumber(CONFIG.SUN_BRIGHTNESS, 0.1, nightAlpha)
		
		-- Sky color transitions from day to dusk
		local duskColor = Color3.fromRGB(255, 183, 77) -- Orange dusk
		local nightColor = Color3.fromRGB(20, 30, 50) -- Dark blue night
		Lighting.Atmosphere.Color = lerpColor(duskColor, nightColor, nightAlpha)
		
		-- Fog becomes more dense
		Lighting.FogEnd = lerpNumber(CONFIG.FOG_END, 300, nightAlpha)
	end
	
	-- Update moon brightness (opposite to sun)
	Lighting.MoonBrightness = lerpNumber(0.1, CONFIG.MOON_BRIGHTNESS, 1 - alpha)
end

-- Create moving clouds
function AtmosphereService:CreateClouds()
	print("AtmosphereService: Creating cloud system...")
	
	-- Create a cloud container
	local cloudContainer = Instance.new("Part")
	cloudContainer.Name = "CloudContainer"
	cloudContainer.Anchored = true
	cloudContainer.CanCollide = false
	cloudContainer.Transparency = 1
	cloudContainer.Size = Vector3.new(1000, 100, 1000)
	cloudContainer.Position = Vector3.new(0, 200, 0)
	cloudContainer.Parent = workspace
	
	-- Create multiple cloud layers
	for i = 1, 3 do
		local cloudLayer = Instance.new("Part")
		cloudLayer.Name = "CloudLayer" .. i
		cloudLayer.Anchored = true
		cloudLayer.CanCollide = false
		cloudLayer.Transparency = 0.3
		cloudLayer.Size = Vector3.new(800, 2, 800)
		cloudLayer.Position = Vector3.new(0, 200 + (i * 20), 0)
		cloudLayer.Material = Enum.Material.Cloud
		cloudLayer.Color = Color3.fromRGB(255, 255, 255)
		cloudLayer.Parent = cloudContainer
		
		-- Add cloud texture
		local cloudTexture = Instance.new("Texture")
		cloudTexture.Texture = "rbxasset://textures/particles/clouds_main.dds"
		cloudTexture.StudsPerTileU = 50
		cloudTexture.StudsPerTileV = 50
		cloudTexture.Transparency = 0.5
		cloudTexture.Parent = cloudLayer
		
		-- Animate clouds moving
		local tweenInfo = TweenInfo.new(
			60 + (i * 20), -- Different speeds for each layer
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.InOut,
			-1, -- Repeat infinitely
			true -- Reverses
		)
		
		local tween = TweenService:Create(cloudLayer, tweenInfo, {
			Position = Vector3.new(400, 200 + (i * 20), 0)
		})
		tween:Play()
	end
	
	print("AtmosphereService: Cloud system created successfully")
end

-- Start the atmosphere system
function AtmosphereService:Start()
	if atmosphereEnabled then
		print("AtmosphereService: Already running")
		return
	end
	
	print("AtmosphereService: Starting atmosphere system...")
	
	-- Initialize components
	self:InitializeSky()
	self:CreateClouds()
	
	-- Start time cycle
	atmosphereEnabled = true
	
	-- Main update loop
	RunService.Heartbeat:Connect(function(deltaTime)
		if not atmosphereEnabled then return end
		
		-- Update time
		currentTime = currentTime + (deltaTime / CONFIG.DAY_LENGTH)
		if currentTime >= 1 then
			currentTime = 0
		end
		
		-- Update lighting
		self:UpdateLighting(currentTime)
	end)
	
	print("AtmosphereService: Atmosphere system started successfully")
end

-- Stop the atmosphere system
function AtmosphereService:Stop()
	if not atmosphereEnabled then
		print("AtmosphereService: Not running")
		return
	end
	
	print("AtmosphereService: Stopping atmosphere system...")
	atmosphereEnabled = false
	
	-- Clean up clouds
	local cloudContainer = workspace:FindFirstChild("CloudContainer")
	if cloudContainer then
		cloudContainer:Destroy()
	end
	
	print("AtmosphereService: Atmosphere system stopped")
end

-- Get current time of day (0-1)
function AtmosphereService:GetTimeOfDay()
	return currentTime
end

-- Check if it's currently day
function AtmosphereService:IsDay()
	return currentTime <= 0.5
end

-- Set specific time of day (0-1)
function AtmosphereService:SetTimeOfDay(time)
	currentTime = math.clamp(time, 0, 1)
	self:UpdateLighting(currentTime)
end

-- Toggle between day and night
function AtmosphereService:ToggleDayNight()
	if self:IsDay() then
		self:SetTimeOfDay(0.75) -- Set to night
	else
		self:SetTimeOfDay(0.25) -- Set to day
	end
end

return AtmosphereService
