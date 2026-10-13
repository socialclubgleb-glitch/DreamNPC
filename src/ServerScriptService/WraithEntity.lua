--[[
	The Endless Estate - Milestone 5
	WraithEntity.lua

	The Wraith entity logic. Travels linearly through the map from Start to the current furthest room.
	Unlike generic "Rush" clones, it damages based on Line of Sight (Raycasting).
]]--

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local WraithEntity = {}

-- Create the physical Wraith object
local function CreateWraithPart(startCFrame)
	local wraith = Instance.new("Part")
	wraith.Name = "Wraith"
	wraith.Size = Vector3.new(4, 4, 4)
	wraith.Shape = Enum.PartType.Ball
	wraith.CFrame = startCFrame
	wraith.Anchored = true
	wraith.CanCollide = false
	wraith.Color = Color3.fromRGB(0, 0, 0)
	wraith.Material = Enum.Material.Neon
	wraith.Parent = Workspace

	-- Menacing aura
	local particle = Instance.new("ParticleEmitter")
	particle.Color = ColorSequence.new(Color3.fromRGB(50, 0, 100))
	particle.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
	particle.Texture = "rbxassetid://243660364" -- Default puff
	particle.EmissionDirection = Enum.NormalId.Back
	particle.Speed = NumberRange.new(5, 10)
	particle.Parent = wraith

	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(100, 0, 200)
	pointLight.Range = 30
	pointLight.Brightness = 4
	pointLight.Parent = wraith

	return wraith
end

-- Line of Sight Raycast check
local function PerformSightCheck(wraith)
	for _, player in ipairs(Players:GetPlayers()) do
		-- Skip if player is safe in a closet
		if player:GetAttribute("IsHiding") then continue end

		local char = player.Character
		if not char or not char:FindFirstChild("Humanoid") then continue end
		local rootPart = char:FindFirstChild("HumanoidRootPart")
		if not rootPart then continue end

		local distance = (wraith.Position - rootPart.Position).Magnitude
		if distance > 60 then continue end -- Out of aura range

		-- Raycast to check for walls/obstacles
		local rayDirection = (rootPart.Position - wraith.Position).Unit * distance
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {wraith, char}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local result = Workspace:Raycast(wraith.Position, rayDirection, raycastParams)

		-- If nothing blocked the ray, the Wraith sees the player!
		if not result then
			char.Humanoid:TakeDamage(5) -- Rapid damage per frame tick while seen
		end

	end
end

-- Spawn and route the Wraith
function WraithEntity.Spawn(generatedRoomsList)
	if #generatedRoomsList == 0 then return end

	print("[Wraith] Spawning and beginning hunt...")

	local startRoom = generatedRoomsList[1]
	local wraith = CreateWraithPart(startRoom.PrimaryPart.CFrame + Vector3.new(0, 4, 0))

	-- Compile a list of CFrames to visit (PrimaryParts of all generated rooms in order)
	local pathNodes = {}
	for _, room in ipairs(generatedRoomsList) do
		if room and room.PrimaryPart then
			table.insert(pathNodes, room.PrimaryPart.CFrame + Vector3.new(0, 4, 0))
		end
	end

	-- Move function using TweenService for smooth linear travel
	local function MoveToNode(index)
		if index > #pathNodes then
			-- End of path, destroy Wraith
			wraith:Destroy()
			print("[Wraith] Hunt finished. Despawning.")
			return
		end

		local targetCFrame = pathNodes[index]
		local distance = (wraith.Position - targetCFrame.Position).Magnitude
		local speed = 60 -- Studs per second
		local duration = distance / speed

		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
		local tween = TweenService:Create(wraith, tweenInfo, {CFrame = targetCFrame})

		tween.Completed:Connect(function()
			MoveToNode(index + 1)
		end)

		tween:Play()
	end

	-- Heartbeat connection for line of sight damage loop
	local damageConnection
	damageConnection = RunService.Heartbeat:Connect(function()
		if not wraith or not wraith.Parent then
			damageConnection:Disconnect()
			return
		end
		PerformSightCheck(wraith)
	end)

	-- Start movement
	MoveToNode(1)
end

return WraithEntity