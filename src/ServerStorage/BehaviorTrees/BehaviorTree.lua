local BehaviorTree = {}
BehaviorTree.__index = BehaviorTree

function BehaviorTree.new(root)
	return setmetatable({ root = root }, BehaviorTree)
end

function BehaviorTree:Tick(enemy)
	self.root:Run(enemy)
end

return BehaviorTree