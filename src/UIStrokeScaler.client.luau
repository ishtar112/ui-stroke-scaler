--[[

	Automatic UIStroke.Thickness Adjuster
	by ishtar112
	
	* Automatically adjusts the Thickness of tagged UIStrokes when parent/viewport sizes change
	+ Supports reparenting/recycling UIStrokes at runtime
	* Supports changing `scale` attribute at runtime
	* Incredibly performant (unrecognizable impact to the naked eye, even at ridiculous loads)
	* Close to no memory impact
	
	You can opt specific UIStrokes out by removing their "@@TAG" tag
	This is the counterpart to ishtar112's UIStrokeScaler plugin
	
]]

--!strict

local TAG = '@@TAG'
local ATTRIBUTE = '@@ATTRIBUTE'

local PLACEHOLDER_SCALE  = newproxy() :: number
local PLACEHOLDER_PARENT = newproxy() :: Instance
local PLACEHOLDER_FACTOR = newproxy() :: number

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

local array = {} :: { any }
-- { UIStroke, number (scale), GuiObject (parent), number (factor), repeat... }
-- using a single array to maximize cache efficiency in render step (overengineering!)

--[[
	Returns a boolean indicating whether or not the given Instance is a valid parent.
	"Valid" in this context means something that a UIStroke can actually render onto.
	
	@param Instance? instance
	@return boolean
]]
local function is_valid_parent( instance: Instance? ): boolean
	return typeof(instance) == "Instance" and instance:IsA("GuiObject")
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
	Collects the given UIStrokes.
	
	@param ...Instance
]]
local function collect( ...: Instance )
	if select("#", ...) == 0 then
		return
	end
	
	for i = 1, select("#", ...) do
		local stroke = select(i, ...) :: UIStroke
		local scale  = stroke:GetAttribute(ATTRIBUTE) :: number
		local parent = stroke.Parent
		
		if stroke.ClassName ~= "UIStroke" then
			-- something else is using our tag, ignore it
			continue
		end
		
		if type(scale) ~= "number" then
			scale = PLACEHOLDER_SCALE
		end
		
		if not is_valid_parent(parent) then
			parent = PLACEHOLDER_PARENT
		end
		
		stroke:GetAttributeChangedSignal(ATTRIBUTE):Connect(function()
			local index = table.find(array, stroke) :: number
			
			if index == nil then
				-- even though connections are disconnected when instances are destroyed-
				-- -it is still possible for this branch to be reached;
				-- this is b/c of Deferred signal behavior [when combined with a laggy client(?)]
				return
			end
			
			local scale = stroke:GetAttribute(ATTRIBUTE)
			
			if type(scale) == "number" then
				array[index + 1] = scale
			else
				array[index + 1] = PLACEHOLDER_SCALE
			end
		end)
		
		stroke:GetPropertyChangedSignal("Parent"):Connect(function()
			local index = table.find(array, stroke) :: number
			
			if index == nil then
				-- even though connections are disconnected when instances are destroyed-
				-- -it is still possible for this branch to be reached;
				-- this is b/c of Deferred signal behavior [when combined with a laggy client(?)]
				return
			end
			
			local parent = stroke.Parent
			
			if is_valid_parent(parent) then
				array[index + 2] = parent
				array[index + 3] = PLACEHOLDER_FACTOR -- trigger update next render step
			else
				array[index + 2] = PLACEHOLDER_PARENT
			end
		end)
		
		table.insert(array, stroke)
		table.insert(array, scale)
		table.insert(array, parent)
		table.insert(array, PLACEHOLDER_FACTOR) -- always initialize with placeholder, render step will update it
	end
end

RunService.PreSimulation:Connect(function()
	-- PreSimulation seems to be the best entrypoint to run UI code
	-- as it seems to produce the least visible artifacts
	
	for i = 1, #array, 4 do
		local stroke = array[i] :: UIStroke
		local scale  = array[i + 1] :: number
		local parent = array[i + 2] :: GuiObject
		
		if scale == PLACEHOLDER_SCALE or parent == PLACEHOLDER_PARENT then
			-- stroke is in an "invalid" state
			continue
		end
		
		-- make sure stroke is actually visible
		if not stroke:IsDescendantOf(PlayerGui) then
			continue
		elseif stroke:FindFirstAncestorWhichIsA("LayerCollector") == nil then
			continue
		elseif not stroke:FindFirstAncestorWhichIsA("LayerCollector").Enabled then
			continue
		elseif not parent.Visible then
			continue
		end
		
		local factor = get_shortest_side(parent, stroke.ApplyStrokeMode)
		local cached_factor = array[i + 3]
		
		if factor == cached_factor then
			-- parent size is unchanged, no work to do
			continue
		end
		
		stroke.Thickness = scale * factor
		array[i + 3] = factor
	end
end)

CollectionService:GetInstanceRemovedSignal(TAG):Connect(@native function( instance: Instance )
	-- doubles as .Destroying connection for collected UIStrokes
	local index = table.find(array, instance)
	
	if index == nil then
		-- shouldn't be possible but rather safe than sorry
		return
	end
	
	local len = #array
	
	-- swap
	array[index]     = array[len - 3]
	array[index + 1] = array[len - 2]
	array[index + 2] = array[len - 1]
	array[index + 3] = array[len]
	
	-- pop
	array[len]     = nil
	array[len - 1] = nil
	array[len - 2] = nil
	array[len - 3] = nil
end)

CollectionService:GetInstanceAddedSignal(TAG):Connect(collect)
collect(unpack(CollectionService:GetTagged(TAG)))
