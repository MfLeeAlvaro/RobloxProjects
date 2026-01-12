local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load modules
local DialogModule = require(ReplicatedStorage.Modules.DialogModule)
local NPCData = require(ReplicatedStorage.Modules.NPCData)
local QuestData = require(ReplicatedStorage.Modules.QuestData)

-- Get RemoteEvents
local npcTalkRemote = ReplicatedStorage:WaitForChild("NPCTalkRemote")
local npcQuestsRemote = ReplicatedStorage:WaitForChild("NPCQuestsRemote")
local acceptQuestRemote = ReplicatedStorage:WaitForChild("AcceptQuestRemote")

-- Store active NPC dialogs
local activeDialogs = {}

-- Store quest data per NPC
local pendingQuestRequests = {}

-- Function to show quest selection dialog
local function showQuestDialog(dialog, npcId, npcInfo)
	print("📤 Requesting quests for NPC:", npcId)
	
	-- Store the dialog for when server responds
	pendingQuestRequests[npcId] = dialog
	
	-- Request quests from server
	local success = pcall(function()
		npcQuestsRemote:FireServer(npcId)
	end)
	
	if not success then
		warn("❌ Failed to send quest request to server")
		pendingQuestRequests[npcId] = nil
		dialog:hideGui("Error connecting to server. Please try again.")
	end
end

-- Function to setup NPC dialog
local function setupNPCDialog(npcModel, npcId)
	if not npcModel or not npcModel:IsA("Model") then return end
	
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	local head = npcModel:FindFirstChild("Head")
	local prompt = npcModel:FindFirstChild("ProximityPrompt")
	
	if not humanoid or not head or not prompt then
		warn("NPC missing required parts: " .. npcModel.Name)
		return
	end
	
	-- Get NPC data
	local npcInfo = NPCData[npcId]
	if not npcInfo then
		warn("NPC data not found for: " .. npcId)
		return
	end
	
	-- Check if head has gui (required for DialogModule)
	local headGui = head:FindFirstChild("gui")
	if not headGui then
		warn("NPC Head missing 'gui' - DialogModule requires this!")
		return
	end
	
	-- Create dialog instance
	local dialog = DialogModule.new(npcInfo.name, npcModel, prompt)
	
	-- Add greeting dialog with quest options
	local greetingResponses = {"View Quests", "Goodbye"}
	dialog:addDialog(npcInfo.greeting, greetingResponses)
	
	-- Handle dialog responses
	dialog.responded:Connect(function(responseIndex, dialogNum)
		print("💬 Dialog response - Index:", responseIndex, "Dialog #:", dialogNum)
		
		-- Get the dialog that was responded to
		if not dialog.dialogs or not dialog.dialogs[dialogNum] then
			warn("⚠️ No dialog data for dialogNum:", dialogNum)
			return
		end
		
		local dialogData = dialog.dialogs[dialogNum]
		local response = dialogData.responses[responseIndex]
		
		if not response then
			warn("⚠️ No response for index:", responseIndex)
			return
		end
		
		print("✅ Selected response:", response)
		
		if dialogNum == 1 then -- Greeting dialog
			if response == "View Quests" then
				print("🔍 View Quests selected, requesting from server...")
				-- Don't hide the dialog yet - wait for server response
				-- Request quests from server (will show quest dialog when response arrives)
				showQuestDialog(dialog, npcId, npcInfo)
				-- Keep dialog visible while waiting for server
			elseif response == "Goodbye" then
				dialog:hideGui("Farewell, traveler!")
			end
		elseif dialogNum == 2 then -- Quest selection dialog
			print("📋 Quest dialog response:", response)
			if response and string.find(response, "Accept:") then
				-- Extract quest name and find quest ID
				local questName = string.gsub(response, "Accept: ", "")
				print("🎯 Accepting quest:", questName)
				
				-- Find quest ID by name
				local foundQuestId = nil
				for questId, quest in pairs(QuestData) do
					if quest.name == questName then
						foundQuestId = questId
						break
					end
				end
				
				if foundQuestId then
					acceptQuestRemote:FireServer(npcId, foundQuestId)
					dialog:hideGui("Quest accepted! Good luck!")
				else
					warn("❌ Quest not found:", questName)
					dialog:hideGui("Quest not found. Please try again.")
				end
			elseif response == "Back" then
				print("⬅️ Going back to greeting")
				dialog:triggerDialog(player, 1) -- Go back to greeting
			elseif response == "Okay" then
				dialog:hideGui("Come back anytime!")
			end
		end
	end)
	
	-- Handle prompt trigger
	prompt.Triggered:Connect(function()
		dialog:triggerDialog(player)
	end)
	
	activeDialogs[npcModel] = dialog
	
	print("✅ NPC Dialog setup: " .. npcInfo.name)
end

-- Listen for quest data from server
npcQuestsRemote.OnClientEvent:Connect(function(npcId, availableQuests)
	print("✅ Received quest data for NPC:", npcId, "Quests:", #availableQuests)
	
	local dialog = pendingQuestRequests[npcId]
	if not dialog then 
		warn("⚠️ No pending dialog for NPC:", npcId)
		return 
	end
	
	local npcInfo = NPCData[npcId]
	if not npcInfo then 
		warn("⚠️ NPC info not found for:", npcId)
		return 
	end
	
	-- Clear pending request
	pendingQuestRequests[npcId] = nil
	
	-- Build quest list or no quests message
	local questList
	local questOptions = {}
	
	if #availableQuests == 0 then
		questList = npcInfo.dialogues.noQuests
		table.insert(questOptions, "Okay")
	else
		questList = "Available Quests:\n\n"
		for i, quest in ipairs(availableQuests) do
			questList = questList .. i .. ". " .. quest.name .. " (Level " .. quest.level .. ")\n"
			questList = questList .. "   " .. quest.description .. "\n"
			questList = questList .. "   Rewards: " .. quest.rewards.xp .. " XP"
			if quest.rewards.coins then
				questList = questList .. ", " .. quest.rewards.coins .. " coins"
			end
			questList = questList .. "\n\n"
			
			table.insert(questOptions, "Accept: " .. quest.name)
		end
		table.insert(questOptions, "Back")
	end
	
	-- Add quest dialog
	dialog:addDialog(questList, questOptions)
	
	print("📋 Added quest dialog, total dialogs:", #dialog.dialogs)
	
	-- Use a coroutine to ensure proper timing
	task.spawn(function()
		-- Wait a bit for dialog to be fully registered
		task.wait(0.5)
		
		-- Verify dialog was added
		if not dialog.dialogs or not dialog.dialogs[2] then
			warn("❌ Quest dialog was not added properly!")
			dialog:hideGui("Error loading quests. Please try again.")
			return
		end
		
		-- Show the quest dialog (dialog #2)
		print("📋 Triggering quest dialog #2")
		dialog:triggerDialog(player, 2)
		end)
end)

-- Function to try setting up an NPC dialog
local function trySetupNPCDialog(npcModel)
	if not npcModel or not npcModel:IsA("Model") then return end
	
	local npcId = npcModel:GetAttribute("NPCId") or npcModel:GetAttribute("NPCID")
	if npcId then
		npcId = tostring(npcId)
	else
		-- Try to match by name
		for id, data in pairs(NPCData) do
			if data.name == npcModel.Name or npcModel.Name == id then
				npcId = id
				break
			end
		end
	end
	
	if npcId and NPCData[npcId] then
		setupNPCDialog(npcModel, npcId)
		return true
	end
	
	return false
end

-- Find and setup NPCs
local function setupNPCs()
	-- Check NPCs folder (recommended location)
	local npcsFolder = workspace:FindFirstChild("NPCs")
	if npcsFolder then
		for _, npcModel in pairs(npcsFolder:GetChildren()) do
			if npcModel:IsA("Model") then
				task.wait(0.5) -- Wait for model to load
				trySetupNPCDialog(npcModel)
			end
		end
	end
	
	-- Check CollectionService tagged NPCs
	for _, npcModel in pairs(CollectionService:GetTagged("NPC")) do
		trySetupNPCDialog(npcModel)
	end
	
	-- Check directly in workspace (if NPCId attribute is set)
	local skipFolders = {"NPCs", "Zones", "Enemies", "Terrain"}
	for _, child in pairs(workspace:GetChildren()) do
		if child:IsA("Model") and not table.find(skipFolders, child.Name) then
			if child:GetAttribute("NPCId") or child:GetAttribute("NPCID") then
				trySetupNPCDialog(child)
			end
		end
	end
end

-- Setup NPCs when they're added
workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") then
		task.wait(1) -- Wait for model to load
		trySetupNPCDialog(child)
	end
end)

-- Also watch NPCs folder if it exists
workspace.ChildAdded:Connect(function(child)
	if child.Name == "NPCs" and child:IsA("Folder") then
		child.ChildAdded:Connect(function(npcModel)
			if npcModel:IsA("Model") then
				task.wait(1) -- Wait for model to load
				trySetupNPCDialog(npcModel)
			end
		end)
	end
end)

-- Initial setup
task.wait(2) -- Wait for workspace to load
setupNPCs()

print("✅ NPC Interaction client ready")
