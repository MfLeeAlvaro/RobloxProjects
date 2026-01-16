local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load modules
local OreData = require(ReplicatedStorage.Modules.OreData)

-- Get or create remote for mining
local miningRemote = ReplicatedStorage:FindFirstChild("MiningRemote")
if not miningRemote then
	miningRemote = Instance.new("RemoteEvent")
	miningRemote.Name = "MiningRemote"
	miningRemote.Parent = ReplicatedStorage
end

-- Mining cooldown to prevent spam
local miningCooldowns = {}

-- Handle mining requests
miningRemote.OnServerEvent:Connect(function(player, oreType, oreModel)
	-- Validate player and character
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end
	
	-- Check cooldown
	local userId = player.UserId
	local lastMine = miningCooldowns[userId]
	if lastMine and tick() - lastMine < 0.5 then return end
	miningCooldowns[userId] = tick()
	
	-- Validate ore type
	local oreData = OreData[oreType]
	if not oreData then
		warn("Invalid ore type: " .. tostring(oreType))
		return
	end
	
	-- Validate ore model exists and is in range
	if not oreModel or not oreModel.Parent then return end
	
	local orePart = oreModel:FindFirstChildOfClass("BasePart")
	if not orePart then return end
	
	-- Check distance (max 15 studs)
	local distance = (rootPart.Position - orePart.Position).Magnitude
	if distance > 15 then
		warn(player.Name .. " tried to mine ore too far away")
		return
	end
	
	-- Give XP
	if _G.GiveXP then
		_G.GiveXP(player, oreData.experience, "Mining: " .. oreType)
	end
	
	-- Handle drops
	if oreData.drops then
		for _, drop in ipairs(oreData.drops) do
			-- Roll for drop chance
			if math.random() <= drop.chance then
				-- TODO: Add items to player inventory
				-- For now, just print
				print("💎 " .. player.Name .. " mined " .. drop.amount .. "x " .. drop.item)
				
				-- Update quest if mining quest exists
				if _G.UpdateQuest then
					_G.UpdateQuest(player, "Mine", {
						oreType = oreType,
						amount = drop.amount
					})
				end
			end
		end
	end
	
	-- Remove or respawn ore (you can customize this)
	-- Option 1: Remove the ore
	-- oreModel:Destroy()
	
	-- Option 2: Make it invisible and respawn later
	-- orePart.Transparency = 1
	-- orePart.CanCollide = false
	-- task.wait(30) -- Respawn after 30 seconds
	-- orePart.Transparency = 0
	-- orePart.CanCollide = true
	
	-- Option 3: Just leave it (for testing)
	-- Do nothing
	
	print("⛏️ " .. player.Name .. " mined " .. oreType .. " (+" .. oreData.experience .. " XP)")
end)

print("✅ MiningHandler server ready")
