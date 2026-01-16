local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local tool = script.Parent

-- Get remote
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local mineOreRemote = remotesFolder:WaitForChild("MineOre")

-- Get ores folder
local oresFolder = Workspace:WaitForChild("Ores")

-- Mining settings
local RAYCAST_DISTANCE = 12 -- Studs
local MINE_COOLDOWN = 0.25 -- Seconds

-- State
local canMine = true
local lastMineTime = 0

-- Function to find ore node from hit part
local function findOreNode(hit)
	if not hit then return nil end
	
	-- Walk up the parent tree to find a Model that's in workspace.Ores
	local current = hit
	local depth = 0
	while current and current ~= Workspace and depth < 20 do
		-- Check if it's in ores folder
		if current:IsDescendantOf(oresFolder) then
			-- Found it! Return the Model (or BasePart if it's directly in Ores)
			if current:IsA("Model") or current:IsA("BasePart") then
				return current
			end
		end
		current = current.Parent
		depth = depth + 1
	end
	
	return nil
end

-- Function to perform mining
local function performMining()
	if not canMine then return end
	
	local currentTime = tick()
	if currentTime - lastMineTime < MINE_COOLDOWN then
		return
	end
	
	-- Update cooldown
	lastMineTime = currentTime
	canMine = false
	
	-- Get character
	local character = player.Character
	if not character then
		canMine = true
		return
	end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		canMine = true
		return
	end
	
	-- Get camera for raycast direction
	local camera = Workspace.CurrentCamera
	if not camera then
		canMine = true
		return
	end
	
	-- Calculate raycast direction (forward from camera)
	local cameraCFrame = camera.CFrame
	local lookDirection = cameraCFrame.LookVector
	
	-- Calculate raycast origin (slightly forward from character)
	local rayOrigin = rootPart.Position + Vector3.new(0, 1, 0) + (lookDirection * 2)
	
	-- Create raycast params - ignore character
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.IgnoreWater = true
	
	-- Perform raycast
	local raycastResult = Workspace:Raycast(
		rayOrigin,
		lookDirection * RAYCAST_DISTANCE,
		raycastParams
	)
	
	local hit = raycastResult and raycastResult.Instance
	if not hit then
		canMine = true
		return
	end
	
	-- Find the ore node
	local oreNode = findOreNode(hit)
	
	if not oreNode then
		-- Not an ore node - do nothing (could be terrain, wall, etc.)
		canMine = true
		return
	end
	
	-- Final validation: ensure oreNode is actually in oresFolder
	if not oreNode:IsDescendantOf(oresFolder) then
		canMine = true
		return
	end
	
	-- Get hit position
	local hitPosition = raycastResult.Position
	
	-- Send to server
	mineOreRemote:FireServer(oreNode, hitPosition)
	
	-- Re-enable mining after cooldown
	task.wait(MINE_COOLDOWN)
	canMine = true
end

-- Handle tool activation
tool.Activated:Connect(function()
	performMining()
end)

print("✅ StonePickaxeTest mining script loaded")
