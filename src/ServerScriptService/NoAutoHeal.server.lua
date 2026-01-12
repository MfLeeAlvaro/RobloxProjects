local Players = game:GetService("Players")

-- Settings
local HEAL_RATE = 5 -- health per second
local CHECK_INTERVAL = 0.2 -- seconds
local ZONES_FOLDER = workspace:WaitForChild("Zones") -- your folder containing all zones

-- Table to track which players are in green zones
local playersInGreenZone = {}

-- Function to start healing loop for a player
local function startHealingLoop(player, humanoid)
	task.spawn(function()
		while humanoid.Parent do
			if playersInGreenZone[player] then
				humanoid.Health = math.min(humanoid.Health + HEAL_RATE * CHECK_INTERVAL, humanoid.MaxHealth)
			end
			task.wait(CHECK_INTERVAL)
		end
	end)
end

-- Setup green zones (parts named "GreenZone")
for _, zone in pairs(ZONES_FOLDER:GetChildren()) do
	if zone:IsA("BasePart") and zone.Name == "GreenZone" then
		-- Detect player entering
		zone.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if player and character:FindFirstChild("Humanoid") then
				playersInGreenZone[player] = true
			end
		end)

		-- Detect player leaving
		zone.TouchEnded:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				playersInGreenZone[player] = false
			end
		end)
	end
end

-- Player setup
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Disable auto-heal by removing health scripts
		for _, script in pairs(character:GetDescendants()) do
			if script:IsA("Script") and script.Name == "Health" then
				script:Destroy()
			end
		end

		-- Remove ForceField if any
		local forceField = character:FindFirstChild("ForceField")
		if forceField then
			forceField:Destroy()
		end

		-- Set humanoid health from stored value
		local playerHealth = player:FindFirstChild("Health")
		if playerHealth then
			humanoid.Health = playerHealth.Value
		end

		-- Start healing loop
		startHealingLoop(player, humanoid)

		print("✅ Auto-heal disabled for", player.Name, "with green zone healing")
	end)
end)
