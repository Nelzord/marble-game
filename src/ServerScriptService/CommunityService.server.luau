-- CommunityService: Handles community/group join prompts via ProximityPrompts
-- When a player activates a "community proximity prompt", they are prompted to join the group
-- Note: SocialService:PromptGameGroupInvite must be called from the CLIENT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GROUP_ID = 283577267 -- Marble Collector community group ID
local COMMUNITY_DEBUG = true

local function clog(...)
	if COMMUNITY_DEBUG then
		print("[CommunityService]", ...)
	end
end

clog("Initializing...")

-- Create RemoteEvent for client communication
local function getOrCreateRemote()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	
	local remote = folder:FindFirstChild("PromptCommunityJoin")
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "PromptCommunityJoin"
		remote.Parent = folder
	end
	
	return remote
end

local PromptCommunityJoin = getOrCreateRemote()

-- Function to prompt player to join the group (fires to client)
local function promptGroupJoin(player: Player)
	clog("Firing community join prompt to", player.Name, "for group", GROUP_ID)
	PromptCommunityJoin:FireClient(player)
end

-- Function to set up a single proximity prompt
local function setupProximityPrompt(proximityPrompt: ProximityPrompt)
	-- Connect to the Triggered event
	proximityPrompt.Triggered:Connect(function(player: Player)
		clog("Community proximity prompt triggered by", player.Name)
		promptGroupJoin(player)
	end)
	
	clog("Set up community proximity prompt:", proximityPrompt:GetFullName())
end

-- Function to find and set up all community proximity prompts
local function findAndSetupProximityPrompts()
	local count = 0
	
	-- Search through all descendants in workspace
	for _, descendant in pairs(workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			local name = descendant.Name:lower()
			-- Match prompts with "community" in the name (case-insensitive)
			if name:find("community") then
				setupProximityPrompt(descendant)
				count = count + 1
			end
		end
	end
	
	clog("Found and set up", count, "community proximity prompts")
	return count
end

-- Handle new proximity prompts that get added dynamically
local function onDescendantAdded(descendant: Instance)
	if descendant:IsA("ProximityPrompt") then
		local name = descendant.Name:lower()
		if name:find("community") then
			-- Small delay to ensure the prompt is fully initialized
			task.defer(function()
				setupProximityPrompt(descendant)
			end)
		end
	end
end

-- Set up existing proximity prompts
local promptCount = findAndSetupProximityPrompts()

-- Listen for new proximity prompts added to workspace
workspace.DescendantAdded:Connect(onDescendantAdded)

-- If no prompts were found, log a helpful message
if promptCount == 0 then
	clog("WARNING: No community proximity prompts found!")
	clog("Make sure your ProximityPrompts have 'community' in their name")
	clog("For example: 'Community Proximity Prompt' or 'CommunityProximityPrompt'")
end

clog("CommunityService initialized")

