--[[
	The Endless Estate - Milestone 4
	EntityEventManager.server.lua

	Central manager for triggering global events like light flickering,
	which serves as a warning before entity attacks (e.g., Rush/Ambush).
]]--

local CollectionService = game:GetService("CollectionService")

local EntityEventManager = {}

-- Function to make all lights flicker globally or in specific rooms
function EntityEventManager.FlickerLights(duration)
	local lights = CollectionService:GetTagged("FlickeringLight")
	if #lights == 0 then return end

	task.spawn(function()
		local endTime = tick() + (duration or 3)

		-- Save original materials and colors to restore later
		local originalStates = {}
		for _, lightFixture in ipairs(lights) do
			if lightFixture:IsA("BasePart") then
				local pointLight = lightFixture:FindFirstChildOfClass("PointLight")
				if pointLight then
					originalStates[lightFixture] = {
						Material = lightFixture.Material,
						Color = lightFixture.Color,
						PointLightEnabled = pointLight.Enabled
					}
				end
			end
		end

		-- Flickering loop
		while tick() < endTime do
			local isOn = math.random() > 0.5

			for lightFixture, state in pairs(originalStates) do
				local pointLight = lightFixture:FindFirstChildOfClass("PointLight")

				if isOn then
					lightFixture.Material = state.Material
					lightFixture.Color = state.Color
					if pointLight then pointLight.Enabled = true end
				else
					lightFixture.Material = Enum.Material.Plastic
					lightFixture.Color = Color3.fromRGB(50, 50, 50)
					if pointLight then pointLight.Enabled = false end
				end
			end

			task.wait(math.random(5, 15) / 100) -- Random fast flicker interval
		end

		-- Restore all lights
		for lightFixture, state in pairs(originalStates) do
			lightFixture.Material = state.Material
			lightFixture.Color = state.Color
			local pointLight = lightFixture:FindFirstChildOfClass("PointLight")
			if pointLight then pointLight.Enabled = state.PointLightEnabled end
		end
	end)
end

-- Expose for testing via Chat or other triggers later
_G.TriggerFlicker = function()
	print("[EntityEventManager] Triggering light flicker event...")
	EntityEventManager.FlickerLights(3)
end

print("[EntityEventManager] Loaded.")

return EntityEventManager