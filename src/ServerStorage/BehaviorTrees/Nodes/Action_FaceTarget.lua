local Action_FaceTarget = {}
Action_FaceTarget.__index = Action_FaceTarget

function Action_FaceTarget.new()
	return setmetatable({}, Action_FaceTarget)
end

function Action_FaceTarget:Run(enemy, context)
	local targetPart = context and context.target
	if not targetPart or not enemy.model or not enemy.model.PrimaryPart then
		return "FAILURE"
	end

	local root = enemy.model.PrimaryPart
	local align = root:FindFirstChild("FaceTargetAlign")

	if not align then
		warn("No FaceTargetAlign Found")
		return "FAILURE"
	end
	
	align.Enabled = true

	-- Set target orientation (look at player on same Y level)
	local lookAt = CFrame.lookAt(root.Position, Vector3.new(targetPart.Position.X, root.Position.Y, targetPart.Position.Z))
	align.CFrame = lookAt

	return "SUCCESS"
end

return Action_FaceTarget
