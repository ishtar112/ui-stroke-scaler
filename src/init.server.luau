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

local DEFAULT_ADJUSTER_PARENT = game:GetService('StarterPlayer'):FindFirstChild('StarterPlayerScripts')

local SelectionService = game:GetService("Selection")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local PluginGuiService = game:GetService("PluginGuiService")

local Adjuster = script.Parent.UIStrokeScaler
local Toolbar = plugin:CreateToolbar("UIStrokeScaler")

--[[
	Removes artifacts from any cached UIStrokes, thus removing them from the cache.
]]
local function clear_cache()
	local n: number
	
	for i, stroke in CollectionService:GetTagged(TAG) do
		if stroke.ClassName ~= "UIStroke" then
			continue
		end
		
		stroke:RemoveTag(TAG)
		stroke:SetAttribute(ATTRIBUTE, nil)
		
		n = i
	end
	
	print(`Cleared {n} UIStrokes`)
end

--[[
	Inserts a copy of the plugin's LocalScript counterpart.
]]
local function insert_adjuster()
	local adjuster = Adjuster:Clone()
	local source = adjuster.Source
		:gsub("@@TAG", TAG) -- insert specified tag
		:gsub("@@ATTRIBUTE", ATTRIBUTE) -- insert specified attribute
	
	adjuster.Source  = source
	adjuster.Parent  = DEFAULT_ADJUSTER_PARENT
	adjuster.Enabled = true
end

--[[
	Returns a boolean indicating whether or not the given Instance is a valid parent.
	"Valid" in this context means an Instance that is not a descendant of an invalid directory and that a UIStroke can actually render on.
	
	@param Instance? instance
	@return boolean
]]
local function is_valid_parent( instance: Instance? ): boolean
	if instance == nil then
		return false
	elseif not instance:IsA("GuiObject") then
		return false
	elseif instance:IsDescendantOf(PluginGuiService) then
		return false
	else
		return true
	end
end

--[[
	Returns the shortest side of the given GuiObject based on the given Enum.ApplyStrokeMode.
	
	@param GuiObject object
	@param Enum.ApplyStrokeMode mode: determines whether frame size or text size should be used
	@return number
]]
local function get_shortest_side( object: GuiObject, mode: Enum.ApplyStrokeMode ): number
	local is_text_object =
		object.ClassName == "TextLabel"
		or object.ClassName == "TextButton"
		or object.ClassName == "TextBox"
	
	local bounds = if is_text_object and mode == Enum.ApplyStrokeMode.Contextual then
		(object :: TextLabel).TextBounds
		else
		object.AbsoluteSize
	
	return math.min(bounds.X, bounds.Y)
end

--[[
	Caches the given UIStrokes.
	
	@param ...UIStroke
]]
local function cache( ...: UIStroke )
	if select("#", ...) == 0 then
		return
	end
	
	local n = 0
	
	for i = 1, select("#", ...) do
		local stroke = select(i, ...) :: UIStroke
		local parent = stroke.Parent
		
		if stroke.ClassName ~= "UIStroke" then
			continue
		end
		
		if not is_valid_parent(parent) then
			continue
		end
		
		stroke:AddTag(TAG)
		stroke:SetAttribute(ATTRIBUTE, stroke.Thickness / get_shortest_side(parent :: GuiObject, stroke.ApplyStrokeMode))
		
		n += 1
	end
	
	print(`Cached {n} UIStrokes`)
end

--[[
	Updates all cached UIStrokes.
]]
local function update_cached()
	cache(unpack(CollectionService:GetTagged(TAG)))
end

--[[
	Caches any selected UIStrokes.
]]
local function cache_selected()
	cache(unpack(SelectionService:Get()))
end

--[[
	Caches any UIStrokes who are a descendant of any selected Instance.
]]
local function cache_descendants()
	local selected = SelectionService:Get()
	local instances = table.clone(selected)
	
	if next(selected) == nil then
		return
	end
	
	for _, instance in selected do
		if instance:FindFirstChildWhichIsA("UIStroke", true) == nil then
			continue
		end
		
		for _, descendant in instance:GetDescendants() do
			table.insert(instances, descendant)
			-- kind of crude b/c we aren't preventing duplicate entries, but oh well
		end
	end
	
	cache(unpack(instances))
end

--[[
	Caches any UIStrokes who are a descendant of StarterGui.
]]
local function cache_StarterGui()
	cache(unpack(StarterGui:GetDescendants()))
end

--[[
	Caches all UIStrokes in the game.
]]
local function cache_all()
	cache(unpack(game:GetDescendants()))
end

Toolbar:CreateButton(
	"clearCache",
	"Clears all cached UIStrokes.",
	"rbxassetid://76522587651332",
	"Clear"
).Click:Connect(clear_cache)

Toolbar:CreateButton(
	"insertAdjuster",
	"Inserts a LocalScript that will automatically adjust cached UIStrokes.",
	"rbxassetid://129100543703343",
	"Insert"
).Click:Connect(insert_adjuster)

Toolbar:CreateButton(
	"cacheCached",
	"Updates all cached UIStrokes.",
	"rbxassetid://87419413098446",
	"Cached"
).Click:Connect(update_cached)

Toolbar:CreateButton(
	"cacheSelected",
	"Caches currently selected UIStrokes.",
	"rbxassetid://87419413098446",
	"Selection"
).Click:Connect(cache_selected)

Toolbar:CreateButton(
	"cacheDescendants",
	"Caches any UIStrokes that are a descendant of any currently selected Instance.",
	"rbxassetid://87419413098446",
	"Descendants"
).Click:Connect(cache_descendants)

Toolbar:CreateButton(
	"cacheStarterGui",
	"Caches all UIStrokes under StarterGui.",
	"rbxassetid://87419413098446",
	"StarterGui"
).Click:Connect(cache_StarterGui)

Toolbar:CreateButton(
	"cacheAll",
	"Caches all UIStrokes in the game.",
	"rbxassetid://87419413098446",
	"All"
).Click:Connect(cache_all)
