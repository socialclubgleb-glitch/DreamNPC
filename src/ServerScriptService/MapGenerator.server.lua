--=========================================
-- MAP & WORLD GENERATOR (Programmatic)
--=========================================
local Workspace = game:GetService("Workspace")

local MapFolder = Instance.new("Folder")
MapFolder.Name = "DreamWorld"
MapFolder.Parent = Workspace

-- Baseplate/Ground
local Ground = Instance.new("Part")
Ground.Name = "Ground"
Ground.Size = Vector3.new(200, 1, 200)
Ground.Position = Vector3.new(0, -0.5, 0)
Ground.Anchored = true
Ground.Color = Color3.fromRGB(30, 30, 30)
Ground.Material = Enum.Material.SmoothPlastic
Ground.Parent = MapFolder

-- Sell Zone
local SellZone = Instance.new("Part")
SellZone.Name = "SellZone"
SellZone.Size = Vector3.new(15, 1, 15)
SellZone.Position = Vector3.new(-50, 0.5, 0)
SellZone.Anchored = true
SellZone.CanCollide = false
SellZone.Color = Color3.fromRGB(0, 255, 0)
SellZone.Material = Enum.Material.Neon
SellZone.Parent = MapFolder

-- Create a floating text for the sell zone
local SellGui = Instance.new("BillboardGui")
SellGui.Size = UDim2.new(0, 200, 0, 50)
SellGui.StudsOffset = Vector3.new(0, 5, 0)
SellGui.Parent = SellZone

local SellText = Instance.new("TextLabel")
SellText.Size = UDim2.new(1, 0, 1, 0)
SellText.BackgroundTransparency = 1
SellText.Text = "SELL ZONE"
SellText.TextColor3 = Color3.new(1, 1, 1)
SellText.TextScaled = true
SellText.Font = Enum.Font.LuckiestGuy
SellText.Parent = SellGui

-- Helper to create Dream NPCs
local function CreateDreamNPC(name, color, position)
	local Model = Instance.new("Model")
	Model.Name = name

	local Torso = Instance.new("Part")
	Torso.Name = "Torso"
	Torso.Size = Vector3.new(2, 2, 1)
	Torso.Position = position + Vector3.new(0, 3, 0)
	Torso.Anchored = true
	Torso.Color = color
	Torso.Parent = Model

	local Head = Instance.new("Part")
	Head.Name = "Head"
	Head.Size = Vector3.new(1, 1, 1)
	Head.Position = position + Vector3.new(0, 4.5, 0)
	Head.Anchored = true
	Head.Color = color
	Head.Parent = Model

	-- Add visual Zzz particles or simple billboard to show it's a dream target
	local ZzzGui = Instance.new("BillboardGui")
	ZzzGui.Size = UDim2.new(0, 100, 0, 50)
	ZzzGui.StudsOffset = Vector3.new(0, 2, 0)
	ZzzGui.Parent = Head

	local ZzzText = Instance.new("TextLabel")
	ZzzText.Size = UDim2.new(1, 0, 1, 0)
	ZzzText.BackgroundTransparency = 1
	ZzzText.Text = "Zzz..."
	ZzzText.TextColor3 = color
	ZzzText.TextScaled = true
	ZzzText.Font = Enum.Font.Cartoon
	ZzzText.Parent = ZzzGui

	Model.PrimaryPart = Torso
	Model.Parent = MapFolder
	return Model
end

-- Create some sleeping NPCs around the map
local npcs = {
	{Name = "Basic Dreamer", Color = Color3.fromRGB(100, 150, 255), Pos = Vector3.new(30, 0, 30)},
	{Name = "Lucid Dreamer", Color = Color3.fromRGB(255, 100, 255), Pos = Vector3.new(50, 0, -20)},
	{Name = "Nightmare", Color = Color3.fromRGB(255, 50, 50), Pos = Vector3.new(-30, 0, 40)},
}

for _, data in ipairs(npcs) do
	CreateDreamNPC(data.Name, data.Color, data.Pos)
end

print("Map and 3D Models Generated Programmatically.")