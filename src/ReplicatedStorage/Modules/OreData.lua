local oreData = {
	Stone = {
		miningTime = 2,
		experience = 5,
		drops = {
			{item = "Stone", amount = 1, chance = 1}
		}
	},

	Coal = {
		miningTime = 3,
		experience = 10,
		drops = {
			{item = "Copper", amount = 1, chance = 1}
		}
	},

	Iron = {
		miningTime = 4,
		experience = 15,
		drops = {
			{item = "Iron", amount = 1, chance = 1}
		}
	},

	Gold = {
		miningTime = 5,
		experience = 25,
		drops = {
			{item = "Gold", amount = 1, chance = 1}
		}
	},

	Diamond = {
		miningTime = 7,
		experience = 40,
		drops = {
			{item = "Diamond", amount = 1, chance = 0.8},
			{item = "Copper", amount = 2, chance = 0.2}
		}
	}
}

return oreData--stuff to add later