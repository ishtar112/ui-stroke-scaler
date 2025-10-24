--[[

	UIStrokeScaler -- another UIStroke.Thickness scale implementation
	by ishtar112
	
	* Convenient tools for an easier workflow
	* Blazingly performant runtime implementation
	* Minimal memory impact
	
]]

--!strict

local TAG = "@scaled" -- tag applied to scaled UIStrokes
local ATTRIBUTE = "scale" -- UIStroke attribute used to calculate thickness

local ADJUSTER = script.Parent:FindFirstChild("UIStrokeScaler")
local ADJUSTER_PARENT = game:GetService('StarterPlayer'):FindFirstChild('StarterPlayerScripts')

local ContextualApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local SelectionService = game:GetService("Selection")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local PluginGuiService = game:GetService("PluginGuiService")
	
local TOOLBAR = plugin:CreateToolbar("UIStrokeScaler")

local IsA = script.IsA
local AddTag = script.AddTag
local RemoveTag = script.RemoveTag
local SetAttribute = script.SetAttribute
local IsDescendantOf = script.IsDescendantOf
local GetDescendants = script.GetDescendants
local FindFirstChildWhichIsA = script.FindFirstChildWhichIsA

@native local function getUIStrokes( instances: { Instance } ): ...UIStroke
	local len = #instances
	
	if len > 0 then
		for i = len, 1, -1 do
			if instances[i].ClassName == "UIStroke" then
				continue
			end
			
			instances[i] = instances[len]
			instances[len] = nil
			
			len -= 1
		end
	end
	
	return unpack(instances :: any)
end

local function clearCache()
	local strokes = { getUIStrokes(CollectionService:GetTagged(TAG)) }
	local n: number
	
	if next(strokes) == nil then
		return
	end
	
	for i, stroke in strokes do
		RemoveTag(stroke, TAG)
		SetAttribute(stroke, ATTRIBUTE, nil)
		
		n = i
	end
	
	print(`Cleared {n} UIStrokes`)
end

local function insertAdjuster()
	local adjuster = ADJUSTER:Clone()
	local source = adjuster.Source
		:gsub("@@TAG", TAG) -- insert specified tag
		:gsub("@@ATTRIBUTE", ATTRIBUTE) -- insert specified attribute
	
	adjuster.Source  = source
	adjuster.Parent  = ADJUSTER_PARENT
	adjuster.Enabled = true
end

local function isTextObject( instance: Instance ): boolean
	return instance.ClassName == "TextLabel" or instance.ClassName == "TextButton" or instance.ClassName == "TextBox"
end

local function cacheUIStrokes( ...: UIStroke )
	if select("#", ...) == 0 then
		return
	end
	
	local n = 0
	
	for i = 1, select("#", ...) do
		local stroke = select(i, ...) :: UIStroke
		local parent = stroke.Parent
		
		if parent == nil then
			continue
		elseif not IsA(parent, "GuiObject") then
			continue
		elseif IsDescendantOf(stroke, PluginGuiService) then
			continue
		end
		
		local bounds = if isTextObject(parent) and stroke.ApplyStrokeMode == ContextualApplyStrokeMode then
			(parent :: TextLabel).TextBounds
			else
			(parent :: GuiObject).AbsoluteSize
		
		local denominator = math.min(bounds.X, bounds.Y)
		local scale = stroke.Thickness / denominator
		
		AddTag(stroke, TAG)
		SetAttribute(stroke, ATTRIBUTE, scale)
		
		n += 1
	end
	
	print(`Cached {n} UIStrokes`)
end

local function cacheCached()
	cacheUIStrokes(getUIStrokes(CollectionService:GetTagged(TAG)))
end

local function cacheSelected()
	cacheUIStrokes(getUIStrokes(SelectionService:Get()))
end

local function cacheDescendants()
	local selected = SelectionService:Get()
	local instances = table.clone(selected)
	
	if next(selected) == nil then
		return
	end
	
	for _, instance in selected do
		if FindFirstChildWhichIsA(instance, "UIStroke", true) == nil then
			continue
		end
		
		for _, descendant in GetDescendants(instance) do
			table.insert(instances, descendant)
			-- kind of crude b/c we aren't preventing duplicate entries, but oh well
		end
	end
	
	cacheUIStrokes(getUIStrokes(instances))
end

local function cacheStarterGui()
	cacheUIStrokes(getUIStrokes(GetDescendants(StarterGui)))
end

local function cacheAll()
	cacheUIStrokes(getUIStrokes(GetDescendants(game)))
end

-- create a button to clear all cached UIStrokes
TOOLBAR:CreateButton(
	"clearCache",
	"Clears all cached UIStrokes.",
	"rbxassetid://76522587651332",
	"Clear"
).Click:Connect(clearCache)

-- create button to insert auto-adjustment LocalScript
TOOLBAR:CreateButton(
	"insertAdjuster",
	"Inserts a LocalScript that will automatically adjust cached UIStrokes.",
	"rbxassetid://129100543703343",
	"Insert"
).Click:Connect(insertAdjuster)

-- create button to update all cached UIStrokes
TOOLBAR:CreateButton(
	"cacheCached",
	"Updates all cached UIStrokes.",
	"rbxassetid://87419413098446",
	"Cached"
).Click:Connect(cacheCached)

-- create button to cache the actively selected UIStrokes
TOOLBAR:CreateButton(
	"cacheSelected",
	"Caches currently selected UIStrokes.",
	"rbxassetid://87419413098446",
	"Selection"
).Click:Connect(cacheSelected)

-- create button to cache descendant UIStrokes of any actively selected Instance
TOOLBAR:CreateButton(
	"cacheDescendants",
	"Caches any UIStrokes that are a descendant of any currently selected Instance.",
	"rbxassetid://87419413098446",
	"Descendants"
).Click:Connect(cacheDescendants)

-- create button to cache all UIStrokes in StarterGui
TOOLBAR:CreateButton(
	"cacheStarterGui",
	"Caches all UIStrokes under StarterGui.",
	"rbxassetid://87419413098446",
	"StarterGui"
).Click:Connect(cacheStarterGui)

-- create button to cache all all UIStrokes in the datamodel
TOOLBAR:CreateButton(
	"cacheAll",
	"Caches all UIStrokes in the game.",
	"rbxassetid://87419413098446",
	"All"
).Click:Connect(cacheAll)
