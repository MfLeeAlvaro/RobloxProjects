local Action_MoveTo = {}
Action_MoveTo.__index = Action_MoveTo

function Action_MoveTo.new(range)
    return setmetatable({ range = range or 5 }, Action_MoveTo)
end

function Action_MoveTo:Run(enemy, context)
	local targetPart = context and context.target
	if not targetPart then
		return "FAILURE"
	end

	local humanoid = enemy.model:FindFirstChild("Humanoid")
	local root = enemy.model.PrimaryPart
	
	if humanoid and root then
		local dist = (enemy.model.PrimaryPart.Position - targetPart.Position).Magnitude
		
		local align = root:FindFirstChild("FaceTargetAlign")
		if not align then
			warn("No FaceTargetAlign Found")
			return "FAILURE"
		end

		-- Too close → move backwards
		if dist < (self.range - 4) then
			align.Enabled = false
			local direction = (root.Position - targetPart.Position).Unit
			local retreatPos = root.Position + direction * 4
			humanoid:MoveTo(retreatPos)
			return "RUNNING"
		end

		-- Within range → stop & face player
		if dist <= self.range then
			humanoid:MoveTo(root.Position)
			return "SUCCESS"
		end

		-- Too far → chase forward
		align.Enabled = false
		humanoid:MoveTo(targetPart.Position)
		return "RUNNING"
	end
	return "FAILURE"
end

return Action_MoveTo