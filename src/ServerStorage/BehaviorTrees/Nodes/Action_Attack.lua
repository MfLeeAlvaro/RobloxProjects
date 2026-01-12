local Action_Attack = {}
Action_Attack.__index = Action_Attack

function Action_Attack.new(damage, range, cooldown, animationId)
	return setmetatable({
		damage = damage or 10,
		range = range or 5,
		cooldown = cooldown or 0.5,
		animationId = animationId -- optional attack animation
	}, Action_Attack)
end

function Action_Attack:Run(enemy, context)
	local targetPart = context and context.target
	if not targetPart then
		return { status = "FAILURE" }
	end

	local char = targetPart.Parent
	local humanoid = char and char:FindFirstChild("Humanoid")
	if humanoid then
		local dist = (enemy.model.PrimaryPart.Position - targetPart.Position).Magnitude
		if dist <= self.range then
			-- Deal damage
			humanoid:TakeDamage(self.damage)

			-- Play attack animation
			if self.animationId then
				local enemyHumanoid = enemy.model:FindFirstChild("Humanoid")
				if enemyHumanoid then
					local animator = enemyHumanoid:FindFirstChildOfClass("Animator")
					if animator then
						local anim = Instance.new("Animation")
						anim.AnimationId = "rbxassetid://" .. self.animationId
						local track = animator:LoadAnimation(anim)
						track:Play()
					end
				end
			end

			-- Pause for a little
			task.wait(self.cooldown)
			
			return { status = "SUCCESS", target = targetPart }
		end
	end

	return { status = "FAILURE", target = targetPart }
end

return Action_Attack
