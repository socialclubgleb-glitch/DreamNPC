--[[
	The Endless Estate - Milestone 1
	RoomGenerator.server.lua

	Handles the procedural generation and alignment of rooms.
]]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RoomTemplates = ReplicatedStorage:WaitForChild("RoomTemplates")
RoomTemplates:WaitForChild("SquareRoom") -- Ensure all templates are fully built

local RoomPopulator = require(script.Parent:WaitForChild("RoomPopulator"))
local MapFolder = Instance.new("Folder")
MapFolder.Name = "EstateMap"
MapFolder.Parent = Workspace

-- Wait slightly for TemplateBuilder to finish (since they run in parallel)
task.wait(1)

local GeneratedRooms = {}
local RoomIndex = 0

local function GetRandomTemplate()
	local templates = RoomTemplates:GetChildren()
	-- Exclude StartRoom from random selection
	local validTemplates = {}
	for _, t in ipairs(templates) do
		if t.Name ~= "StartRoom" then
			table.insert(validTemplates, t)
		end
	end
	return validTemplates[math.random(1, #validTemplates)]
end

local function GenerateRoom(templateModel, previousRoom)
	local newRoom = templateModel:Clone()
	RoomIndex = RoomIndex + 1
	newRoom.Name = templateModel.Name .. "_Room_" .. tostring(RoomIndex)

	local entryPart = newRoom:FindFirstChild("Entry")
	local exitPart = newRoom:FindFirstChild("Exit")

	if not entryPart and RoomIndex > 1 then
		warn("Room template missing Entry part: " .. templateModel.Name)
		return nil
	end

	if previousRoom then
		local prevExit = previousRoom:FindFirstChild("Exit")
		if prevExit then
			-- ALIGNMENT MATH (The core of procedural rooms)
			-- We want newRoom.Entry to exactly match previousRoom.Exit

			-- 1. Get the CFrame offset from the new room's PrimaryPart to its Entry
			local primaryToEntry = newRoom.PrimaryPart.CFrame:ToObjectSpace(entryPart.CFrame)

			-- 2. We want the Entry to face the opposite direction of the Exit to snap together cleanly.
			-- Roblox CFrames face -Z. So we rotate the target CFrame by 180 degrees on Y.
			local targetCFrame = prevExit.CFrame * CFrame.Angles(0, math.rad(180), 0)

			-- 3. Apply the inverted offset to the target to find where the PrimaryPart should go
			local newPrimaryCFrame = targetCFrame * primaryToEntry:Inverse()

			newRoom:PivotTo(newPrimaryCFrame)
		end
	else
		-- First room (StartRoom)
		newRoom:PivotTo(CFrame.new(0, 0, 0))
	end

	newRoom.Parent = MapFolder

	-- Populate room with props and loot (skip start room for safety)
	if previousRoom ~= nil then
		RoomPopulator.Populate(newRoom)
	end

	table.insert(GeneratedRooms, newRoom)
	return newRoom
end

-- Generate Start Room
local startTemplate = RoomTemplates:FindFirstChild("StartRoom")
local currentRoom = GenerateRoom(startTemplate, nil)

-- Generate initial batch of rooms
local INITIAL_ROOMS = 10
for i = 1, INITIAL_ROOMS do
	local randomTemplate = GetRandomTemplate()
	currentRoom = GenerateRoom(randomTemplate, currentRoom)
end

print("[RoomGenerator] Successfully generated " .. tostring(#GeneratedRooms) .. " rooms using CFrame math.")
