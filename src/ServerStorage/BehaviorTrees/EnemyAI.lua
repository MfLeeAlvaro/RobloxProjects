local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local function BehaviorTree(damage, attackRange, sightRange, attackAnimation)
	local lastAttackTime = 0
	local attackCooldown = 3 -- Seconds between attacks

	return {
		Tick = function(self, enemy)
			if not enemy.model or not enemy.model.Parent then return end

			local humanoid = enemy.model:FindFirstChildOfClass("Humanoid")
			local rootPart = enemy.model:FindFirstChild("HumanoidRootPart")

			if not humanoid or not rootPart then return end

			-- Find nearest player
			local nearestPlayer = nil
			local nearestDistance = sightRange

			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local playerHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
					if playerHumanoid and playerHumanoid.Health > 0 then
						local distance = (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
						if distance < nearestDistance then
							nearestPlayer = player.Character
							nearestDistance = distance
						end
					end
				end
			end

			-- If player found
			if nearestPlayer then
				local targetRoot = nearestPlayer:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					local distance = (targetRoot.Position - rootPart.Position).Magnitude

					-- Attack if in range
					if distance <= attackRange then
						humanoid.WalkSpeed = 0
						humanoid:MoveTo(rootPart.Position) -- Stop moving

						local currentTime = tick()
						if currentTime - lastAttackTime >= attackCooldown then
							lastAttackTime = currentTime

							-- Deal damage
							local targetHumanoid = nearestPlayer:FindFirstChildOfClass("Humanoid")
							if targetHumanoid then
								targetHumanoid:TakeDamage(damage)
							end
						end
					else
						-- Chase player
						humanoid.WalkSpeed = enemy.speed
						humanoid:MoveTo(targetRoot.Position)
					end
				end
			else
				-- NO PLAYER FOUND - IDLE
				humanoid.WalkSpeed = 0
				humanoid:MoveTo(rootPart.Position) -- Stay in place
			end
		end
	}
end

return BehaviorTree