local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Wait for Remotes
local RemotesFolder = ReplicatedStorage:WaitForChild("DreamRemotes")
local HarvestEvent = RemotesFolder:WaitForChild("HarvestEvent")
local SellEvent = RemotesFolder:WaitForChild("SellEvent")

-- Settings
local MAX_CLICK_DISTANCE = 15 -- Client side check

-- Simple UI setup for basic interactions (can be expanded later)
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DreamStealerUI"
screenGui.Parent = playerGui

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0, 300, 0, 50)
infoLabel.Position = UDim2.new(0.5, -150, 0.9, -60)
infoLabel.Text = "Click 'Zzz' NPCs to harvest Lucidity. Walk on green zone to sell."
infoLabel.TextScaled = true
infoLabel.BackgroundTransparency = 0.5
infoLabel.BackgroundColor3 = Color3.new(0, 0, 0)
infoLabel.TextColor3 = Color3.new(1, 1, 1)
infoLabel.Parent = screenGui

-- Click to harvest
mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if not target then return end

	local char = player.Character
	if not char or not char.PrimaryPart then return end

	-- Is it a Dream NPC?
	local model = target.Parent
	if model and model:IsA("Model") and model:FindFirstChild("Head") and model.Head:FindFirstChildOfClass("BillboardGui") then
		-- Check distance locally before sending
		local distance = (char.PrimaryPart.Position - target.Position).Magnitude
		if distance <= MAX_CLICK_DISTANCE then
			-- Fire server
			HarvestEvent:FireServer(model)

			-- Optional: Add a client-side visual effect (e.g., small particles flying to player)
		else
			-- Too far
			print("Too far away to harvest!")
		end
	end
end)

-- Walking into the sell zone
local debounce = false
game:GetService("RunService").RenderStepped:Connect(function()
	local char = player.Character
	if not char or not char.PrimaryPart then return end

	local workspaceSellZone = workspace:FindFirstChild("DreamWorld") and workspace.DreamWorld:FindFirstChild("SellZone")
	if workspaceSellZone then
		local dist = (char.PrimaryPart.Position - workspaceSellZone.Position).Magnitude
		if dist < (workspaceSellZone.Size.X / 2 + 2) then -- Roughly inside the zone
			if not debounce then
				debounce = true
				SellEvent:FireServer()
				task.wait(1) -- simple debounce
				debounce = false
			end
		end
	end
end)