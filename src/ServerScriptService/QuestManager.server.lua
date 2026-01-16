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

	-- Give only the starter quest "first_blood" automatically
	local playerLevel = player:FindFirstChild("Level")
	if playerLevel then
		task.wait(1) -- Wait for stats to initialize
		-- Only give the starter quest automatically, let NPCs give the rest
		if canAcceptQuest(player, "first_blood") then
			_G.AssignQuest(player, "first_blood")
		end
	end

	print("✅ Quest system initialized for", player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	playerQuests[player.UserId] = nil
end)

-- Function to check if player can accept a quest
local function canAcceptQuest(player, questId)
	local quest = QuestData[questId]
	if not quest then 
		warn("canAcceptQuest: Quest not found:", questId)
		return false 
	end

	local playerData = playerQuests[player.UserId]
	if not playerData then 
		warn("canAcceptQuest: Player data not found for:", player.Name)
		return false 
	end

	-- Check level requirement
	local playerLevel = player:FindFirstChild("Level")
	local playerLevelValue = playerLevel and playerLevel.Value or 1
	if playerLevelValue < quest.level then
		print("   canAcceptQuest: Level too low for " .. questId .. " (need " .. quest.level .. ", have " .. playerLevelValue .. ")")
		return false
	end

	-- Check if already completed (non-repeatable)
	if not quest.repeatable and playerData.completedQuests[questId] then
		print("   canAcceptQuest: Quest " .. questId .. " already completed (not repeatable)")
		return false
	end

	-- Check if already active (but allow if it's completed and repeatable)
	local activeQuest = playerData.activeQuests[questId]
	if activeQuest and not activeQuest.completed then
		print("   canAcceptQuest: Quest " .. questId .. " already active (not completed yet)")
		return false
	end
	-- If quest is completed and repeatable, allow accepting it again
	if activeQuest and activeQuest.completed and quest.repeatable then
		print("   canAcceptQuest: Quest " .. questId .. " completed but repeatable - can accept again")
		-- Note: The quest should have been removed from activeQuests when completed, but just in case
	end

	-- Check if daily quest was already completed today
	if quest.daily then
		local lastReset = playerData.dailyResetTime
		local currentTime = os.time()
		local dayStart = os.time({year = os.date("*t", currentTime).year, month = os.date("*t", currentTime).month, day = os.date("*t", currentTime).day})
		
		if lastReset >= dayStart and playerData.completedQuests[questId] then
			print("   canAcceptQuest: Daily quest " .. questId .. " already completed today")
			return false
		end
	end

	print("   canAcceptQuest: ✓ " .. questId .. " can be accepted")
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

	-- Show final progress before removing
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("✅ QUEST COMPLETED!")
	print("   Player: " .. player.Name)
	print("   Quest: " .. quest.name .. " (ID: " .. questId .. ")")
	print("   Description: " .. quest.description)
	print("   Type: " .. quest.questType)
	print("   Level Required: " .. quest.level)
	print("   Repeatable: " .. tostring(quest.repeatable))
	
	-- Show progress breakdown
	print("   Progress:")
	for i, targetProgress in ipairs(questInfo.progress) do
		local target = targetProgress.targetData
		local targetDesc = ""
		if quest.questType == "Kill" then
			targetDesc = target.enemyType .. " zombies"
		elseif quest.questType == "Collect" then
			targetDesc = target.itemName
		elseif quest.questType == "Visit" then
			targetDesc = target.location
		end
		print("     Target " .. i .. ": " .. targetProgress.current .. "/" .. targetProgress.required .. " " .. targetDesc)
	end
	
	-- Show rewards
	print("   Rewards:")
	if quest.rewards.xp then
		print("     +" .. quest.rewards.xp .. " XP")
	end
	if quest.rewards.coins then
		print("     +" .. quest.rewards.coins .. " coins")
	end
	if quest.rewards.statPoints then
		print("     +" .. quest.rewards.statPoints .. " stat point(s)")
	end
	
	-- Show completion status
	local totalCompleted = 0
	for _ in pairs(playerData.completedQuests) do
		totalCompleted = totalCompleted + 1
	end
	print("   Total Completed Quests: " .. totalCompleted)
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	-- Remove from active quests
	playerData.activeQuests[questId] = nil

	-- Notify client
	questCompleteRemote:FireClient(player, questId, quest)

	-- If repeatable, give it again after a delay
	if quest.repeatable then
		task.wait(2)
		if canAcceptQuest(player, questId) then
			giveAvailableQuests(player)
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

-- Global function for other scripts to update quests
function _G.UpdateQuest(player, questType, data)
	if not player or not player.Parent then return end
	updateQuestProgress(player, questType, data)
end

-- Global function to check if player can accept a quest (exposed for NPCs)
function _G.CanAcceptQuest(player, questId)
	return canAcceptQuest(player, questId)
end

-- Global function to get player's active quests (for debugging)
function _G.GetPlayerQuests(player)
	if not player or not player.Parent then return nil end
	local playerData = playerQuests[player.UserId]
	return playerData and playerData.activeQuests or nil
end

-- Global function to clear player's active quests (for testing/debugging)
function _G.ClearPlayerQuests(player)
	if not player or not player.Parent then return false end
	local playerData = playerQuests[player.UserId]
	if playerData then
		playerData.activeQuests = {}
		print("🧹 Cleared all active quests for " .. player.Name)
		return true
	end
	return false
end

-- Global function to check and display all completed quests for a player
function _G.CheckCompletedQuests(player)
	if not player or not player.Parent then 
		print("❌ Invalid player")
		return false 
	end
	
	local playerData = playerQuests[player.UserId]
	if not playerData then
		print("❌ No quest data found for " .. player.Name)
		return false
	end
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("📊 COMPLETED QUESTS CHECK for " .. player.Name)
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	
	local completedCount = 0
	local completedList = {}
	
	for questId, _ in pairs(playerData.completedQuests) do
		local quest = QuestData[questId]
		if quest then
			completedCount = completedCount + 1
			table.insert(completedList, {
				id = questId,
				name = quest.name,
				level = quest.level
			})
		end
	end
	
	if completedCount == 0 then
		print("   No completed quests yet.")
	else
		print("   Total Completed: " .. completedCount)
		print("   Completed Quests:")
		-- Sort by level for better display
		table.sort(completedList, function(a, b) return a.level < b.level end)
		for i, questInfo in ipairs(completedList) do
			print("     " .. i .. ". " .. questInfo.name .. " (Level " .. questInfo.level .. ", ID: " .. questInfo.id .. ")")
		end
	end
	
	-- Also show active quests
	local activeCount = 0
	for questId, questInfo in pairs(playerData.activeQuests) do
		activeCount = activeCount + 1
	end
	
	print("   Active Quests: " .. activeCount)
	if activeCount > 0 then
		print("   Active Quest List:")
		for questId, questInfo in pairs(playerData.activeQuests) do
			local quest = QuestData[questId]
			if quest then
				local progressStr = ""
				for j, prog in ipairs(questInfo.progress) do
					if j > 1 then progressStr = progressStr .. ", " end
					progressStr = progressStr .. prog.current .. "/" .. prog.required
				end
				print("     - " .. quest.name .. " [" .. progressStr .. "]")
			end
		end
	end
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	return true
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
	
	-- Debug: Verify quest was stored
	local storedQuest = playerData.activeQuests[questId]
	if storedQuest then
		print("✅ Quest '" .. quest.name .. "' assigned to " .. player.Name .. " (ID: " .. questId .. ")")
		print("   Progress targets: " .. #storedQuest.progress)
		for i, prog in ipairs(storedQuest.progress) do
			print("   Target " .. i .. ": " .. prog.current .. "/" .. prog.required)
		end
	else
		warn("❌ Quest was not stored properly for " .. player.Name)
	end
	
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
