local Sequence = {}
Sequence.__index = Sequence

function Sequence.new(children)
	return setmetatable({ children = children }, Sequence)
end

function Sequence:Run(enemy, context)
	local currentContext = context or {}
	for _, child in ipairs(self.children) do
		local result = child:Run(enemy, currentContext)

		-- If a node returns a table (status + data), merge it into context
		if type(result) == "table" then
			currentContext = result
			if result.status ~= "SUCCESS" then
				return result
			end
		elseif result ~= "SUCCESS" then
			return result
		end
	end
	return { status = "SUCCESS" }
end

return Sequence