local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents
local levelUpRemote = ReplicatedStorage:FindFirstChild("LevelUpRemote")
if not levelUpRemote then
	levelUpRemote = Instance.new("RemoteEvent")
	levelUpRemote.Name = "LevelUpRemote"
	levelUpRemote.Parent = ReplicatedStorage
end

local giveXPRemote = ReplicatedStorage:FindFirstChild("GiveXPRemote")
if not giveXPRemote then
	giveXPRemote = Instance.new("RemoteEvent")
	giveXPRemote.Name = "GiveXPRemote"
	giveXPRemote.Parent = ReplicatedStorage
end

-- XP required per level (exponential scaling)
local function getXPForLevel(level)
	return math.floor(100 * (level ^ 1.5))
end

-- Setup player stats
Players.PlayerAdded:Connect(function(player)
	-- Experience Stats
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = player

	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = 0
	xp.Parent = player

	local xpNeeded = Instance.new("IntValue")
	xpNeeded.Name = "XPNeeded"
	xpNeeded.Value = getXPForLevel(1)
	xpNeeded.Parent = player

	-- Stat Points (from leveling)
	local statPoints = Instance.new("IntValue")
	statPoints.Name = "StatPoints"
	statPoints.Value = 0
	statPoints.Parent = player

	-- Mastery Points (from leveling)
	local masteryPoints = Instance.new("IntValue")
	masteryPoints.Name = "MasteryPoints"
	masteryPoints.Value = 0
	masteryPoints.Parent = player

	-- Combat Stats (upgraded with Stat Points)
	local strength = Instance.new("IntValue")
	strength.Name = "Strength"
	strength.Value = 1
	strength.Parent = player

	local vitality = Instance.new("IntValue")
	vitality.Name = "Vitality"
	vitality.Value = 1
	vitality.Parent = player

	local endurance = Instance.new("IntValue")
	endurance.Name = "Endurance"
	endurance.Value = 1
	endurance.Parent = player

	-- Mastery Stats (upgraded with Mastery Points)
	local combatMastery = Instance.new("IntValue")
	combatMastery.Name = "CombatMastery"
	combatMastery.Value = 1
	combatMastery.Parent = player

	local miningMastery = Instance.new("IntValue")
	miningMastery.Name = "MiningMastery"
	miningMastery.Value = 1
	miningMastery.Parent = player

	local survivalMastery = Instance.new("IntValue")
	survivalMastery.Name = "SurvivalMastery"
	survivalMastery.Value = 1
	survivalMastery.Parent = player

	-- Listen for XP changes
	xp.Changed:Connect(function(newXP)
		-- Check for level up
		while newXP >= xpNeeded.Value do
			-- Level up!
			xp.Value = newXP - xpNeeded.Value
			level.Value = level.Value + 1

			-- Give rewards
			statPoints.Value = statPoints.Value + 1
			masteryPoints.Value = masteryPoints.Value + 1

			-- Update XP needed for next level
			xpNeeded.Value = getXPForLevel(level.Value)

			-- Notify player
			levelUpRemote:FireClient(player, level.Value, statPoints.Value, masteryPoints.Value)

			print("🎉 " .. player.Name .. " leveled up to level " .. level.Value)

			newXP = xp.Value
		end
	end)

	print("✅ Leveling stats created for", player.Name)
end)

-- Function to give XP
local function giveXP(player, amount, source)
	local xp = player:FindFirstChild("XP")
	if xp then
		xp.Value = xp.Value + amount

		-- Notify client
		giveXPRemote:FireClient(player, amount, source)

		print(player.Name .. " gained " .. amount .. " XP from " .. source)
	end
end

-- Make function global so other scripts can use it
_G.GiveXP = giveXP

print("✅ Leveling system ready")



-- Handle stat upgrades
local upgradeStatRemote = ReplicatedStorage:FindFirstChild("UpgradeStatRemote")
if not upgradeStatRemote then
	upgradeStatRemote = Instance.new("RemoteEvent")
	upgradeStatRemote.Name = "UpgradeStatRemote"
	upgradeStatRemote.Parent = ReplicatedStorage
end

upgradeStatRemote.OnServerEvent:Connect(function(player, upgradeType, statName)
	if upgradeType == "Stat" then
		-- Upgrade combat stat
		local statPoints = player:FindFirstChild("StatPoints")
		local stat = player:FindFirstChild(statName)

		if statPoints and stat and statPoints.Value > 0 then
			statPoints.Value = statPoints.Value - 1
			stat.Value = stat.Value + 1

			-- Apply stat effects
			if statName == "Vitality" then
				local maxHealth = player:FindFirstChild("MaxHealth")
				if maxHealth then
					maxHealth.Value = maxHealth.Value + 10
				end
			elseif statName == "Endurance" then
				local maxStamina = player:FindFirstChild("MaxStamina")
				if maxStamina then
					maxStamina.Value = maxStamina.Value + 10
				end
			end

			print(player.Name .. " upgraded " .. statName .. " to " .. stat.Value)
		end

	elseif upgradeType == "Mastery" then
		-- Upgrade mastery
		local masteryPoints = player:FindFirstChild("MasteryPoints")
		local mastery = player:FindFirstChild(statName)

		if masteryPoints and mastery and masteryPoints.Value > 0 then
			masteryPoints.Value = masteryPoints.Value - 1
			mastery.Value = mastery.Value + 1

			print(player.Name .. " upgraded " .. statName .. " to " .. mastery.Value)
		end
	end
end)