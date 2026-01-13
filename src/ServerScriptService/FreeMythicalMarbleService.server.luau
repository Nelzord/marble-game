-- FreeMythicalMarbleService: Manages free mythical marble claims (client-side timer, no persistence)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DEBUG = true
local function dlog(...)
	if DEBUG then
		print("[FreeMythicalMarbleService]", ...)
	end
end

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
		ClaimFreeMythicalMarble = ensureEvent("ClaimFreeMythicalMarble"),
		MarbleUnlocked = ensureEvent("MarbleUnlocked"),
	}
end

local Remotes = getOrCreateRemotes()

-- Handle claim request from client (no cooldown check - client handles it)
Remotes.ClaimFreeMythicalMarble.OnServerEvent:Connect(function(player: Player)
	dlog("Claim request from", player.Name)
	
	-- Can claim! Grant Castle Marble
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
		warn("[FreeMythicalMarbleService] MarbleService not available")
		return
	end
	
	-- Check if player already has Castle marble
	local alreadyOwned = false
	if MarbleService.HasMarble and MarbleService.HasMarble(player, "Castle") then
		alreadyOwned = true
		dlog("Player", player.Name, "already has Castle marble")
	end
	
	-- Grant the marble (if not already owned)
	if not alreadyOwned then
		if MarbleService.GrantMarble then
			local success = MarbleService.GrantMarble(player, "Castle")
			if not success then
				warn("[FreeMythicalMarbleService] Failed to grant Castle marble to", player.Name)
				return
			end
			dlog("Granted Castle marble to", player.Name)
		else
			warn("[FreeMythicalMarbleService] MarbleService.GrantMarble not available")
			return
		end
	end
	
	-- Send unlock notification to client (always show 1/200 for Castle marble)
	-- Show popup even if player already owned the marble
	Remotes.MarbleUnlocked:FireClient(player, "Castle", 1, 200)
end)

dlog("FreeMythicalMarbleService initialized")

return {}
