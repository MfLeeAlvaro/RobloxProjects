local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Get the correct remote system
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local mineOreRemote = remotesFolder:FindFirstChild("MineOre")
if not mineOreRemote then
	-- Wait a bit for it to be created by server scripts
	task.wait(1)
	mineOreRemote = remotesFolder:FindFirstChild("MineOre")
	if not mineOreRemote then
		warn("MineOre remote not found - mining disabled")
		return
	end
end

-- Get ores folder
local oresFolder = Workspace:WaitForChild("Ores")

local cooldown = 0.5
local lastMine = 0
local canMine = true

mouse.Button1Down:Connect(function()
	if tick() - lastMine < cooldown then 
		-- Optional: Show cooldown message
		if canMine then
			canMine = false
			print("⏳ Mining too fast! Wait a moment...")
			task.delay(cooldown, function()
				canMine = true
			end)
		end
		return 
	end

	local target = mouse.Target
	if not target then return end
	
	-- Find the ore instance by walking up the parent tree
	local oreInstance = target
	while oreInstance and oreInstance ~= Workspace do
		-- Check if it's in the ores folder
		if oreInstance:IsDescendantOf(oresFolder) then
			-- Found a valid ore!
			lastMine = tick()
			local hitPosition = mouse.Hit.Position
			mineOreRemote:FireServer(oreInstance, hitPosition)
			
			-- Visual feedback
			local oreType = oreInstance:GetAttribute("OreType") or "ore"
			print("⛏️ Mining " .. oreType .. "...")
			return
		end
		oreInstance = oreInstance.Parent
	end
	
	-- Not an ore - do nothing (could be terrain, wall, etc.)
end)

print("Mining system ready! Click on ores to mine them!")