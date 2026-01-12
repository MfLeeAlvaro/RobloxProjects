local Selector = {}
Selector.__index = Selector

function Selector.new(children)
	return setmetatable({ children = children }, Selector)
end

function Selector:Run(enemy, context)
	local currentContext = context or {}
	for _, child in ipairs(self.children) do
		local result = child:Run(enemy, currentContext)
		if type(result) == "table" then
			if result.status == "SUCCESS" then
				return result
			end
		elseif result == "SUCCESS" then
			return { status = "SUCCESS" }
		end
	end
	return { status = "FAILURE" }
end

return Selector