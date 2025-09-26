-- ScreenShake: Handles screen shake effects for dramatic moments

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Screen shake variables
local shakeIntensity = 0
local shakeDuration = 0
local shakeStartTime = 0
local originalCameraCFrame = nil

-- Function to start screen shake
local function startScreenShake(intensity, duration)
    shakeIntensity = intensity
    shakeDuration = duration
    shakeStartTime = tick()
    originalCameraCFrame = camera.CFrame
end

-- Function to update screen shake
local function updateScreenShake()
    if shakeDuration > 0 and shakeIntensity > 0 then
        local elapsed = tick() - shakeStartTime
        local progress = elapsed / shakeDuration
        
        if progress < 1 then
            -- Calculate shake amount (decreases over time)
            local currentIntensity = shakeIntensity * (1 - progress)
            
            -- Generate random shake offset
            local shakeX = (math.random() - 0.5) * currentIntensity
            local shakeY = (math.random() - 0.5) * currentIntensity
            local shakeZ = (math.random() - 0.5) * currentIntensity * 0.1 -- Less Z shake
            
            -- Apply shake to camera
            if originalCameraCFrame then
                local shakeOffset = Vector3.new(shakeX, shakeY, shakeZ)
                camera.CFrame = originalCameraCFrame + shakeOffset
            end
        else
            -- Reset camera to original position
            if originalCameraCFrame then
                camera.CFrame = originalCameraCFrame
            end
            shakeIntensity = 0
            shakeDuration = 0
        end
    end
end

-- Connect to screen shake remote
local function connectToScreenShake()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local screenShakeRemote = remotes:WaitForChild("ScreenShake")
    
    screenShakeRemote.OnClientEvent:Connect(function(intensity, duration)
        startScreenShake(intensity, duration)
    end)
end

-- Update screen shake every frame
RunService.Heartbeat:Connect(updateScreenShake)

-- Connect to remote
connectToScreenShake()

print("ScreenShake client script loaded")
