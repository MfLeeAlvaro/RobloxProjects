local questData = {
	-- Starter Quests
	["first_blood"] = {
		name = "First Blood",
		description = "Kill your first zombie",
		questType = "Kill",
		targets = {
			{enemyType = "Any", amount = 1}
		},
		rewards = {
			xp = 50,
			coins = 10
		},
		level = 1,
		repeatable = false
	},

	["zombie_slayer"] = {
		name = "Zombie Slayer",
		description = "Kill 20 zombies",
		questType = "Kill",
		targets = {
			{enemyType = "Any", amount = 20}
		},
		rewards = {
			xp = 100,
			coins = 50
		},
		level = 1,
		repeatable = true
	},

	["hunter"] = {
		name = "Hunter",
		description = "Kill 5 Stalker zombies",
		questType = "Kill",
		targets = {
			{enemyType = "Stalker", amount = 5}
		},
		rewards = {
			xp = 200,
			coins = 75
		},
		level = 3,
		repeatable = true
	},

	["brute_force"] = {
		name = "Brute Force",
		description = "Kill 3 Brute zombies",
		questType = "Kill",
		targets = {
			{enemyType = "BruteZombie", amount = 3}
		},
		rewards = {
			xp = 300,
			coins = 100,
			statPoints = 1
		},
		level = 5,
		repeatable = true
	},

	--[[ Collection Quests (for when mining works)7
	["gather_stone"] = {
		name = "Gather Stone",
		description = "Mine 10 Stone",
		questType = "Collect",
		targets = {
			{itemName = "Stone", amount = 10}
		},
		rewards = {
			xp = 100,
			coins = 25
		},
		level = 1,
		repeatable = true
	},

	["precious_metals"] = {
		name = "Precious Metals",
		description = "Mine 5 Gold ore",
		questType = "Collect",
		targets = {
			{itemName = "Gold", amount = 5}
		},
		rewards = {
			xp = 250,
			coins = 150
		},
		level = 4,
		repeatable = true
	},

	-- Exploration Quests
	["explore_yellow"] = {
		name = "Into the Yellow Zone",
		description = "Enter the Yellow Zone",
		questType = "Visit",
		targets = {
			{location = "YellowZone", amount = 1}
		},
		rewards = {
			xp = 75,
			coins = 20
		},
		level = 1,
		repeatable = false
	},

	["danger_zone"] = {
		name = "Danger Ahead",
		description = "Enter the Red Zone",
		questType = "Visit",
		targets = {
			{location = "RedZone", amount = 1}
		},
		rewards = {
			xp = 200,
			coins = 100
		},
		level = 5,
		repeatable = false
	},

	-- Daily Quests
	["daily_kills"] = {
		name = "Daily Hunt",
		description = "Kill 15 zombies",
		questType = "Kill",
		targets = {
			{enemyType = "Any", amount = 15}
		},
		rewards = {
			xp = 300,
			coins = 100
		},
		level = 1,
		repeatable = false,
		daily = true
	},

	["daily_mining"] = {
		name = "Daily Mining",
		description = "Mine 20 ores",
		questType = "Collect",
		targets = {
			{itemName = "Any", amount = 20}
		},
		rewards = {
			xp = 250,
			coins = 80
		},
		level = 1,
		repeatable = false,
		daily = true
	}
--]]
}

return questData