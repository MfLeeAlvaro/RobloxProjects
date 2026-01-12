--// Services
local ServerScriptService = game:WaitForChild("ServerScriptService")


--// Check if EnemyHandler exists
if not ServerScriptService:FindFirstChild("EnemyHandler") then
	warn("ERROR: EnemyHandler module not found!")
	return
end

--// Load EnemyHandler
local success, EnemyHandler = pcall(function()
	return require(ServerScriptService.EnemyHandler)
end)

if not success then
	warn("ERROR: Failed to load EnemyHandler:", EnemyHandler)
	return
end

--// Setup
local zonesFolder = workspace:WaitForChild("Zones")
local spawnInterval = 20

-- ZOMBIE CAPS PER ZONE
local zombieCaps = {
	GreenZone = 0,      -- No zombies
	YellowZone = 40,    -- Max 40 per yellow zone
	RedZone = 60,       -- Max 60 per red zone
	BlackZone = 100     -- Max 100 per black zone (raid!)
}

-- Track zombie counts per zone
local zoneZombieCounts = {}

--// Zone Configuration
local zoneConfig = {
	GreenZone = {
		spawnCount = {},
		spawnChance = 0
	},

	YellowZone = {
		spawnCount = {
			BlackZombie = 5,
			ClownZombie = 4,
			MexicanZombie = 3,
			Stalker = 2,
			BigBlackZombie = {count = 1, chance = 0.1},
			MinerZombie = {count = 1, chance = 0.1}
		},
		spawnChance = 0.4
--[[
	RedZone = {
		spawnCount = {
			-- Some weak zombies
			BlackZombie = 3,
			ClownZombie = 2,
			MexicanZombie = 2,
			Stalker = 3,
			-- More stronger zombies (50% chance each)
			BigBlackZombie = {count = 3, chance = 0.5},
			BruteZombie = {count = 2, chance = 0.5},
			MinerZombie = {count = 2, chance = 0.5}
		},
		spawnChance = 0.7 -- 70% chance to spawn
	},
	BlackZone = {
		spawnCount = {
			-- RAID MODE - Tons of everything!
			BlackZombie = 8,
			ClownZombie = 6,
			MexicanZombie = 5,
			Stalker = 7,
			-- Lots of strong zombies (always spawn)
			BigBlackZombie = 10,
			BruteZombie = 8,
			MinerZombie = 6
		},
		spawnChance = 1 -- Always spawns (100%)
	}
--]]
	}

	-- Add RedZone and BlackZone when ready
}

--// Function to count zombies in a zone
local function countZombiesInZone(zonePart)
	local count = 0
	local enemiesFolder = workspace:FindFirstChild("Enemies")

	if not enemiesFolder then return 0 end

	for _, zombie in pairs(enemiesFolder:GetChildren()) do
		if zombie:IsA("Model") and zombie.PrimaryPart then
			local zombiePos = zombie.PrimaryPart.Position
			local zonePos = zonePart.Position
			local zoneSize = zonePart.Size

			-- Check if zombie is inside zone
			if math.abs(zombiePos.X - zonePos.X) <= zoneSize.X / 2
				and math.abs(zombiePos.Y - zonePos.Y) <= zoneSize.Y / 2
				and math.abs(zombiePos.Z - zonePos.Z) <= zoneSize.Z / 2 then
				count += 1
			end
		end
	end

	return count
end

--// Function to get random position in zone
local function getRandomPositionInZone(zonePart)
	local size = zonePart.Size
	local pos = zonePart.Position

	local randomX = pos.X + math.random(-size.X/2, size.X/2)
	local randomZ = pos.Z + math.random(-size.Z/2, size.Z/2)
	local y = pos.Y + (size.Y/2) + 3

	return Vector3.new(randomX, y, randomZ)
end

--// Spawn wave in a zone
local function spawnWaveInZone(zoneName, zoneData, zonePart)
	-- Check spawn chance
	if math.random() > zoneData.spawnChance then
		return
	end

	-- Check zombie cap for this zone
	local currentCount = countZombiesInZone(zonePart)
	local maxCap = zombieCaps[zoneName] or 50

	if currentCount >= maxCap then
		print("⊘ " .. zonePart.Name .. " at zombie cap (" .. currentCount .. "/" .. maxCap .. ")")
		return
	end

	print("🟢 Spawning in " .. zonePart.Name .. " (" .. currentCount .. "/" .. maxCap .. ")")

	local spawned = 0

	for enemyType, spawnData in pairs(zoneData.spawnCount) do
		local count, chance

		-- Check if it's a rare spawn with chance
		if type(spawnData) == "table" then
			count = spawnData.count
			chance = spawnData.chance

			-- Roll for spawn chance
			if math.random() > chance then
				continue
			end
		else
			count = spawnData
		end

		-- Spawn zombies up to cap
		for i = 1, count do
			-- Check if we're at cap
			if currentCount + spawned >= maxCap then
				print("  ⚠️ Reached cap, stopping spawn")
				return
			end

			local enemy = EnemyHandler.new(enemyType)

			if enemy then
				local spawnPos = getRandomPositionInZone(zonePart)
				enemy:spawn(spawnPos)
				spawned += 1
				task.wait(0.1)
			end
		end
	end
end

--// Main spawn loop
local function spawnAllZones()

	for _, zonePart in pairs(zonesFolder:GetChildren()) do
		if zonePart:IsA("BasePart") then
			local zoneData = zoneConfig[zonePart.Name]

			if zoneData then
				spawnWaveInZone(zonePart.Name, zoneData, zonePart)
			end
		end
	end
end

--// Initial spawn
spawnAllZones()

--// Continuous spawning
while true do
	task.wait(spawnInterval)
	spawnAllZones()
end