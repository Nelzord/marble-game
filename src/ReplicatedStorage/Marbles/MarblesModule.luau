-- Central marble registry and helpers
-- Place marble models under ReplicatedStorage/MarbleModels/<MarbleId> as Model instances.
-- Abilities are in ReplicatedStorage/Marbles/Abilities/<AbilityModule>.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local marblesFolder = ReplicatedStorage:WaitForChild("Marbles")
local abilitiesFolder = marblesFolder:WaitForChild("Abilities")

export type MarbleDefinition = {
	id: string,
	name: string,
	dropDenominator: number?, -- 2 => 1/2, 3 => 1/3, etc. If nil or 0, not rollable
	rollable: boolean?,
	abilityModule: string?,
	color: Color3?,
}

local MarblesModule = {}

-- Define all marbles here. You can add more and point their model to ReplicatedStorage/MarbleModels/<id>
local DEFINITIONS: { [string]: MarbleDefinition } = {
	Default = {
		id = "Default",
		name = "Default Marble",
		dropDenominator = 0,
		rollable = false,
		abilityModule = "Default",
		color = Color3.fromRGB(230, 230, 230),
	},
	Red = {
		id = "Red",
		name = "Red Marble",
		dropDenominator = 2, -- equal weight with other colors
		rollable = true,
		abilityModule = "Default",
		color = Color3.fromRGB(220, 60, 60),
	},
	Blue = {
		id = "Blue",
		name = "Blue Marble",
		dropDenominator = 2,
		rollable = true,
		abilityModule = "Default",
		color = Color3.fromRGB(60, 120, 220),
	},
	Green = {
		id = "Green",
		name = "Green Marble",
		dropDenominator = 2,
		rollable = true,
		abilityModule = "Default",
		color = Color3.fromRGB(70, 200, 90),
	},
}

function MarblesModule.getById(id: string): MarbleDefinition?
	return DEFINITIONS[id]
end

function MarblesModule.getAll(): { MarbleDefinition }
	local list = {}
	for _, def in pairs(DEFINITIONS) do
		table.insert(list, def)
	end
	-- Sort by drop chance and then name for a stable order
	table.sort(list, function(a, b)
		local ad = a.dropDenominator or math.huge
		local bd = b.dropDenominator or math.huge
		if ad ~= bd then
			return ad < bd
		end
		return a.name < b.name
	end)
	return list
end

function MarblesModule.getRollable(): { MarbleDefinition }
	local list = {}
	for _, def in pairs(DEFINITIONS) do
		if def.rollable and def.dropDenominator and def.dropDenominator > 0 then
			table.insert(list, def)
		end
	end
	return list
end

-- Weighted roll: probability proportional to 1 / dropDenominator
function MarblesModule.roll(): MarbleDefinition?
	local candidates = {}
	local totalWeight = 0
	for _, def in pairs(DEFINITIONS) do
		if def.rollable and def.dropDenominator and def.dropDenominator > 0 then
			local weight = 1 / def.dropDenominator
			totalWeight += weight
			table.insert(candidates, { def = def, weight = weight })
		end
	end
	if totalWeight <= 0 or #candidates == 0 then
		return nil
	end
	local r = math.random()
	local cumulative = 0
	for _, c in ipairs(candidates) do
		cumulative += (c.weight / totalWeight)
		if r <= cumulative then
			return c.def
		end
	end
	return candidates[#candidates].def
end

function MarblesModule.getAbilityModule(defOrId: MarbleDefinition | string)
	local def: MarbleDefinition? = typeof(defOrId) == "table" and defOrId or DEFINITIONS[defOrId :: string]
	if not def then
		return require(abilitiesFolder:WaitForChild("Default"))
	end
	local moduleName = def.abilityModule or "Default"
	local abilityScript = abilitiesFolder:FindFirstChild(moduleName)
	if abilityScript then
		return require(abilityScript)
	end
	return require(abilitiesFolder:WaitForChild("Default"))
end

-- Clone a model for the marble if provided under ReplicatedStorage/MarbleModels/<id>
-- If not found, the server will build a simple spherical character instead.
function MarblesModule.getModelClone(defOrId: MarbleDefinition | string): Model?
	local def: MarbleDefinition? = typeof(defOrId) == "table" and defOrId or DEFINITIONS[defOrId :: string]
	if not def then return nil end
	local modelsFolder = ReplicatedStorage:FindFirstChild("MarbleModels")
	if modelsFolder then
		local model = modelsFolder:FindFirstChild(def.id)
		if model and model:IsA("Model") then
			return model:Clone()
		end
	end
	return nil
end

return MarblesModule 