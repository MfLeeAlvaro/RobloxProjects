local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Condition_CanSeePlayer = {}
Condition_CanSeePlayer.__index = Condition_CanSeePlayer

function Condition_CanSeePlayer.new(radius, losCheckInterval)
	return setmetatable({
		radius = radius or 30,
		losCheckInterval = losCheckInterval or 0.3,
		_lastCheck = 0,
		_cachedTarget = nil
	}, Condition_CanSeePlayer)
end

function Condition_CanSeePlayer:Run(enemy)
	if not enemy.model or not enemy.model.PrimaryPart then
		return { status = "FAILURE" }
	end

	local now = tick()
	local origin = enemy.model.PrimaryPart.Position

	-- Use cached target between checks
	if now - self._lastCheck < self.losCheckInterval and self._cachedTarget and self._cachedTarget.Parent then
		return { status = "SUCCESS", target = self._cachedTarget }
	end

	self._lastCheck = now
	local closestChar, closestDist = nil, math.huge

	-- Stage 1: Distance filtering
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local dist = (origin - char.HumanoidRootPart.Position).Magnitude
			if dist < closestDist and dist <= self.radius then
				closestDist = dist
				closestChar = char
			end
		end
	end

	if not closestChar then
		self._cachedTarget = nil
		return { status = "FAILURE" }
	end

	-- Stage 2: Raycast only to closest
	local targetPos = closestChar.HumanoidRootPart.Position
	local direction = (targetPos - origin).Unit * closestDist
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {
		enemy.model,
		enemy.model.Parent -- <- This is the folder containing all enemies
	}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(origin, direction, params)
	if not result or result.Instance:IsDescendantOf(closestChar) then
		self._cachedTarget = closestChar.HumanoidRootPart
		return { status = "SUCCESS", target = self._cachedTarget }
	end

	self._cachedTarget = nil
	return { status = "FAILURE" }
end

return Condition_CanSeePlayer
