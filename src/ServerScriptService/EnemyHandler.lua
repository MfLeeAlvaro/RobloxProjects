--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// Modules
local BehaviorTree = require(ServerStorage.BehaviorTrees.EnemyAI)
local EnemyTemplates = require(ReplicatedStorage.Modules.EnemyTemplates)

--// Setup
local enemyFolder = Workspace:WaitForChild("Enemies")
local zoneFolder = Workspace:WaitForChild("Zones") -- assumes Zones folder with Yellow, Red, Black parts

local module = {enemies = {}}
local enemyClass = {}
enemyClass.__index = enemyClass

-- Per-zombie type level bonus
local zombieLevelBonus = {
    BigBlackZombie = 2,
    BruteZombie = 4,
    MinerZombie = 1,
    Stalker = 2,
    BossZombie = 8
}

-- Zone Level Ranges
local zoneLevelRange = {
    Yellow = {min = 1, max = 8},
    Red    = {min = 5, max = 14},
    Black  = {min = 10, max = 20}
}

-- Stat scaling per level
local function scaleStats(baseHealth, baseDamage, baseSpeed, level)
    return {
        health = baseHealth * (1 + level * 0.25),
        damage = baseDamage * (1 + level * 0.2),
        speed  = baseSpeed  * (1 + level * 0.04)
    }
end

-- XP scaling per level
local function scaleXP(baseXP, level)
    return math.floor(baseXP * (1 + level * 0.3))
end

-- Helper: Create Health Bar (DISABLED)
local function createHealthBar(zombieModel, name, level)
	return nil
end

-- Constructor
function module.new(enemyType, zoneName)
    local self = setmetatable({}, enemyClass)
    local data = EnemyTemplates[enemyType]
    if not data then
        warn("Enemy type '" .. enemyType .. "' not found!")
        return nil
    end

    self.id = HttpService:GenerateGUID(false)
    self.enemyType = enemyType
    self.baseData = data
    self.zoneName = zoneName

    -- Determine Level
    local range = zoneLevelRange[zoneName] or {min=1, max=5}
    local level = math.random(range.min, range.max)
    local bonus = zombieLevelBonus[enemyType] or 0
    self.level = math.clamp(level + bonus, 1, 20)

    -- Scale stats
    local stats = scaleStats(data.health, data.damage, data.speed, self.level)
    self.health = stats.health
    self.damage = stats.damage
    self.speed  = stats.speed
    self.attackRange = data.attackRange
    self.sightRange = data.sightRange
    self.respawnTime = data.respawnTime
    self.storedModel = data.model
    self.model = nil
    self.spawnPoint = nil
    self.attackAnimation = data.attackAnimation
    self.behaviorTree = BehaviorTree(self.damage, self.attackRange, self.sightRange, self.attackAnimation)

    module.enemies[self.id] = self
    return self
end

-- Spawn
function enemyClass:spawn(spawnpoint)
    if self.model then return end
    local modelClone = self.storedModel:Clone()
    if not modelClone.PrimaryPart then
        local rootPart = modelClone:FindFirstChild("HumanoidRootPart") or modelClone:FindFirstChild("Torso")
        if rootPart then
            modelClone.PrimaryPart = rootPart
        else
            warn("Zombie model '" .. modelClone.Name .. "' has no PrimaryPart!")
            modelClone:Destroy()
            return
        end
    end

    modelClone:SetPrimaryPartCFrame(CFrame.new(spawnpoint))
    modelClone.Parent = enemyFolder
    self.spawnPoint = spawnpoint
    self.model = modelClone

    local humanoid = modelClone:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = self.health
        humanoid.Health = self.health
        humanoid.WalkSpeed = self.speed

        -- Create health bar
        local healthBar = createHealthBar(modelClone, self.enemyType, self.level)

        -- Update health bar every frame
        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if healthBar then
                local ratio = humanoid.Health / humanoid.MaxHealth
                healthBar.Size = UDim2.new(math.clamp(ratio,0,1), 0, 1, 0)
                if ratio > 0.6 then
                    healthBar.BackgroundColor3 = Color3.new(0,1,0)
                elseif ratio > 0.3 then
                    healthBar.BackgroundColor3 = Color3.new(1,1,0)
                else
                    healthBar.BackgroundColor3 = Color3.new(1,0,0)
                end
            end
        end)

        humanoid.Died:Connect(function()
            self:die()
        end)
    else
        warn("Zombie model '" .. modelClone.Name .. "' has no Humanoid!")
    end

    self:runAI()
    return modelClone
end

-- AI loop
function enemyClass:runAI()
    task.spawn(function()
        while self.model and self.model.Parent do
            self.behaviorTree:Tick(self)
            task.wait(0.2)
        end
    end)
end

-- Death
function enemyClass:die()
    if not self.model then return end

    local model = self.model
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local killer = nil

    if humanoid then
        local tag = humanoid:FindFirstChild("creator")
        if tag and tag.Value and tag.Value:IsA("Player") then
            killer = tag.Value
        end
    end

    self.model = nil

    if killer and killer.Parent then
        local xpAmount = scaleXP(self:getXPReward(), self.level)
        if _G.GiveXP then
            _G.GiveXP(killer, xpAmount, "Killing " .. self.enemyType)
        end
        print(killer.Name .. " killed " .. self.enemyType .. " (Lv."..self.level..") and gained "..xpAmount.." XP")
    end

    task.delay(3, function()
        if model then model:Destroy() end
    end)

    if self.respawnTime then
        task.delay(self.respawnTime, function()
            self:spawn(self.spawnPoint)
        end)
    else
        module.enemies[self.id] = nil
    end
end

-- XP table
function enemyClass:getXPReward()
    local xpTable = {
        BlackZombie = 10,
        BigBlackZombie = 25,
        BruteZombie = 30,
        ClownZombie = 12,
        MexicanZombie = 10,
        MinerZombie = 20,
        Stalker = 15,
        BossZombie = 100
    }
    return xpTable[self.enemyType] or 10
end

-- Cleanup
function enemyClass:destroy()
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
    module.enemies[self.id] = nil
end

-- Knockback + Stun
function enemyClass:applyKnockback(direction, force, stunDuration)
    if not self.model then return end

    local rootPart = self.model:FindFirstChild("HumanoidRootPart")
    local humanoid = self.model:FindFirstChildOfClass("Humanoid")
    if rootPart and humanoid then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
        bodyVelocity.Velocity = direction * force + Vector3.new(0,20,0)
        bodyVelocity.Parent = rootPart
        game:GetService("Debris"):AddItem(bodyVelocity, 0.3)

        local originalSpeed = self.speed
        humanoid.WalkSpeed = 0
        task.delay(stunDuration, function()
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = originalSpeed
            end
        end)
    end
end

return module
