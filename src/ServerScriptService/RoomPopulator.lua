--[[
	The Endless Estate - Milestone 3
	RoomPopulator.lua

	Module responsible for filling generated rooms with props, interactables (closets), and loot.
]]--

local CollectionService = game:GetService("CollectionService")
local RoomPopulator = {}

local function CreateBasePart(name, size, cframe, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.Color = color
	p.Material = Enum.Material.Wood
	p.Parent = parent
	return p
end

-- Spawns a closet that players will eventually use to hide from entities
function RoomPopulator.SpawnCloset(roomModel, positionOffset)
	local closetModel = Instance.new("Model")
	closetModel.Name = "Closet"

	-- Base CFrame relative to the room's PrimaryPart
	local baseCFrame = roomModel.PrimaryPart.CFrame * positionOffset

	local body = CreateBasePart("Body", Vector3.new(4, 8, 4), baseCFrame * CFrame.new(0, 3.5, 0), Color3.fromRGB(80, 50, 30), closetModel)
	local door = CreateBasePart("Door", Vector3.new(4, 8, 0.5), baseCFrame * CFrame.new(0, 3.5, -2), Color3.fromRGB(90, 60, 40), closetModel)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hide"
	prompt.ObjectText = "Closet"
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = door

	closetModel.PrimaryPart = body
	closetModel.Parent = roomModel

	CollectionService:AddTag(closetModel, "InteractiveCloset")
end

-- Spawns collectible gold/loot
function RoomPopulator.SpawnLoot(roomModel, positionOffset)
	local loot = Instance.new("Part")
	loot.Name = "GoldCoin"
	loot.Size = Vector3.new(1, 0.2, 1)
	loot.Shape = Enum.PartType.Cylinder
	loot.CFrame = roomModel.PrimaryPart.CFrame * positionOffset * CFrame.Angles(0, 0, math.rad(90))
	loot.Anchored = true
	loot.CanCollide = false
	loot.Color = Color3.fromRGB(255, 215, 0)
	loot.Material = Enum.Material.Metal
	loot.Parent = roomModel

	-- Add a slight glow
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 215, 0)
	pointLight.Range = 5
	pointLight.Brightness = 1
	pointLight.Parent = loot

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = "Gold"
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = false
	prompt.Parent = loot

	CollectionService:AddTag(loot, "LootCoin")
end

-- Adds ambient light to the room
function RoomPopulator.SpawnLight(roomModel)
	local roof = roomModel:FindFirstChild("Roof")
	if not roof then return end

	local lightFixture = Instance.new("Part")
	lightFixture.Name = "CeilingLight"
	lightFixture.Size = Vector3.new(2, 0.5, 2)
	lightFixture.CFrame = roof.CFrame * CFrame.new(0, -roof.Size.Y/2, 0)
	lightFixture.Anchored = true
	lightFixture.Material = Enum.Material.Neon
	lightFixture.Color = Color3.fromRGB(255, 255, 200)
	lightFixture.Parent = roomModel

	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 255, 220)
	pointLight.Range = 25
	pointLight.Brightness = 2
	pointLight.Shadows = true
	pointLight.Parent = lightFixture
end

-- Main function called by RoomGenerator
function RoomPopulator.Populate(roomModel)
	-- Always spawn a light
	RoomPopulator.SpawnLight(roomModel)

	local roomType = roomModel.Name

	-- Specific populating logic based on template type
	if string.find(roomType, "SquareRoom") then
		-- Spawn a closet in the corner
		RoomPopulator.SpawnCloset(roomModel, CFrame.new(15, 0, 15) * CFrame.Angles(0, math.rad(180), 0))
		-- Spawn some loot
		RoomPopulator.SpawnLoot(roomModel, CFrame.new(-10, 0, 10))
		RoomPopulator.SpawnLoot(roomModel, CFrame.new(0, 0, 0))

	elseif string.find(roomType, "Hallway") then
		-- 30% chance for a closet in a hallway
		if math.random(1, 100) <= 30 then
			RoomPopulator.SpawnCloset(roomModel, CFrame.new(-2, 0, 0) * CFrame.Angles(0, math.rad(90), 0))
		end
		-- 50% chance for loot
		if math.random(1, 100) <= 50 then
			RoomPopulator.SpawnLoot(roomModel, CFrame.new(2, 0, -5))
		end
	end
end

return RoomPopulator
