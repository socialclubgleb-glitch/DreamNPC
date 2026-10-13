--[[
	The Endless Estate - Milestone 2
	InteractionManager.server.lua

	Centralized interaction system using CollectionService.
	Handles the smooth opening/closing of doors via TweenService.
]]--

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local TWEEN_INFO = TweenInfo.new(
	0.8, -- Duration
	Enum.EasingStyle.Quad, -- Smooth natural easing
	Enum.EasingDirection.Out
)

local function HandleDoorInteraction(doorModel, prompt, player)
	-- Prevent spam clicking while tween is playing
	if doorModel:GetAttribute("IsMoving") then return end
	doorModel:SetAttribute("IsMoving", true)

	local isOpen = doorModel:GetAttribute("IsOpen") or false
	local hinge = doorModel.PrimaryPart
	local doorPanel = doorModel:FindFirstChild("DoorPanel")

	if not hinge or not doorPanel then
		doorModel:SetAttribute("IsMoving", false)
		return
	end

	-- Calculate the target rotation (open 90 degrees or close back to 0)
	local targetRotation = isOpen and CFrame.Angles(0, math.rad(-90), 0) or CFrame.Angles(0, math.rad(90), 0)
	local targetCFrame = hinge.CFrame * targetRotation

	-- Note: Since the door panel is anchored and relative to the hinge,
	-- we need to tween the Hinge and make the DoorPanel move with it.
	-- Because TweenService doesn't automatically move welded ANCHORED parts,
	-- we will use a CFrameValue to interpolate, and update the parts every frame.

	local cframeValue = Instance.new("CFrameValue")
	cframeValue.Value = hinge.CFrame

	-- Calculate the initial offset of the panel relative to the hinge
	local panelOffset = hinge.CFrame:ToObjectSpace(doorPanel.CFrame)

	local connection
	connection = cframeValue.Changed:Connect(function(newCFrame)
		hinge.CFrame = newCFrame
		doorPanel.CFrame = newCFrame * panelOffset
	end)

	local tween = TweenService:Create(cframeValue, TWEEN_INFO, {Value = targetCFrame})
	tween:Play()

	-- Change prompt text immediately
	prompt.ActionText = isOpen and "Open" or "Close"

	tween.Completed:Connect(function()
		connection:Disconnect()
		cframeValue:Destroy()
		doorModel:SetAttribute("IsOpen", not isOpen)
		doorModel:SetAttribute("IsMoving", false)
	end)
end

local function OnDoorAdded(doorModel)
	-- Find the prompt inside the panel
	local doorPanel = doorModel:FindFirstChild("DoorPanel")
	if doorPanel then
		local prompt = doorPanel:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				HandleDoorInteraction(doorModel, prompt, player)
			end)
		end
	end
end

local function OnLootAdded(lootPart)
	local prompt = lootPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			-- In the future, we'll hook this up to a leaderstats/DataStore system
			-- For now, give feedback and destroy
			print(player.Name .. " collected Gold!")
			lootPart:Destroy()
		end)
	end
end

-- Hook up existing and future doors
for _, door in ipairs(CollectionService:GetTagged("InteractiveDoor")) do
	OnDoorAdded(door)
end
CollectionService:GetInstanceAddedSignal("InteractiveDoor"):Connect(OnDoorAdded)

-- Hook up existing and future loot
for _, loot in ipairs(CollectionService:GetTagged("LootCoin")) do
	OnLootAdded(loot)
end
CollectionService:GetInstanceAddedSignal("LootCoin"):Connect(OnLootAdded)

print("[InteractionManager] Initialized Door and Loot Interactions.")