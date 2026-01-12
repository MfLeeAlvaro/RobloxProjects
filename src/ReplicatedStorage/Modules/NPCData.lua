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