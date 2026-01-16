local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Load NPC and Quest data
local NPCData = require(ReplicatedStorage.Modules.NPCData)
local QuestData = require(ReplicatedStorage.Modules.QuestData)

-- Create RemoteEvents
local npcTalkRemote = ReplicatedStorage:FindFirstChild("NPCTalkRemote")
if not npcTalkRemote then
	npcTalkRemote = Instance.new("RemoteEvent")
	npcTalkRemote.Name = "NPCTalkRemote"
	npcTalkRemote.Parent = ReplicatedStorage
end

local npcQuestsRemote = ReplicatedStorage:FindFirstChild("NPCQuestsRemote")
if not npcQuestsRemote then
	npcQuestsRemote = Instance.new("RemoteEvent")
	npcQuestsRemote.Name = "NPCQuestsRemote"
	npcQuestsRemote.Parent = ReplicatedStorage
end

-- Store NPC data
local npcInstances = {}

-- Function to setup NPC
local function setupNPC(npcModel, npcId)
	if not npcModel or not npcModel:IsA("Model") then return end
	
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Get NPC data
	local npcInfo = NPCData[npcId]
	if not npcInfo then
		warn("NPC data not found for: " .. npcId)
		return
	end

	-- Create or get ProximityPrompt
	local prompt = npcModel:FindFirstChild("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ProximityPrompt"
		prompt.ActionText = "Talk"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.Parent = npcModel
	end

	-- Tag with NPCprompt for DialogModule
	CollectionService:AddTag(prompt, "NPCprompt")

	-- Store NPC info
	npcInstances[npcModel] = {
		id = npcId,
		data = npcInfo,
		prompt = prompt
	}

	-- Handle prompt trigger (client will handle dialog, server just tracks)
	prompt.Triggered:Connect(function(player)
		print("💬 " .. player.Name .. " talked to " .. npcInfo.name)
	end)

	print("✅ NPC setup complete: " .. npcInfo.name .. " (" .. npcId .. ")")
end

-- Function to get available quests for a player
function getAvailableQuests(player, npcId)
	local npcInfo = NPCData[npcId]
	if not npcInfo then 
		warn("NPC data not found for:", npcId)
		return {} 
	end

	local availableQuests = {}
	local playerLevel = player:FindFirstChild("Level")
	local playerLevelValue = playerLevel and playerLevel.Value or 1

	print("🔍 Getting available quests for " .. player.Name .. " from " .. npcInfo.name)
	print("   Player level:", playerLevelValue)
	print("   NPC offers " .. #npcInfo.quests .. " quests")

	-- Check each quest this NPC offers
	for _, questId in ipairs(npcInfo.quests) do
		local quest = QuestData[questId]
		if not quest then 
			warn("   ⚠ Quest '" .. questId .. "' not found in QuestData")
			continue 
		end

		print("   Checking quest:", questId, "-", quest.name, "(Level", quest.level .. ")")

		-- Check if quest can be accepted using QuestManager's function
		if _G.CanAcceptQuest then
			local canAccept = _G.CanAcceptQuest(player, questId)
			if not canAccept then
				print("     ❌ Cannot accept (filtered by CanAcceptQuest)")
				continue -- Skip quests that can't be accepted
			end
			print("     ✅ Can accept")
		else
			-- Fallback: just check level requirement if QuestManager not available
			if playerLevelValue < quest.level then
				print("     ❌ Level too low (need " .. quest.level .. ", have " .. playerLevelValue .. ")")
				continue
			end
			print("     ✅ Level requirement met")
		end

		-- Quest can be accepted, add it to the list
		table.insert(availableQuests, {
			id = questId,
			name = quest.name,
			description = quest.description,
			rewards = quest.rewards,
			level = quest.level
		})
		print("     ✓ Added to available quests list")
	end

	print("   📋 Returning " .. #availableQuests .. " available quests")
	return availableQuests
end

-- Function to accept quest from NPC
local function acceptQuestFromNPC(player, npcId, questId)
	local npcInfo = NPCData[npcId]
	if not npcInfo then return false end
	
	-- Check if NPC offers this quest
	local offersQuest = false
	for _, offeredQuestId in ipairs(npcInfo.quests) do
		if offeredQuestId == questId then
			offersQuest = true
			break
		end
	end
	
	if not offersQuest then
		warn("NPC " .. npcInfo.name .. " does not offer quest " .. questId)
		return false
	end
	
	-- Call QuestManager to assign quest
	if _G.AssignQuest then
		local success = _G.AssignQuest(player, questId)
		if success then
			print("✅ " .. player.Name .. " accepted quest " .. questId .. " from " .. npcInfo.name)
			-- Verify quest was actually stored
			if _G.GetPlayerQuests then
				local activeQuests = _G.GetPlayerQuests(player)
				if activeQuests and activeQuests[questId] then
					print("   ✓ Quest verified in player's active quests")
				else
					warn("   ⚠ Quest not found in player's active quests after assignment!")
				end
			end
			return true
		else
			-- Quest couldn't be assigned (already active, level too low, etc.)
			print("❌ Quest " .. questId .. " could not be assigned to " .. player.Name)
			return false
		end
	else
		warn("❌ _G.AssignQuest is not available!")
		return false
	end
end

-- Handle quest list request from client
npcQuestsRemote.OnServerEvent:Connect(function(player, npcId)
	local availableQuests = getAvailableQuests(player, npcId)
	npcQuestsRemote:FireClient(player, npcId, availableQuests)
end)

-- Handle quest acceptance from client
local acceptQuestRemote = ReplicatedStorage:FindFirstChild("AcceptQuestRemote")
if not acceptQuestRemote then
	acceptQuestRemote = Instance.new("RemoteEvent")
	acceptQuestRemote.Name = "AcceptQuestRemote"
	acceptQuestRemote.Parent = ReplicatedStorage
end

acceptQuestRemote.OnServerEvent:Connect(function(player, npcId, questId)
	local success = acceptQuestFromNPC(player, npcId, questId)
	-- Notify client of result
	acceptQuestRemote:FireClient(player, success, questId)
end)

-- Function to setup a single NPC
local function trySetupNPC(npcModel)
	if not npcModel or not npcModel:IsA("Model") then return end
	
	-- Try to find NPC ID from attributes or name
	local npcId = npcModel:GetAttribute("NPCId") or npcModel:GetAttribute("NPCID")
	
	-- Ensure it's a string
	if npcId then
		npcId = tostring(npcId)
	end
	
	-- If no attribute, try to match by name
	if not npcId then
		for id, data in pairs(NPCData) do
			if data.name == npcModel.Name or npcModel.Name == id then
				npcId = id
				break
			end
		end
	end
	
	if npcId and NPCData[npcId] then
		setupNPC(npcModel, npcId)
		return true
	elseif npcId then
		warn("NPC ID '" .. tostring(npcId) .. "' not found in NPCData for model: " .. npcModel.Name)
	end
	
	return false
end

-- Find and setup existing NPCs in workspace
local function setupExistingNPCs()
	-- Look for NPCs in a specific folder (recommended)
	local npcsFolder = workspace:FindFirstChild("NPCs")
	
	if npcsFolder then
		for _, npcModel in pairs(npcsFolder:GetChildren()) do
			trySetupNPC(npcModel)
		end
	end

	-- Also check for NPCs with CollectionService tags
	for _, npcModel in pairs(CollectionService:GetTagged("NPC")) do
		trySetupNPC(npcModel)
	end
	
	-- Also check directly in workspace (for NPCs placed at root level)
	-- But skip common folders to avoid checking everything
	local skipFolders = {"NPCs", "Zones", "Enemies", "Terrain"}
	for _, child in pairs(workspace:GetChildren()) do
		if child:IsA("Model") and not table.find(skipFolders, child.Name) then
			-- Only check if it has NPCId attribute to avoid checking every model
			if child:GetAttribute("NPCId") or child:GetAttribute("NPCID") then
				trySetupNPC(child)
			end
		end
	end
end

-- Setup NPCs when they're added
workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") then
		task.wait(1) -- Wait for model to fully load
		trySetupNPC(child)
	end
end)

-- Also watch NPCs folder if it exists
workspace.ChildAdded:Connect(function(child)
	if child.Name == "NPCs" and child:IsA("Folder") then
		child.ChildAdded:Connect(function(npcModel)
			if npcModel:IsA("Model") then
				task.wait(1) -- Wait for model to fully load
				trySetupNPC(npcModel)
			end
		end)
	end
end)

-- Initial setup
task.wait(2) -- Wait for workspace to load
setupExistingNPCs()

print("✅ NPC Handler ready")
