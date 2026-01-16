local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

-- Get folders
local oreStagesFolder = ReplicatedStorage:WaitForChild("OreStages")
local oresFolder = ReplicatedStorage:WaitForChild("Ores")
local oresWorkspaceFolder = Workspace:WaitForChild("Ores")
-- Ensure OreDrops folder exists (bulletproof)
local oreDropsFolder = Workspace:FindFirstChild("OreDrops")
if not oreDropsFolder then
	oreDropsFolder = Instance.new("Folder")
	oreDropsFolder.Name = "OreDrops"
	oreDropsFolder.Parent = Workspace
	print("[DROP] Created OreDrops folder")
end
print("[DROP] Using OreDrops folder:", oreDropsFolder:GetFullName())

-- Get or create RemoteEvent
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local mineOreRemote = remotesFolder:FindFirstChild("MineOre")
if not mineOreRemote then
	mineOreRemote = Instance.new("RemoteEvent")
	mineOreRemote.Name = "MineOre"
	mineOreRemote.Parent = remotesFolder
	warn("Created MineOre RemoteEvent (was missing)")
end

-- Mining settings
local MINE_DAMAGE = 25 -- Damage per hit
local MAX_MINE_DISTANCE = 14 -- Studs
local MINE_COOLDOWN = 0.25 -- Seconds
local RESPAWN_TIME = 8 -- Seconds
local DROP_DESPAWN_TIME = 12 -- Seconds

-- Cooldown tracking
local playerCooldowns = {}

-- Get stage models (matching exact folder names: Stage0rock, Stage1rock, etc.)
local function getStageModel(stageNumber)
	local stageName = "Stage" .. stageNumber .. "rock"
	return oreStagesFolder:FindFirstChild(stageName)
end

-- Initialize ore attributes
local function initializeOreAttributes(ore)
	if not ore:GetAttribute("MaxHP") then
		ore:SetAttribute("MaxHP", 100)
	end
	if not ore:GetAttribute("HP") then
		ore:SetAttribute("HP", ore:GetAttribute("MaxHP"))
	end
	if not ore:GetAttribute("OreType") then
		ore:SetAttribute("OreType", "Stone")
	end
	if not ore:GetAttribute("DropPerHitChance") then
		ore:SetAttribute("DropPerHitChance", 0.25)
	end
	if not ore:GetAttribute("DropsOnBreak") then
		ore:SetAttribute("DropsOnBreak", 3)
	end
	if not ore:GetAttribute("RespawnTime") then
		ore:SetAttribute("RespawnTime", 8)
	end
	if not ore:GetAttribute("Broken") then
		ore:SetAttribute("Broken", false)
	end
end

-- Update ore stage visual
local function updateOreStage(ore)
	local hp = ore:GetAttribute("HP")
	local maxHP = ore:GetAttribute("MaxHP")
	
	-- Calculate stage (0-3) based on HP percentage
	local hpPercent = hp / maxHP
	local stage = 0
	if hpPercent > 0.75 then
		stage = 0
	elseif hpPercent > 0.5 then
		stage = 1
	elseif hpPercent > 0.25 then
		stage = 2
	else
		stage = 3
	end
	
	-- Remove old stage model
	local oldStage = ore:FindFirstChild("StageModel")
	if oldStage then
		oldStage:Destroy()
	end
	
	-- Get and clone new stage model
	local stageModel = getStageModel(stage)
	if stageModel then
		local newStage = stageModel:Clone()
		newStage.Name = "StageModel"
		
		-- Get ore pivot
		local orePivot = ore:GetPivot()
		
		-- Parent to ore
		newStage.Parent = ore
		
		-- Set pivot to match ore (so it doesn't jump)
		newStage:PivotTo(orePivot)
		
		-- Make all parts non-collidable and transparent (visual only)
		for _, part in pairs(newStage:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Anchored = true
			end
		end
	end
end

-- Spawn rock shard VFX at hit position
local function spawnShardVFX(hitPosition)
	-- Create a small rock shard part
	local shard = Instance.new("Part")
	shard.Size = Vector3.new(0.2, 0.2, 0.2)
	shard.Material = Enum.Material.Rock
	shard.BrickColor = BrickColor.new("Dark stone grey")
	shard.CFrame = CFrame.new(hitPosition) * CFrame.new(
		math.random(-0.5, 0.5),
		math.random(-0.5, 0.5),
		math.random(-0.5, 0.5)
	)
	shard.Anchored = false
	shard.CanCollide = true
	shard.Parent = Workspace
	
	-- Add impulse
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1000, 1000, 1000)
	bodyVelocity.Velocity = Vector3.new(
		math.random(-5, 5),
		math.random(2, 5),
		math.random(-5, 5)
	)
	bodyVelocity.Parent = shard
	
	-- Remove after short time
	Debris:AddItem(bodyVelocity, 0.1)
	Debris:AddItem(shard, 1)
end

-- Helper: Generate random offset within a sphere
local function randomInsideOffset(radius)
	-- random point inside sphere
	local u = math.random()
	local v = math.random()
	local theta = 2 * math.pi * u
	local phi = math.acos(2 * v - 1)
	local r = radius * (math.random() ^ (1/3))
	return Vector3.new(
		r * math.sin(phi) * math.cos(theta),
		r * math.cos(phi),
		r * math.sin(phi) * math.sin(theta)
	)
end

-- Spawn embedded chunk inside the ore (stuck in rock, released on break)
local function spawnEmbeddedChunk(oreNode)
	local oreType = oreNode:GetAttribute("OreType") or "Stone"
	local template = oresFolder:FindFirstChild(oreType)
	
	if not template then 
		warn("[EMBEDDED] Template not found for oreType: " .. tostring(oreType))
		return nil
	end
	
	-- Ensure EmbeddedDrops folder exists
	local embeddedFolder = oreNode:FindFirstChild("EmbeddedDrops")
	if not embeddedFolder then
		embeddedFolder = Instance.new("Folder")
		embeddedFolder.Name = "EmbeddedDrops"
		embeddedFolder.Parent = oreNode
	end
	
	local chunk = template:Clone()
	chunk.Name = "EmbeddedChunk_" .. oreType
	chunk.Parent = embeddedFolder
	
	-- Get ore pivot and position chunk inside
	local orePivot = oreNode:GetPivot()
	local center = orePivot.Position
	local spawnPos = center + randomInsideOffset(math.random(100, 150) / 100) -- 1.0-1.5 studs
	
	-- Position the chunk
	if chunk:IsA("Model") then
		if not chunk.PrimaryPart then
			local pp = chunk:FindFirstChildWhichIsA("BasePart", true)
			if pp then 
				chunk.PrimaryPart = pp 
			end
		end
		if chunk.PrimaryPart then
			chunk:PivotTo(CFrame.new(spawnPos))
		end
	elseif chunk:IsA("BasePart") then
		chunk.Position = spawnPos
	end
	
	-- Make it embedded (anchored, no collision, massless)
	for _, part in ipairs(chunk:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.Massless = true
		end
	end
	
	-- Store ore type as attribute for later pickup
	chunk:SetAttribute("OreType", oreType)
	
	return chunk
end

-- Helper A: Get any BasePart from instance
local function getAnyBasePart(inst)
	if inst:IsA("Model") then
		-- Try PrimaryPart first
		if inst.PrimaryPart then
			return inst.PrimaryPart
		end
		-- Fallback to first BasePart descendant
		return inst:FindFirstChildOfClass("BasePart") or inst:FindFirstChildWhichIsA("BasePart", true)
	elseif inst:IsA("BasePart") then
		return inst
	end
	return nil
end

-- Helper B: Place drop on ground near position
local function placeOnGroundNear(position, dropInstance, oreNode)
	local rayOrigin = position + Vector3.new(0, 10, 0)
	local rayEnd = position - Vector3.new(0, 200, 0)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local excludeList = {}
	if dropInstance then
		table.insert(excludeList, dropInstance)
	end
	if oreNode then
		table.insert(excludeList, oreNode)
	end
	raycastParams.FilterDescendantsInstances = excludeList
	
	local rayResult = Workspace:Raycast(rayOrigin, rayEnd - rayOrigin, raycastParams)
	if rayResult then
		return rayResult.Position + Vector3.new(0, 0.5, 0)
	else
		return position
	end
end

-- Helper C: Apply safe impulse to part
local function applySafeImpulse(part)
	if not part or not part:IsA("BasePart") then return end
	
	-- Random horizontal direction
	local horizontalDir = Vector3.new(
		math.random(-1, 1),
		0,
		math.random(-1, 1)
	).Unit
	
	-- Horizontal magnitude: 4-8
	local horizontalMag = math.random(4, 8)
	
	-- Upward: 6-12
	local upward = math.random(6, 12)
	
	-- Combine
	local impulseDir = (horizontalDir * horizontalMag + Vector3.new(0, upward, 0))
	
	-- Apply impulse
	local assemblyMass = part.AssemblyMass
	if assemblyMass <= 0 then
		assemblyMass = 1
	end
	
	part:ApplyImpulse(impulseDir * assemblyMass)
end

-- Helper D: Add kill zone watcher
local function addKillZoneWatcher(drop, part)
	if not drop or not part then return end
	
	task.spawn(function()
		while drop.Parent and part.Parent do
			if part.Position.Y < -50 then
				-- Drop fell off map, destroy it
				warn("[KILLZONE] Destroying drop that fell below Y=-50:", drop.Name)
				drop:Destroy()
				break
			end
			task.wait(0.25)
		end
	end)
end

-- Helper: Ensure leaderstats folder and ore IntValues exist
local function ensureLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	
	-- Create IntValues for ore types if missing
	local oreTypes = {"Stone", "Iron", "Gold", "Copper", "Diamond"}
	for _, oreType in ipairs(oreTypes) do
		if not leaderstats:FindFirstChild(oreType) then
			local stat = Instance.new("IntValue")
			stat.Name = oreType
			stat.Value = 0
			stat.Parent = leaderstats
		end
	end
	
	return leaderstats
end

-- Track collected drops to prevent duplicates
local collectedDrops = {}

-- Helper E: Make rolling pickup (physics enabled)
local function makeRollingPickup(drop, oreType, amount)
	amount = amount or 1
	
	-- Find a BasePart to attach the prompt to
	local targetPart = getAnyBasePart(drop)
	if not targetPart then
		warn("[PICKUP] No BasePart found in drop:", drop.Name, "Type:", drop.ClassName)
		return
	end
	
	-- Enable physics for all parts
	for _, part in ipairs(drop:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = true
			part.CanTouch = true
			part.CanQuery = true
		end
	end
	
	-- Create ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = oreType
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = targetPart
	
	-- Handle pickup
	prompt.Triggered:Connect(function(player)
		-- Prevent duplicate collections
		if collectedDrops[drop] then 
			return 
		end
		collectedDrops[drop] = true
		
		-- Ensure leaderstats exists
		local leaderstats = ensureLeaderstats(player)
		
		-- Get or create ore stat
		local oreStat = leaderstats:FindFirstChild(oreType)
		if not oreStat then
			oreStat = Instance.new("IntValue")
			oreStat.Name = oreType
			oreStat.Value = 0
			oreStat.Parent = leaderstats
		end
		
		-- Increment inventory
		oreStat.Value = oreStat.Value + amount
		print("✅ " .. player.Name .. " picked up " .. amount .. "x " .. oreType .. " (Total: " .. oreStat.Value .. ")")
		
		-- Destroy the drop
		if drop.Parent then
			drop:Destroy()
		end
		
		-- Clean up tracking
		task.delay(1, function()
			collectedDrops[drop] = nil
		end)
	end)
	
	-- Auto-cleanup after 20 seconds
	Debris:AddItem(drop, 20)
end

-- Release all embedded chunks when ore breaks
local function releaseEmbeddedChunks(oreNode, playerWhoBroke)
	local embeddedFolder = oreNode:FindFirstChild("EmbeddedDrops")
	if not embeddedFolder then
		return
	end
	
	local orePivot = oreNode:GetPivot()
	local center = orePivot.Position
	
	-- Move each chunk to OreDrops and make it collectible
	for _, chunk in pairs(embeddedFolder:GetChildren()) do
		if chunk:IsA("Model") or chunk:IsA("BasePart") then
			local oreType = chunk:GetAttribute("OreType") or oreNode:GetAttribute("OreType") or "Stone"
			
			-- Move to OreDrops folder
			chunk.Parent = oreDropsFolder
			
			-- Find primary part
			local basePart = getAnyBasePart(chunk)
			if not basePart then
				warn("[RELEASE] No BasePart found in chunk:", chunk.Name)
			else
				-- Compute spawn position near ore pivot with small random offset
				local scatterX = math.random(-1.5, 1.5)
				local scatterZ = math.random(-1.5, 1.5)
				local spawnPos = center + Vector3.new(scatterX, 0, scatterZ)
				
				-- Adjust spawn position to be on ground
				spawnPos = placeOnGroundNear(spawnPos, chunk, oreNode)
				
				-- Position the drop
				if chunk:IsA("Model") and chunk.PrimaryPart then
					chunk:PivotTo(CFrame.new(spawnPos))
				elseif chunk:IsA("BasePart") then
					chunk.Position = spawnPos
				end
				
				-- Make it a rolling pickup
				makeRollingPickup(chunk, oreType, 1)
				
				-- Apply safe impulse
				applySafeImpulse(basePart)
				
				-- Add kill zone watcher
				addKillZoneWatcher(chunk, basePart)
			end
		end
	end
	
	-- Clean up folder
	embeddedFolder:Destroy()
end

-- Spawn physical ore drop (physics-based with safety measures)
local function spawnOreDrop(oreType, spawnPosition, oreNode)
	local dropTemplate = oresFolder:FindFirstChild(oreType)
	if not dropTemplate then
		warn("Drop template not found for ore type: " .. tostring(oreType))
		return nil
	end
	
	-- Clone the drop template
	local drop = dropTemplate:Clone()
	
	-- Compute spawn position with small random offset
	local offset = Vector3.new(
		math.random(-1.5, 1.5),
		0,
		math.random(-1.5, 1.5)
	)
	local initialSpawnPos = spawnPosition + offset
	
	-- Adjust to be on ground
	initialSpawnPos = placeOnGroundNear(initialSpawnPos, drop, oreNode)
	
	-- Position the drop
	if drop:IsA("Model") then
		local primaryPart = drop.PrimaryPart or drop:FindFirstChildOfClass("BasePart")
		if primaryPart then
			drop:SetPrimaryPartCFrame(CFrame.new(initialSpawnPos))
		end
	elseif drop:IsA("BasePart") then
		drop.Position = initialSpawnPos
	end
	
	-- Parent to OreDrops folder
	drop.Parent = oreDropsFolder
	
	-- Find base part
	local basePart = getAnyBasePart(drop)
	if not basePart then
		warn("[SPAWN] No BasePart found in drop:", drop.Name)
		drop:Destroy()
		return nil
	end
	
	-- Make it a rolling pickup
	makeRollingPickup(drop, oreType, 1)
	
	-- Apply safe impulse
	applySafeImpulse(basePart)
	
	-- Add kill zone watcher
	addKillZoneWatcher(drop, basePart)
	
	return drop
end

-- Find a random spawn location near SpawnLocation
local function findRandomSpawnPosition()
	-- Find SpawnLocation
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
	if not spawnLocation or not spawnLocation:IsA("SpawnLocation") then
		-- Fallback: find first SpawnLocation
		for _, obj in pairs(Workspace:GetChildren()) do
			if obj:IsA("SpawnLocation") then
				spawnLocation = obj
				break
			end
		end
	end
	
	if not spawnLocation then
		-- No spawn location found, use origin
		return Vector3.new(0, 10, 0)
	end
	
	local spawnPos = spawnLocation.Position
	
	-- Calculate random position (15-25 studs from spawn, random X/Z offset, Y + 2 above ground)
	local offsetX = math.random(-25, 25)
	local offsetZ = math.random(-25, 25)
	
	-- Ensure it's at least 15 studs away
	local distance = math.sqrt(offsetX * offsetX + offsetZ * offsetZ)
	if distance < 15 then
		-- Normalize and scale to 15-25 range
		if distance > 0 then
			offsetX = (offsetX / distance) * math.random(15, 25)
			offsetZ = (offsetZ / distance) * math.random(15, 25)
		else
			offsetX = math.random(15, 25)
			offsetZ = 0
		end
	end
	
	local newPosition = spawnPos + Vector3.new(offsetX, 2, offsetZ)
	
	-- Raycast down to find ground
	local rayOrigin = newPosition + Vector3.new(0, 10, 0)
	local rayDirection = Vector3.new(0, -50, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {}
	
	local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if rayResult then
		return rayResult.Position + Vector3.new(0, 0.5, 0)
	else
		return newPosition
	end
end

-- Respawn ore at a new random location
local function respawnOre(ore)
	-- Clean up any leftover embedded chunks
	local embeddedFolder = ore:FindFirstChild("EmbeddedDrops")
	if embeddedFolder then
		embeddedFolder:Destroy()
	end
	
	-- Find new random position
	local newPosition = findRandomSpawnPosition()
	
	-- Move ore to new location
	if ore:IsA("Model") and ore.PrimaryPart then
		ore:PivotTo(CFrame.new(newPosition))
	else
		local rootPart = ore:FindFirstChild("Root") or ore:FindFirstChildOfClass("BasePart")
		if rootPart then
			rootPart.Position = newPosition
		end
	end
	
	-- Reset attributes
	local maxHP = ore:GetAttribute("MaxHP")
	ore:SetAttribute("HP", maxHP)
	ore:SetAttribute("Broken", false)
	
	-- Update to stage 0
	updateOreStage(ore)
	
	print("✅ Ore respawned at new location: " .. ore.Name .. " at " .. tostring(newPosition))
end

-- Handle mining
mineOreRemote.OnServerEvent:Connect(function(player, oreInstance, hitPosition)
	-- Debug: Log that we received the event
	print("🔨 Server received mine request from " .. player.Name .. " for: " .. tostring(oreInstance and oreInstance.Name or "nil"))
	
	-- Validate player and character
	local character = player.Character
	if not character then 
		warn("  ❌ No character for " .. player.Name)
		return 
	end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end
	
	-- Check cooldown
	local userId = player.UserId
	local lastMine = playerCooldowns[userId]
	if lastMine and tick() - lastMine < MINE_COOLDOWN then
		return
	end
	playerCooldowns[userId] = tick()
	
	-- Hard block terrain and non-ore targets (never trust client)
	if typeof(oreInstance) ~= "Instance" then return end
	
	-- CRITICAL: Check if ore is in workspace.Ores FIRST (fastest check)
	-- This catches 99% of invalid targets including terrain
	if not oreInstance:IsDescendantOf(oresWorkspaceFolder) then
		-- Additional check: is it terrain?
		local isTerrain = false
		
		-- Check if it's the Terrain service itself
		if oreInstance == Workspace.Terrain then
			isTerrain = true
		elseif oreInstance.ClassName == "Terrain" or oreInstance:IsA("Terrain") then
			isTerrain = true
		else
			-- Check if it's a descendant of Terrain
			local success, isDescendant = pcall(function()
				return oreInstance:IsDescendantOf(Workspace.Terrain)
			end)
			if success and isDescendant then
				isTerrain = true
			elseif oreInstance.Parent == Workspace.Terrain then
				isTerrain = true
			else
				-- Walk up parent tree to check for terrain
				local current = oreInstance
				local depth = 0
				while current and current ~= Workspace and depth < 20 do
					if current == Workspace.Terrain then
						isTerrain = true
						break
					end
					current = current.Parent
					depth = depth + 1
				end
			end
		end
		
		if isTerrain then
			warn(player.Name .. " tried to mine terrain (blocked)")
		else
			warn(player.Name .. " tried to mine something outside of workspace.Ores: " .. tostring(oreInstance.Name) .. " (Parent: " .. tostring(oreInstance.Parent and oreInstance.Parent.Name) .. ")")
		end
		return
	end
	
	-- Double-check: ensure it's actually a Model or BasePart (not terrain)
	if not (oreInstance:IsA("Model") or oreInstance:IsA("BasePart")) then
		warn(player.Name .. " tried to mine invalid instance type: " .. tostring(oreInstance.ClassName))
		return
	end
	
	-- Additional safety: Check if it's a terrain voxel (terrain parts have special properties)
	-- Terrain voxels are usually not in workspace.Ores, but double-check anyway
	if oreInstance:IsA("BasePart") then
		-- Terrain voxels sometimes have no parent or weird parent structure
		if not oreInstance.Parent or oreInstance.Parent == Workspace then
			-- If it's directly in Workspace and not in Ores folder, it's likely terrain
			warn(player.Name .. " tried to mine suspicious part (likely terrain): " .. tostring(oreInstance.Name))
			return
		end
	end
	
	-- Validate ore instance still exists
	if not oreInstance.Parent then return end
	
	-- CRITICAL: If oreInstance is a BasePart (from StageModel), find the parent Model (the actual ore node)
	local oreModel = oreInstance
	if oreInstance:IsA("BasePart") then
		-- Walk up to find the Model that's directly in workspace.Ores
		local current = oreInstance.Parent
		while current and current ~= Workspace do
			if current:IsA("Model") and current:IsDescendantOf(oresWorkspaceFolder) and current.Parent == oresWorkspaceFolder then
				oreModel = current
				break
			end
			current = current.Parent
		end
		-- If we didn't find the model, use the part's parent as fallback
		if oreModel == oreInstance then
			oreModel = oreInstance.Parent
			if not oreModel or not oreModel:IsA("Model") then
				warn(player.Name .. " could not find ore Model from Part: " .. tostring(oreInstance.Name))
				return
			end
		end
	end
	
	-- Validate distance - get a BasePart from the ore model
	-- Try PrimaryPart first, then FindFirstChildOfClass, then use GetPivot()
	local orePart = oreModel.PrimaryPart
	if not orePart then
		orePart = oreModel:FindFirstChildOfClass("BasePart")
	end
	if not orePart then
		-- Try to find "Root" part specifically
		orePart = oreModel:FindFirstChild("Root")
	end
	
	-- Get position for distance calculation
	local orePosition
	if orePart then
		orePosition = orePart.Position
	else
		-- Fallback: use model pivot
		local success, pivot = pcall(function()
			return oreModel:GetPivot()
		end)
		if success then
			orePosition = pivot.Position
		else
			warn(player.Name .. " ore model has no BasePart and cannot get pivot: " .. tostring(oreModel.Name))
			return
		end
	end
	
	local distance = (rootPart.Position - orePosition).Magnitude
	if distance > MAX_MINE_DISTANCE then
		warn(player.Name .. " tried to mine ore too far away (" .. math.floor(distance) .. " studs)")
		return
	end
	
	-- Check if ore is broken
	if oreModel:GetAttribute("Broken") == true then
		return
	end
	
	-- Initialize attributes if needed
	initializeOreAttributes(oreModel)
	
	-- Get current HP
	local currentHP = oreModel:GetAttribute("HP")
	local newHP = math.max(0, currentHP - MINE_DAMAGE)
	
	-- Update HP
	oreModel:SetAttribute("HP", newHP)
	
	-- Spawn shard VFX at hit position
	if hitPosition then
		spawnShardVFX(hitPosition)
	else
		spawnShardVFX(orePosition)
	end
	
	-- Spawn embedded chunk inside the rock (random chance)
	local dropChance = oreModel:GetAttribute("DropPerHitChance") or 0.25
	if math.random() < dropChance then
		spawnEmbeddedChunk(oreModel)
	end
	
	-- Update stage visual
	updateOreStage(oreModel)
	
	-- Check if ore is broken
	if newHP <= 0 then
		oreModel:SetAttribute("Broken", true)
		
		-- Release all embedded chunks (they become collectible pickups)
		releaseEmbeddedChunks(oreModel, player)
		
		-- Spawn additional break drops (if DropsOnBreak attribute is set)
		local dropsOnBreak = oreModel:GetAttribute("DropsOnBreak") or 0
		local oreType = oreModel:GetAttribute("OreType")
		
		if dropsOnBreak > 0 then
			for i = 1, dropsOnBreak do
				spawnOreDrop(oreType, orePosition, oreModel)
			end
		end
		
		-- Give XP if function exists
		if _G.GiveXP then
			-- Get XP from OreData if available
			local OreData = require(ReplicatedStorage.Modules.OreData)
			local oreData = OreData[oreType]
			if oreData and oreData.experience then
				_G.GiveXP(player, oreData.experience, "Mining: " .. oreType)
			end
		end
		
		-- Update quest if function exists
		if _G.UpdateQuest then
			_G.UpdateQuest(player, "Mine", {
				oreType = oreType,
				amount = 1
			})
		end
		
		-- Respawn after delay (use ore's RespawnTime attribute)
		local respawnTime = oreModel:GetAttribute("RespawnTime") or RESPAWN_TIME
		task.wait(respawnTime)
		respawnOre(oreModel)
		
		print("⛏️ " .. player.Name .. " broke " .. oreType .. " ore")
	else
		print("⛏️ " .. player.Name .. " mined " .. oreModel:GetAttribute("OreType") .. " ore (" .. math.floor(newHP) .. "/" .. oreModel:GetAttribute("MaxHP") .. " HP)")
	end
end)

-- Setup player inventory on join (uses ensureLeaderstats helper)
Players.PlayerAdded:Connect(function(player)
	ensureLeaderstats(player)
end)

-- Initialize existing players
for _, player in pairs(Players:GetPlayers()) do
	ensureLeaderstats(player)
end

-- Initialize existing ores
task.spawn(function()
	task.wait(1) -- Wait for workspace to load
	
	for _, ore in pairs(oresWorkspaceFolder:GetChildren()) do
		if ore:IsA("Model") or ore:IsA("BasePart") then
			initializeOreAttributes(ore)
			updateOreStage(ore)
		end
	end
	
	-- Watch for new ores
	oresWorkspaceFolder.ChildAdded:Connect(function(ore)
		if ore:IsA("Model") or ore:IsA("BasePart") then
			task.wait(0.1) -- Wait for ore to fully load
			initializeOreAttributes(ore)
			updateOreStage(ore)
		end
	end)
end)

print("✅ OreSystem server ready")
