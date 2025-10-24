--!strict

local DEBUG_INTERVAL = 10 -- in seconds

local CHANGE_UISCALE_INTERVAL = 1/2 -- in seconds
local CHANGE_STROKE_SCALE_INTERVAL = 3 -- in seconds

local GENERATE_FRAME_INTERVAL = 0.1 -- in seconds
local FRAME_LIFESPAN = 10 -- in seconds
local MAX_FRAMES = 1000

local TEMPLATE = script:FindFirstChild("Frame")
local SCREEN_GUI = script:FindFirstChild("ScreenGui")

task.spawn(function()
	while task.wait(GENERATE_FRAME_INTERVAL) do
		if #SCREEN_GUI:GetChildren() == MAX_FRAMES then
			continue
		end
		
		local frame = TEMPLATE:Clone()
		
		frame.Position = UDim2.fromScale(math.random(), math.random())
		frame.UIScale.Scale = math.random()
		frame.Parent = SCREEN_GUI
		
		if FRAME_LIFESPAN > 0 then
			task.delay(FRAME_LIFESPAN, frame.Destroy, frame)
		end
	end
end)

task.spawn(function()
	while task.wait(CHANGE_UISCALE_INTERVAL) do
		for _, frame in SCREEN_GUI:GetChildren() do
			frame.UIScale.Scale = math.random()
		end
	end
end)

task.spawn(function()
	while task.wait(CHANGE_STROKE_SCALE_INTERVAL) do
		for _, frame in SCREEN_GUI:GetChildren() do
			frame.UIStroke:SetAttribute("scale", math.random())
		end
	end
end)

task.spawn(function()
	while task.wait(DEBUG_INTERVAL) do
		print(#SCREEN_GUI:GetChildren())
	end
end)

SCREEN_GUI.Parent = script:FindFirstAncestorOfClass("Player"):FindFirstChild("PlayerGui")
