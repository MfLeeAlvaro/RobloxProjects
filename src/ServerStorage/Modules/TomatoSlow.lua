local rs = game:GetService("RunService")

local stunnedHumanoids = {}
local currDur = {}
local prevTime = {}

local prevWalkSpeed = {}
local prevJumpPower = {}

local displayTime = false

local stun = {}

function stun.Stun(humanoid:Humanoid,slowDuration,speed)
	if not table.find(stunnedHumanoids,humanoid) then
		table.insert(stunnedHumanoids,humanoid)
		--print("Stun Started "..stunDuration.." Seconds Stun")
		prevTime[humanoid] = os.clock()
		currDur[humanoid] = slowDuration
		
		prevWalkSpeed[humanoid] = humanoid.WalkSpeed
		prevJumpPower[humanoid] = 50
		
		humanoid.WalkSpeed = speed or 14
		humanoid.JumpPower = 0
		
		humanoid.Parent:SetAttribute("Slowed",true)
		
		local cd 
		cd = rs.Heartbeat:Connect(function()
			local passedTime = os.clock() - prevTime[humanoid]

			if passedTime >= currDur[humanoid] then
				for i=1, #stunnedHumanoids,1 do
					if stunnedHumanoids[i] == humanoid then
						table.remove(stunnedHumanoids,i)
					end
				end
				humanoid.Parent:SetAttribute("Slowed",false)
				
				local plr = game.Players:GetPlayerFromCharacter(humanoid.Parent)
				
				if not humanoid.Parent:GetAttribute("Stunned") and not humanoid.Parent:GetAttribute("Blocking") then
					humanoid.WalkSpeed = prevWalkSpeed[humanoid]
					humanoid.JumpPower = prevJumpPower[humanoid]
				end

				
				if cd then
					cd:Disconnect()
				end
			end
		end)
	else
		--print("Stun Duration Changed! "..stunDuration.." Seconds Stun")
		prevTime[humanoid] = os.clock()
		currDur[humanoid] = slowDuration
	end
end

return stun
