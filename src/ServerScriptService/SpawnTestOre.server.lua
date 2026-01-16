local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for folders
local oresWorkspaceFolder = Workspace:WaitForChild("Ores")
local oreStagesFolder = ReplicatedStorage:WaitForChild("OreStages")

-- Find SpawnLocation
local function findSpawnLocation()
	-- Prefer object named "SpawnLocation"
	local namedSpawn = Workspace:FindFirstChild("SpawnLocation")
	if namedSpawn and namedSpawn:IsA("SpawnLocation") then
		return namedSpawn
	end
	
	-- Else find first SpawnLocation
	for _, obj in pairs(Workspace:GetChildren()) do
		if obj:IsA("SpawnLocation") then
			return obj
		end
	end
	
	return nil
end

-- Function to update ore stage (shared with OreSystem)
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
	
	-- Get and clone new stage model (matching exact folder names: Stage0rock, Stage1rock, etc.)
	local stageName = "Stage" .. stage .. "rock"
	local stageModel = oreStagesFolder:FindFirstChild(stageName)
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

-- Spawn the test ore
task.spawn(function()
	task.wait(2) -- Wait for workspace to fully load
	
	local spawnLocation = findSpawnLocation()
	if not spawnLocation then
		warn("No SpawnLocation found - cannot spawn test ore")
		return
	end
	
	-- Calculate spawn position (15-25 studs from spawn, random X/Z offset, Y + 2 above ground)
	local spawnPos = spawnLocation.Position
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
	
	local orePosition = spawnPos + Vector3.new(offsetX, 2, offsetZ)
	
	-- Create the ore node model
	local oreNode = Instance.new("Model")
	oreNode.Name = "TestOreNode"
	
	-- Create invisible anchored root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "Root"
	rootPart.Size = Vector3.new(4, 4, 4)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Anchored = true
	rootPart.Parent = oreNode
	oreNode.PrimaryPart = rootPart
	
	-- Set pivot/position
	oreNode:PivotTo(CFrame.new(orePosition))
	
	-- Set attributes
	oreNode:SetAttribute("OreType", "Stone")
	oreNode:SetAttribute("MaxHP", 100)
	oreNode:SetAttribute("HP", 100)
	oreNode:SetAttribute("DropPerHitChance", 0.35)
	oreNode:SetAttribute("DropsOnBreak", 4)
	oreNode:SetAttribute("RespawnTime", 8)
	oreNode:SetAttribute("Broken", false)
	
	-- Parent to workspace.Ores
	oreNode.Parent = oresWorkspaceFolder
	
	-- Apply Stage0 visual
	task.wait(0.1) -- Small delay to ensure model is fully set up
	updateOreStage(oreNode)
	
	print("✅ Test ore node spawned at " .. tostring(orePosition))
end)
