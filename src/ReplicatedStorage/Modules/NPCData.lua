local npcData = {
	["QuestGiver"] = {
		name = "Elder Monkey",
		greeting = "Greetings, traveler! I have tasks that need doing.",
		quests = {
			"first_blood",
			"zombie_slayer",
			"gather_stone",
			"explore_yellow"
		},
		dialogues = {
			noQuests = "You've completed all my quests for now. Check back later!",
			questActive = "Finish your current quests first!",
			levelTooLow = "You're not ready for these challenges yet. Come back when you're stronger."
		}
	},

	["CombatMaster"] = {
		name = "Warrior Chief",
		greeting = "Prove your strength in combat, warrior!",
		quests = {
			"hunter",
			"brute_force"
		},
		dialogues = {
			noQuests = "You've proven yourself in battle. Return when you seek greater challenges!",
			questActive = "Complete your current mission before taking on another!",
			levelTooLow = "You lack the experience needed for these dangerous tasks. Train more first."
		}
	},

	["Miner"] = {
		name = "Old Prospector",
		greeting = "Hey there, partner! Need some mining work?",
		quests = {
			"gather_stone",
			"precious_metals"
		},
		dialogues = {
			noQuests = "You've mined all I need for now. Come back if you want more work!",
			questActive = "Finish gathering what I asked for first!",
			levelTooLow = "These ores are too dangerous for someone of your level. Come back stronger!"
		}
	},

	["Explorer"] = {
		name = "Scout Leader",
		greeting = "The wasteland is vast and dangerous. Help me map it out!",
		quests = {
			"explore_yellow",
			"danger_zone"
		},
		dialogues = {
			noQuests = "You've explored all the areas I know about. Great work!",
			questActive = "Complete your current exploration first!",
			levelTooLow = "Those zones are too dangerous for you right now. Level up first!"
		}
	},

	["QuestBoard"] = {
		name = "Daily Quest Board",
		greeting = "Daily challenges await those brave enough!",
		quests = {
			"daily_kills",
			"daily_mining"
		},
		dialogues = {
			noQuests = "All daily quests completed! Check back tomorrow for new challenges!",
			questActive = "You already have a daily quest active!",
			levelTooLow = "These daily quests require more experience. Come back when you're ready!"
		}
	}
}

return npcData