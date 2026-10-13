--[[
	The Endless Estate - Milestone 4
	AtmosphereController.client.lua

	Handles client-side visual and audio atmosphere to create a horror vibe.
]]--

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Configure base horror lighting
local function SetupBaseLighting()
	Lighting.Ambient = Color3.fromRGB(15, 15, 20)
	Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 15)
	Lighting.Brightness = 0.5
	Lighting.GlobalShadows = true
	Lighting.Technology = Enum.Technology.Future -- Best for dynamic horror lighting

	Lighting.FogColor = Color3.fromRGB(5, 5, 8)
	Lighting.FogEnd = 150
	Lighting.FogStart = 20

	-- Optional ColorCorrection for a slightly desaturated, gritty look
	local cc = Lighting:FindFirstChild("HorrorCC")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "HorrorCC"
		cc.Saturation = -0.3
		cc.Contrast = 0.2
		cc.TintColor = Color3.fromRGB(240, 240, 255)
		cc.Parent = Lighting
	end
end

-- Manage dynamic atmosphere based on the room the player is in
local function CheckCurrentRoom()
	local char = player.Character
	if not char or not char.PrimaryPart then return end

	-- Simple raycast downwards to find which room floor the player is standing on
	local rayOrigin = char.PrimaryPart.Position
	local rayDirection = Vector3.new(0, -10, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {char}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result and result.Instance then
		-- Traverse up to find the Room model
		local roomModel = result.Instance:FindFirstAncestorOfClass("Model")
		if roomModel and roomModel.Name:match("Room") then

			-- Dark Room Logic
			if roomModel:GetAttribute("IsDarkRoom") then
				-- Drop visibility drastically in dark rooms
				Lighting.FogEnd = 40
				Lighting.Ambient = Color3.fromRGB(2, 2, 2)
			else
				-- Restore normal visibility
				Lighting.FogEnd = 150
				Lighting.Ambient = Color3.fromRGB(15, 15, 20)
			end

		end
	end
end

SetupBaseLighting()

-- Periodically check the current room for dynamic atmosphere shifts (e.g., entering a dark room)
local timeSinceLastCheck = 0
RunService.Heartbeat:Connect(function(deltaTime)
	timeSinceLastCheck = timeSinceLastCheck + deltaTime
	if timeSinceLastCheck >= 0.2 then
		timeSinceLastCheck = 0
		CheckCurrentRoom()
	end
end)

print("[AtmosphereController] Client atmosphere initialized.")