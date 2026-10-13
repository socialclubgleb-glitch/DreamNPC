--[[
	The Endless Estate - Milestone 1
	TemplateBuilder.server.lua

	This script programmatically generates base 3D room templates and places them in ReplicatedStorage.
	Each room MUST have an 'Entry' part and an 'Exit' part. These are CFrame reference points used
	for seamlessly snapping rooms together.
]]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local RoomTemplates = Instance.new("Folder")
RoomTemplates.Name = "RoomTemplates"
RoomTemplates.Parent = ReplicatedStorage

local function CreateBasePart(name, size, pos, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.Color = color or Color3.fromRGB(163, 162, 165)
	p.Material = Enum.Material.Wood
	p.Parent = parent
	return p
end

-- Helper to create attachment points
local function CreateAttachmentPoint(name, cframe, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(4, 8, 1) -- Doorway size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1 -- Invisible in real game
	p.Parent = parent

	-- Optional: visual indicator for debugging
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.Parent = p
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Text = name
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.TextColor3 = name == "Entry" and Color3.new(0,1,0) or Color3.new(1,0,0)
	text.Parent = surface

	-- Build physical interactive door at the Entry point (except StartRoom which has no entry)
	if name == "Entry" then
		local doorModel = Instance.new("Model")
		doorModel.Name = "DoorModel"

		-- Hinge part (invisible, used as rotation pivot for TweenService)
		local hinge = Instance.new("Part")
		hinge.Name = "Hinge"
		hinge.Size = Vector3.new(0.5, 8, 0.5)
		-- Position hinge to the left edge of the doorway
		hinge.CFrame = cframe * CFrame.new(-2, 0, 0)
		hinge.Anchored = true
		hinge.CanCollide = false
		hinge.Transparency = 1
		hinge.Parent = doorModel

		-- The actual physical door panel
		local doorPanel = Instance.new("Part")
		doorPanel.Name = "DoorPanel"
		doorPanel.Size = Vector3.new(4, 8, 0.5)
		-- Position panel relative to hinge (offset by half width so it rotates properly)
		doorPanel.CFrame = hinge.CFrame * CFrame.new(2, 0, 0)
		doorPanel.Anchored = true
		doorPanel.Color = Color3.fromRGB(101, 67, 33) -- Brown wood
		doorPanel.Material = Enum.Material.Wood
		doorPanel.Parent = doorModel

		-- ProximityPrompt for interaction
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = "Door"
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 8
		prompt.Parent = doorPanel

		doorModel.PrimaryPart = hinge
		doorModel.Parent = parent

		-- Tag for the InteractionManager
		CollectionService:AddTag(doorModel, "InteractiveDoor")
	end

	return p
end

local function BuildRoom_Start()
	local model = Instance.new("Model")
	model.Name = "StartRoom"

	local floor = CreateBasePart("Floor", Vector3.new(30, 1, 30), Vector3.new(0, -0.5, 0), Color3.fromRGB(80, 70, 60), model)
	local wallL = CreateBasePart("Wall", Vector3.new(1, 15, 30), Vector3.new(-14.5, 7, 0), Color3.fromRGB(50, 50, 50), model)
	local wallR = CreateBasePart("Wall", Vector3.new(1, 15, 30), Vector3.new(14.5, 7, 0), Color3.fromRGB(50, 50, 50), model)
	local wallB = CreateBasePart("Wall", Vector3.new(30, 15, 1), Vector3.new(0, 7, 14.5), Color3.fromRGB(50, 50, 50), model)
	local roof = CreateBasePart("Roof", Vector3.new(30, 1, 30), Vector3.new(0, 14.5, 0), Color3.fromRGB(30, 30, 30), model)

	-- Only an exit for the start room
	local exitPoint = CreateAttachmentPoint("Exit", CFrame.new(0, 4, -14.5), model)

	model.PrimaryPart = floor
	model.Parent = RoomTemplates
end

local function BuildRoom_Hallway()
	local model = Instance.new("Model")
	model.Name = "Hallway"

	local floor = CreateBasePart("Floor", Vector3.new(10, 1, 40), Vector3.new(0, -0.5, 0), Color3.fromRGB(100, 90, 80), model)
	local wallL = CreateBasePart("Wall", Vector3.new(1, 12, 40), Vector3.new(-4.5, 5.5, 0), Color3.fromRGB(70, 70, 70), model)
	local wallR = CreateBasePart("Wall", Vector3.new(1, 12, 40), Vector3.new(4.5, 5.5, 0), Color3.fromRGB(70, 70, 70), model)
	local roof = CreateBasePart("Roof", Vector3.new(10, 1, 40), Vector3.new(0, 11.5, 0), Color3.fromRGB(30, 30, 30), model)

	local entryPoint = CreateAttachmentPoint("Entry", CFrame.new(0, 4, 19.5) * CFrame.Angles(0, math.rad(180), 0), model)
	local exitPoint = CreateAttachmentPoint("Exit", CFrame.new(0, 4, -19.5), model)

	model.PrimaryPart = floor
	model.Parent = RoomTemplates
end

local function BuildRoom_Square()
	local model = Instance.new("Model")
	model.Name = "SquareRoom"

	local floor = CreateBasePart("Floor", Vector3.new(40, 1, 40), Vector3.new(0, -0.5, 0), Color3.fromRGB(90, 70, 70), model)
	local roof = CreateBasePart("Roof", Vector3.new(40, 1, 40), Vector3.new(0, 15.5, 0), Color3.fromRGB(30, 30, 30), model)

	-- Left wall with a hole for the exit
	local wallL1 = CreateBasePart("Wall", Vector3.new(1, 15, 16), Vector3.new(-19.5, 7, 12), Color3.fromRGB(80, 80, 80), model)
	local wallL2 = CreateBasePart("Wall", Vector3.new(1, 15, 16), Vector3.new(-19.5, 7, -12), Color3.fromRGB(80, 80, 80), model)
	local wallLTop = CreateBasePart("Wall", Vector3.new(1, 7, 8), Vector3.new(-19.5, 11.5, 0), Color3.fromRGB(80, 80, 80), model)

	local wallR = CreateBasePart("Wall", Vector3.new(1, 15, 40), Vector3.new(19.5, 7, 0), Color3.fromRGB(80, 80, 80), model)
	local wallFront = CreateBasePart("Wall", Vector3.new(40, 15, 1), Vector3.new(0, 7, -19.5), Color3.fromRGB(80, 80, 80), model)

	local entryPoint = CreateAttachmentPoint("Entry", CFrame.new(0, 4, 19.5) * CFrame.Angles(0, math.rad(180), 0), model)

	-- Let's make the exit on the left side instead of straight, to add variety (turns)
	-- To make a left exit, we face the negative X axis. Rotation is 90 degrees on Y axis.
	local exitPoint = CreateAttachmentPoint("Exit", CFrame.new(-19.5, 4, 0) * CFrame.Angles(0, math.rad(90), 0), model)

	model.PrimaryPart = floor
	model.Parent = RoomTemplates
end

-- Initialize Templates
BuildRoom_Start()
BuildRoom_Hallway()
BuildRoom_Square()

print("[TemplateBuilder] Built 3 room templates.")
