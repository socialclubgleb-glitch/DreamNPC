--[[
====================================================================================================
GAME CONCEPT: "Dream Stealer Simulator" - MONOLITHIC EDITION
----------------------------------------------------------------------------------------------------
Twist/Market Trend: Players dive into the minds of sleeping NPCs (themed zones) to steal
"Lucidity" (primary currency) using "Dreamcatchers" (harvesting tools) and store them in
"Dream Jars" (capacity backpacks). Players use Lucidity to buy better tools and jars.
Once they reach capacity, they convert it. Rebirthing grants "Astral Points" (premium/rebirth
currency) to unlock surreal new worlds (e.g., Candyland Dream, Backrooms Nightmare).

This monolithic script handles EVERYTHING:
- DataStore / Profile saving and loading
- Procedural generation of the 3D Map, Sell Zones, and Dream NPCs
- Player interactions using ClickDetectors and Touched events instead of LocalScripts
====================================================================================================
]]--

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DreamDataStore = DataStoreService:GetDataStore("DreamStealer_Release_V1")

--=========================================
-- GAME CONFIGURATION & BALANCING
--=========================================
local Config = {
	MaxHarvestDistance = 15, -- Max studs away a player can be from a dream source to harvest
	HarvestCooldown = 0.5, -- Seconds between harvest clicks to prevent auto-clicker spam
	AutoSaveInterval = 60, -- Auto-save every 60 seconds
}

local ShopData = {
	Catchers = {
		["Basic Catcher"] = { Price = 0, Multiplier = 1 },
		["Neon Catcher"]  = { Price = 100, Multiplier = 5 },
		["Void Catcher"]  = { Price = 1500, Multiplier = 25 },
		["Astral Catcher"]= { Price = 10000, Multiplier = 100 },
	},
	Jars = {
		["Small Jar"]   = { Price = 0, Capacity = 50 },
		["Glowing Jar"] = { Price = 150, Capacity = 500 },
		["Cosmic Jar"]  = { Price = 2000, Capacity = 5000 },
	}
}

-- Rebirth configuration: Required Lucidity = Base * (Multiplier ^ CurrentRebirths)
local RebirthConfig = {
	BaseCost = 50000,
	CostMultiplier = 1.5,
	AstralRewardBase = 1
}

--=========================================
-- DATA TEMPLATE & CACHE
--=========================================
local DefaultData = {
	Lucidity = 0,
	DreamsStored = 0,
	AstralPoints = 0,
	Rebirths = 0,
	Equipped = {
		Catcher = "Basic Catcher",
		Jar = "Small Jar"
	},
	Inventory = {
		Catchers = { ["Basic Catcher"] = true },
		Jars = { ["Small Jar"] = true }
	},
	SessionLock = false
}

local PlayerProfiles = {}
local ActionDebounces = {}

local function DeepCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			copy[k] = DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

--=========================================
-- DATASTORE & PROFILE LOGIC
--=========================================
local function UpdateLeaderstats(player)
	local profile = PlayerProfiles[player]
	local leaderstats = player:FindFirstChild("leaderstats")
	if profile and leaderstats then
		leaderstats.Lucidity.Value = profile.Lucidity
		leaderstats.Rebirths.Value = profile.Rebirths
		leaderstats["Astral Points"].Value = profile.AstralPoints
	end
end

local function LoadProfile(player)
	local key = "Player_" .. player.UserId
	local loadedData = nil
	local success, err = pcall(function()
		loadedData = DreamDataStore:UpdateAsync(key, function(oldData)
			local data = oldData or DeepCopy(DefaultData)
			if data.SessionLock and not RunService:IsStudio() then
				warn("Profile was session locked for " .. player.Name .. ". Forcing unlock.")
			end
			for k, v in pairs(DefaultData) do
				if data[k] == nil then data[k] = type(v) == "table" and DeepCopy(v) or v end
			end
			data.SessionLock = true
			return data
		end)
	end)

	if success and loadedData then
		PlayerProfiles[player] = loadedData
		ActionDebounces[player] = { LastHarvest = 0 }

		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"

		local lucidity = Instance.new("NumberValue")
		lucidity.Name = "Lucidity"
		lucidity.Value = loadedData.Lucidity
		lucidity.Parent = leaderstats

		local rebirths = Instance.new("IntValue")
		rebirths.Name = "Rebirths"
		rebirths.Value = loadedData.Rebirths
		rebirths.Parent = leaderstats

		local astral = Instance.new("IntValue")
		astral.Name = "Astral Points"
		astral.Value = loadedData.AstralPoints
		astral.Parent = leaderstats

		leaderstats.Parent = player
	else
		player:Kick("Failed to load data. Please rejoin. Error: " .. tostring(err))
	end
end

local function SaveProfile(player, isLeaving)
	local profile = PlayerProfiles[player]
	if not profile then return end

	local key = "Player_" .. player.UserId
	local success, err = pcall(function()
		DreamDataStore:UpdateAsync(key, function(oldData)
			if isLeaving then
				profile.SessionLock = false
			end
			return profile
		end)
	end)

	if not success then
		warn("Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end

	if isLeaving then
		PlayerProfiles[player] = nil
		ActionDebounces[player] = nil
	end
end

Players.PlayerAdded:Connect(LoadProfile)
Players.PlayerRemoving:Connect(function(player) SaveProfile(player, true) end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		SaveProfile(player, true)
	end
	task.wait(2)
end)

task.spawn(function()
	while task.wait(Config.AutoSaveInterval) do
		for _, player in ipairs(Players:GetPlayers()) do
			SaveProfile(player, false)
		end
	end
end)

--=========================================
-- SERVER-SIDE ACTION LOGIC
--=========================================

local function TryHarvest(player, targetPart)
	local profile = PlayerProfiles[player]
	local debounces = ActionDebounces[player]
	if not profile or not debounces then return end

	if tick() - debounces.LastHarvest < Config.HarvestCooldown then return end

	local char = player.Character
	if char and char.PrimaryPart then
		local distance = (char.PrimaryPart.Position - targetPart.Position).Magnitude
		if distance > Config.MaxHarvestDistance then return end
	else
		return
	end

	debounces.LastHarvest = tick()

	local equippedCatcher = profile.Equipped.Catcher
	local equippedJar = profile.Equipped.Jar
	local multiplier = ShopData.Catchers[equippedCatcher].Multiplier
	local maxCapacity = ShopData.Jars[equippedJar].Capacity

	local totalHarvest = multiplier * (1 + profile.Rebirths)

	if profile.DreamsStored < maxCapacity then
		profile.DreamsStored = math.min(profile.DreamsStored + totalHarvest, maxCapacity)
		-- Basic feedback
		local p = Instance.new("Part")
		p.Size = Vector3.new(0.5, 0.5, 0.5)
		p.Color = Color3.fromRGB(0, 255, 255)
		p.Position = char.PrimaryPart.Position + Vector3.new(0, 5, 0)
		p.Anchored = false
		p.CanCollide = false
		p.Parent = workspace
		game:GetService("Debris"):AddItem(p, 1)
	end
end

local function TrySell(player)
	local profile = PlayerProfiles[player]
	if not profile then return end

	if profile.DreamsStored > 0 then
		profile.Lucidity = profile.Lucidity + profile.DreamsStored
		profile.DreamsStored = 0
		UpdateLeaderstats(player)
	end
end

--=========================================
-- MAP & WORLD GENERATOR (Programmatic)
--=========================================
local MapFolder = Instance.new("Folder")
MapFolder.Name = "DreamWorld"
MapFolder.Parent = Workspace

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

local SellGui = Instance.new("BillboardGui")
SellGui.Size = UDim2.new(0, 200, 0, 50)
SellGui.StudsOffset = Vector3.new(0, 5, 0)
SellGui.Parent = SellZone

local SellText = Instance.new("TextLabel")
SellText.Size = UDim2.new(1, 0, 1, 0)
SellText.BackgroundTransparency = 1
SellText.Text = "SELL ZONE\n(Walk here)"
SellText.TextColor3 = Color3.new(1, 1, 1)
SellText.TextScaled = true
SellText.Font = Enum.Font.LuckiestGuy
SellText.Parent = SellGui

-- Handling Selling (Server-side touched event)
SellZone.Touched:Connect(function(hit)
	local char = hit.Parent
	local player = Players:GetPlayerFromCharacter(char)
	if player then
		TrySell(player)
	end
end)

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

	-- ClickDetector for monolithic server-side interaction
	local ClickDetector = Instance.new("ClickDetector")
	ClickDetector.MaxActivationDistance = Config.MaxHarvestDistance
	ClickDetector.Parent = Torso

	ClickDetector.MouseClick:Connect(function(player)
		TryHarvest(player, Torso)
	end)

	Model.PrimaryPart = Torso
	Model.Parent = MapFolder
	return Model
end

local npcs = {
	{Name = "Basic Dreamer", Color = Color3.fromRGB(100, 150, 255), Pos = Vector3.new(30, 0, 30)},
	{Name = "Lucid Dreamer", Color = Color3.fromRGB(255, 100, 255), Pos = Vector3.new(50, 0, -20)},
	{Name = "Nightmare", Color = Color3.fromRGB(255, 50, 50), Pos = Vector3.new(-30, 0, 40)},
}

for _, data in ipairs(npcs) do
	CreateDreamNPC(data.Name, data.Color, data.Pos)
end

print("Dream Stealer Simulator: Monolithic Server Started.")
