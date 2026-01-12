local Action_Idle = {}
Action_Idle.__index = Action_Idle

function Action_Idle.new()
	return setmetatable({}, Action_Idle)
end

function Action_Idle:Run(npc)
	-- Do nothing, maybe play an idle animation
	return "SUCCESS"
end

return Action_Idle