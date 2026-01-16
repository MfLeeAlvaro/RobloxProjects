local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Get the ores folder
local oresWorkspaceFolder = Workspace:WaitForChild("Ores")

-- Get or create the MineOre remote to use the proper mining system
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local mineOreRemote = remotesFolder:FindFirstChild("MineOre")
if not mineOreRemote then
	mineOreRemote = Instance.new("RemoteEvent")
	mineOreRemote.Name = "MineOre"
	mineOreRemote.Parent = remotesFolder
	warn("Created MineOre RemoteEvent (was missing)")
end

-- Function to check if a position/instance is terrain
local function isTerrainPosition(position)
	if not Workspace.Terrain then return false end
	
	-- Use ReadVoxels to check if there's solid terrain at this position
	local region = Region3.new(
		position - Vector3.new(0.5, 0.5, 0.5),
		position + Vector3.new(0.5, 0.5, 0.5)
	)
	
	local success, material, occupancy = pcall(function()
		return Workspace.Terrain:ReadVoxels(region, Enum.Material.Air)
	end)
	
	if success and material and #material > 0 then
		-- Check if there's any solid material (not air)
		for i, mat in ipairs(material) do
			if mat ~= Enum.Material.Air and occupancy and occupancy[i] and occupancy[i] > 0 then
				return true
			end
		end
	end
	
	return false
end

-- Function to find ore at a position
local function findOreAtPosition(position)
	-- Check all ores in the workspace.Ores folder
	for _, ore in pairs(oresWorkspaceFolder:GetChildren()) do
		if ore:IsA("Model") or ore:IsA("BasePart") then
			local orePart = ore:IsA("BasePart") and ore or ore:FindFirstChildOfClass("BasePart")
			if orePart then
				local distance = (orePart.Position - position).Magnitude
				-- If we're within 2 studs of an ore, consider it a hit
				if distance < 2 then
					return ore
				end
			end
		end
	end
	return nil
end

script.Parent.event.OnServerEvent:Connect(function(plr, mousetarget, Radius, HitSoundEnabled)
	-- Validate player and character
	local character = plr.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end
	
	-- Validate mousetarget is a Vector3
	if typeof(mousetarget) ~= "Vector3" then return end
	
	-- Check distance from pickaxe head to target
	local pickaxeHead = script.Parent:FindFirstChild("Head")
	if not pickaxeHead then return end
	
	local distance = (pickaxeHead.Position - mousetarget).Magnitude
	if distance >= 10 then return end
	
	-- CRITICAL: Check if target position is terrain
	if isTerrainPosition(mousetarget) then
		-- Block terrain mining
		warn(plr.Name .. " tried to mine terrain with pickaxe (blocked)")
		return
	end
	
	-- Find the ore at this position
	local oreInstance = findOreAtPosition(mousetarget)
	
	if not oreInstance then
		-- No ore found at this position - don't create explosion
		return
	end
	
	-- Validate the ore is actually in workspace.Ores
	if not oreInstance:IsDescendantOf(oresWorkspaceFolder) then
		warn(plr.Name .. " tried to mine something outside of workspace.Ores")
		return
	end
	
	-- Play hit sound if enabled
	if HitSoundEnabled == true then
		local hitsound = script.Parent.Head:FindFirstChild("hitsound")
		if hitsound then
			hitsound.TimePosition = 0
			hitsound.Playing = true
		end
	end
	
	-- Instead of creating an explosion that modifies terrain, use the proper mining system
	-- This will handle HP, drops, visuals, etc. properly
	mineOreRemote:FireServer(oreInstance, mousetarget)
	
	-- Optional: Create a visual explosion effect (without terrain modification)
	-- Only if you want visual feedback without the crater effect
	--[[
	local Explosion = Instance.new("Explosion")
	Explosion.Parent = Workspace
	Explosion.BlastPressure = 0  -- No pressure damage
	Explosion.BlastRadius = Radius
	Explosion.DestroyJointRadiusPercent = 0
	Explosion.ExplosionType = Enum.ExplosionType.NoCraters  -- Changed from Craters!
	Explosion.Visible = false
	Explosion.Position = mousetarget
	--]]
end)
