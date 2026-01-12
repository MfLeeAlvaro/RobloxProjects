local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load QuestData
local QuestData = require(ReplicatedStorage.Modules.QuestData)

-- Create RemoteEvents
local questUpdateRemote = ReplicatedStorage:FindFirstChild("QuestUpdateRemote")
if not questUpdateRemote then
	questUpdateRemote = Instance.new("RemoteEvent")
	questUpdateRemote.Name = "QuestUpdateRemote"
	questUpdateRemote.Parent = ReplicatedStorage
end

local questCompleteRemote = ReplicatedStorage:FindFirstChild("QuestCompleteRemote")
if not questCompleteRemote then
	questCompleteRemote = Instance.new("RemoteEvent")
	questCompleteRemote.Name = "QuestCompleteRemote"
	questCompleteRemote.Parent = ReplicatedStorage
end

-- Player quest data storage
local playerQuests = {}

-- Initialize player quests
Players.PlayerAdded:Connect(function(player)
	-- Create quest folder for player
	local questFolder = Instance.new("Folder")
	questFolder.Name = "Quests"
	questFolder.Parent = player

	-- Initialize player quest data
	playerQuests[player.UserId] = {
		activeQuests = {}, -- {questId = {progress = {}, completed = false}}
		completedQuests = {}, -- {questId = true} for non-repeatable quests
		dailyResetTime = 0 -- Track when daily quests were last reset
	}

	-- Give starter quests based on level
	local playerLevel = player:FindFirstChild("Level")
	if playerLevel then
		task.wait(1) -- Wait for stats to initialize
		giveAvailableQuests(player)
	end

	print("✅ Quest system initialized for", player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	playerQuests[player.UserId] = nil
end)

-- Function to check if player can accept a quest
local function canAcceptQuest(player, questId)
	local quest = QuestData[questId]
	if not quest then return false end

	local playerData = playerQuests[player.UserId]
	if not playerData then return false end

	-- Check level requirement
	local playerLevel = player:FindFirstChild("Level")
	if playerLevel and playerLevel.Value < quest.level then
		return false
	end

	-- Check if already completed (non-repeatable)
	if not quest.repeatable and playerData.completedQuests[questId] then
		return false
	end

	-- Check if already active
	if playerData.activeQuests[questId] and not playerData.activeQuests[questId].completed then
		return false
	end

	-- Check if daily quest was already completed today
	if quest.daily then
		local lastReset = playerData.dailyResetTime
		local currentTime = os.time()
		local dayStart = os.time({year = os.date("*t", currentTime).year, month = os.date("*t", currentTime).month, day = os.date("*t", currentTime).day})
		
		if lastReset >= dayStart and playerData.completedQuests[questId] then
			return false
		end
	end

	return true
end

-- Function to give available quests to player
function giveAvailableQuests(player)
	local playerData = playerQuests[player.UserId]
	if not playerData then return end

	local playerLevel = player:FindFirstChild("Level")
	if not playerLevel then return end

	-- Check all quests and give available ones
	for questId, quest in pairs(QuestData) do
		if canAcceptQuest(player, questId) then
			-- Initialize quest progress
			local progress = {}
			for _, target in ipairs(quest.targets) do
				progress[#progress + 1] = {
					current = 0,
					required = target.amount,
					targetData = target
				}
			end

			playerData.activeQuests[questId] = {
				progress = progress,
				completed = false
			}

			-- Notify client
			questUpdateRemote:FireClient(player, questId, quest, progress)

			print("📋 Quest '" .. quest.name .. "' assigned to " .. player.Name)
		end
	end
end

-- Function to update quest progress
local function updateQuestProgress(player, questType, data)
	local playerData = playerQuests[player.UserId]
	if not playerData then return end

	-- Check all active quests
	for questId, questInfo in pairs(playerData.activeQuests) do
		if questInfo.completed then continue end

		local quest = QuestData[questId]
		if not quest or quest.questType ~= questType then continue end

		-- Update progress for matching targets
		for i, targetProgress in ipairs(questInfo.progress) do
			local target = targetProgress.targetData
			local matches = false

			if questType == "Kill" then
				-- Check if enemy type matches
				if target.enemyType == "Any" or target.enemyType == data.enemyType then
					matches = true
				end
			elseif questType == "Collect" then
				-- Check if item matches
				if target.itemName == "Any" or target.itemName == data.itemName then
					matches = true
				end
			elseif questType == "Visit" then
				-- Check if location matches
				if target.location == data.location then
					matches = true
				end
			end

			if matches then
				targetProgress.current = math.min(targetProgress.current + (data.amount or 1), targetProgress.required)
			end
		end

		-- Check if quest is complete
		local allComplete = true
		for _, targetProgress in ipairs(questInfo.progress) do
			if targetProgress.current < targetProgress.required then
				allComplete = false
				break
			end
		end

		if allComplete then
			completeQuest(player, questId)
		else
			-- Update client with new progress
			questUpdateRemote:FireClient(player, questId, quest, questInfo.progress)
		end
	end
end

-- Function to complete a quest
local function completeQuest(player, questId)
	local playerData = playerQuests[player.UserId]
	if not playerData then return end

	local questInfo = playerData.activeQuests[questId]
	if not questInfo or questInfo.completed then return end

	local quest = QuestData[questId]
	if not quest then return end

	-- Mark as completed
	questInfo.completed = true

	-- Give rewards
	if quest.rewards.xp and _G.GiveXP then
		_G.GiveXP(player, quest.rewards.xp, "Quest: " .. quest.name)
	end

	if quest.rewards.coins then
		-- TODO: Add coin system when available
		-- _G.GiveCoins(player, quest.rewards.coins)
		print("💰 " .. player.Name .. " earned " .. quest.rewards.coins .. " coins from quest")
	end

	if quest.rewards.statPoints then
		local statPoints = player:FindFirstChild("StatPoints")
		if statPoints then
			statPoints.Value = statPoints.Value + quest.rewards.statPoints
		end
	end

	-- Mark as completed (if not repeatable)
	if not quest.repeatable then
		playerData.completedQuests[questId] = true
	end

	-- Remove from active quests
	playerData.activeQuests[questId] = nil

	-- Notify client
	questCompleteRemote:FireClient(player, questId, quest)

	print("✅ " .. player.Name .. " completed quest: " .. quest.name)

	-- If repeatable, give it again after a delay
	if quest.repeatable then
		task.wait(2)
		if canAcceptQuest(player, questId) then
			giveAvailableQuests(player)
		end
	end
end

-- Global function for other scripts to update quests
function _G.UpdateQuest(player, questType, data)
	if not player or not player.Parent then return end
	updateQuestProgress(player, questType, data)
end

-- Global function to assign a quest to a player (called from NPCs)
function _G.AssignQuest(player, questId)
	if not player or not player.Parent then return end
	
	local playerData = playerQuests[player.UserId]
	if not playerData then return false end
	
	if not canAcceptQuest(player, questId) then
		return false
	end
	
	-- Initialize quest progress
	local quest = QuestData[questId]
	if not quest then return false end
	
	local progress = {}
	for _, target in ipairs(quest.targets) do
		progress[#progress + 1] = {
			current = 0,
			required = target.amount,
			targetData = target
		}
	end
	
	playerData.activeQuests[questId] = {
		progress = progress,
		completed = false
	}
	
	-- Notify client
	questUpdateRemote:FireClient(player, questId, quest, progress)
	
	print("📋 Quest '" .. quest.name .. "' assigned to " .. player.Name)
	return true
end

-- Handle kill quests (called from combat handler)
-- This is already handled in SimpleCombatHandler.server.lua

-- Handle collect quests (for mining)
-- TODO: Call _G.UpdateQuest(player, "Collect", {itemName = "Stone", amount = 1}) from mining handler

-- Handle visit quests (for zone exploration)
-- TODO: Call _G.UpdateQuest(player, "Visit", {location = "YellowZone"}) from zone detection

-- Daily quest reset (check every hour)
task.spawn(function()
	while true do
		task.wait(3600) -- Check every hour

		local currentTime = os.time()
		local dayStart = os.time({year = os.date("*t", currentTime).year, month = os.date("*t", currentTime).month, day = os.date("*t", currentTime).day})

		for userId, playerData in pairs(playerQuests) do
			local player = Players:GetPlayerByUserId(userId)
			if player and playerData.dailyResetTime < dayStart then
				-- Reset daily quests
				playerData.dailyResetTime = currentTime
				
				-- Remove completed daily quests
				for questId, _ in pairs(playerData.completedQuests) do
					local quest = QuestData[questId]
					if quest and quest.daily then
						playerData.completedQuests[questId] = nil
					end
				end

				-- Give new daily quests
				if player then
					giveAvailableQuests(player)
				end
			end
		end
	end
end)

print("✅ Quest Manager ready")
