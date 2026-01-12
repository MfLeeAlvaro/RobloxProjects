local ss = game:GetService("ServerStorage")
local enemyFolder = ss:WaitForChild("Enemies")

local enemyTemplates = {
	BigBlackZombie = {
		health = 150,
		speed = 14,
		damage = 15,
		attackRange = 6,
		sightRange = 60,
		respawnTime = 30,
		--attackAnimation = 115067823846471,
		model = enemyFolder.BigBlackZombie
	},

	BlackZombie = {
		health = 100,
		speed = 16,
		damage = 10,
		attackRange = 5,
		sightRange = 50,
		respawnTime = 20,
		--attackAnimation = 115067823846471,
		model = enemyFolder.BlackZombie
	},

	BruteZombie = {
		health = 200,
		speed = 12,
		damage = 20,
		attackRange = 7,
		sightRange = 55,
		respawnTime = 40,
		--attackAnimation = 115067823846471,
		model = enemyFolder.BruteZombie
	},

	ClownZombie = {
		health = 80,
		speed = 18,
		damage = 8,
		attackRange = 5,
		sightRange = 70,
		respawnTime = 15,
		--attackAnimation = 115067823846471,
		model = enemyFolder.ClownZombie
	},

	MexicanZombie = {
		health = 100,
		speed = 16,
		damage = 10,
		attackRange = 5,
		sightRange = 50,
		respawnTime = 20,
		--attackAnimation = 115067823846471,
		model = enemyFolder.MexicanZombie
	},

	MinerZombie = {
		health = 120,
		speed = 14,
		damage = 12,
		attackRange = 6,
		sightRange = 45,
		respawnTime = 25,
		--attackAnimation = 115067823846471,
		model = enemyFolder.MinerZombie
	},

	Stalker = {
		health = 60,
		speed = 22,
		damage = 5,
		attackRange = 4,
		sightRange = 100,
		respawnTime = 10,
		--attackAnimation = 115067823846471, hello im here
		model = enemyFolder.Stalker
	}
}

return enemyTemplates