local rs = game:GetService("RunService")

local stunnedHumanoids = {}
local currDur = {}
local prevTime = {}

local prevWalkSpeed = {}
local prevJumpPower = {}

local displayTime = false

local stun = {}

function stun.Stun(humanoid:Humanoid,Duration)
	if not table.find(stunnedHumanoids,humanoid) then
		table.insert(stunnedHumanoids,humanoid)
		--print("Stun Started "..stunDuration.." Seconds Stun")
		prevTime[humanoid] = os.clock()
		currDur[humanoid] = Duration

		local ragTrigger = humanoid.Parent:WaitForChild("RagdollTrigger")
		--humanoid.Parent:SetAttribute("Slowed",true)

		ragTrigger.Value = true
		
		local cd 
		cd = rs.Heartbeat:Connect(function()
			local passedTime = os.clock() - prevTime[humanoid]

			if displayTime then
				--print(string.format("%.2f",passedTime))
			end

			if passedTime >= currDur[humanoid] then
				for i=1, #stunnedHumanoids,1 do
					if stunnedHumanoids[i] == humanoid then
						table.remove(stunnedHumanoids,i)
					end
				end
				
				if humanoid.Health > 0 then
					ragTrigger.Value = false
				end


				if cd then
					cd:Disconnect()
				end
			end
		end)
	else
		--print("Stun Duration Changed! "..stunDuration.." Seconds Stun")
		prevTime[humanoid] = os.clock()
		currDur[humanoid] = Duration
	end
end

return stun
