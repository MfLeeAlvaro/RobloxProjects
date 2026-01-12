local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvent for stamina
local staminaRemote = ReplicatedStorage:FindFirstChild("StaminaRemote")
if not staminaRemote then
	staminaRemote = Instance.new("RemoteEvent")
	staminaRemote.Name = "StaminaRemote"
	staminaRemote.Parent = ReplicatedStorage
end

Players.PlayerAdded:Connect(function(player)
	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Player Stats
	local maxHealth = Instance.new("IntValue")
	maxHealth.Name = "MaxHealth"
	maxHealth.Value = 100
	maxHealth.Parent = player

	local health = Instance.new("IntValue")
	health.Name = "Health"
	health.Value = 100
	health.Parent = player

	local maxStamina = Instance.new("IntValue")
	maxStamina.Name = "MaxStamina"
	maxStamina.Value = 100
	maxStamina.Parent = player

	local stamina = Instance.new("NumberValue") -- Changed to NumberValue for decimals
	stamina.Name = "Stamina"
	stamina.Value = 100
	stamina.Parent = player

	-- Wait for character
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- DISABLE AUTO-HEAL
		humanoid.Health = health.Value
		humanoid.MaxHealth = maxHealth.Value

		-- Sync health
		humanoid.HealthChanged:Connect(function(newHealth)
			health.Value = math.floor(newHealth)

			if newHealth <= 0 then
				health.Value = 0
			end
		end)

		-- Respawn with full health/stamina
		if humanoid.Health <= 0 then
			health.Value = maxHealth.Value
			stamina.Value = maxStamina.Value
		end
	end)

	print("✅ Stats created for", player.Name)
end)

-- Handle stamina changes from client
staminaRemote.OnServerEvent:Connect(function(player, action, amount)
	local stamina = player:FindFirstChild("Stamina")
	local maxStamina = player:FindFirstChild("MaxStamina")

	if not stamina or not maxStamina then return end

	if action == "Drain" then
		stamina.Value = math.max(0, stamina.Value - amount)
	elseif action == "Regen" then
		stamina.Value = math.min(maxStamina.Value, stamina.Value + amount)
	elseif action == "Set" then
		stamina.Value = math.clamp(amount, 0, maxStamina.Value)
	end
end)

print("✅ Player stats system ready")