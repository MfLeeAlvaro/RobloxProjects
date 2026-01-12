local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get or create remote
local combatRemote = ReplicatedStorage:FindFirstChild("SimpleCombatRemote")
if not combatRemote then
	combatRemote = Instance.new("RemoteEvent")
	combatRemote.Name = "SimpleCombatRemote"
	combatRemote.Parent = ReplicatedStorage
end

-- Damage settings
local DAMAGE = {
	[1] = 15, -- First attack
	[2] = 20, -- Second attack
	[3] = 30, -- Third attack (finisher)
}

local RANGE = 8
local cooldowns = {}

combatRemote.OnServerEvent:Connect(function(player, comboCount)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	-- Cooldown check
	local userId = player.UserId
	local lastAttack = cooldowns[userId]
	if lastAttack and tick() - lastAttack < 0.4 then return end
	cooldowns[userId] = tick()

	-- Create hitbox
	local hitbox = Instance.new("Part")
	hitbox.Size = Vector3.new(RANGE, 6, RANGE)
	hitbox.CFrame = rootPart.CFrame * CFrame.new(0, 0, -RANGE/2)
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Anchored = true
	hitbox.Parent = workspace

	game:GetService("Debris"):AddItem(hitbox, 0.1)

	-- Detect hits
	local hitList = {}
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {character}
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local hitParts = workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size, overlapParams)

	for _, part in pairs(hitParts) do
		local targetModel = part.Parent
		if targetModel then
			local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
			local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")

			if targetHumanoid and targetRoot and not hitList[targetHumanoid] then
				hitList[targetHumanoid] = true

				-- Get damage for this combo
				local damage = DAMAGE[comboCount] or 15

				-- Apply damage
				targetHumanoid:TakeDamage(damage)

				-- Knockback
				local direction = (targetRoot.Position - rootPart.Position).Unit
				local knockbackForce = comboCount == 3 and 20 or 10

				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
				bodyVelocity.Velocity = direction * knockbackForce + Vector3.new(0, 5, 0)
				bodyVelocity.Parent = targetRoot
				game:GetService("Debris"):AddItem(bodyVelocity, 0.2)

				-- Tag with creator for XP
				local creatorTag = Instance.new("ObjectValue")
				creatorTag.Name = "creator"
				creatorTag.Value = player
				creatorTag.Parent = targetHumanoid
				game:GetService("Debris"):AddItem(creatorTag, 2)

				-- Update kill quest when enemy dies
				targetHumanoid.Died:Connect(function()
					if _G.UpdateQuest then
						-- Get zombie type (model name)
						local zombieType = targetModel.Name

						-- Update quest
						_G.UpdateQuest(player, "Kill", {
							enemyType = zombieType,
							amount = 1
						})

						print("📊 " .. player.Name .. " killed " .. zombieType .. " - quest updated")
					end
				end)

				print(player.Name .. " hit " .. targetModel.Name .. " (Combo " .. comboCount .. ") for " .. damage .. " damage")
			end
		end
	end
end)

