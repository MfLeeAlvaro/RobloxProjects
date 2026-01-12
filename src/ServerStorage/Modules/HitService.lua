local debris = game:GetService("Debris")
local RP = game:GetService("ReplicatedStorage")

local modules = game:WaitForChild("ServerStorage"):FindFirstChild("Modules")
local RagdollModule = require(RP.Modules.Ragdoll)
local StunHandler = require(modules.StunHandlerV2)

local Damage = 3

local module = {}

-- Function to handle when a player is hit
function module.hit(plr, enemyHum, knockback, attackerKnockback, attacker, ragdoll, maxForce, blockBreak)
	local enemy = enemyHum.Parent
	local enemyplr = game.Players:GetPlayerFromCharacter(enemy)
	local enemy2 = game:WaitForChild("Players").LocalPlayer
	local enemyHumRp = enemy:WaitForChild("HumanoidRootPart")

	local attackerHumRp = attacker:WaitForChild("HumanoidRootPart")
	local attackerHum = attacker:WaitForChild("Humanoid")

	local enemyBlocking = enemy:GetAttribute("Blocking")
	local enemyStunned = enemy:GetAttribute("Stunned")
	local otherenemy = game.Players.LocalPlayer
	
	local combo = attacker:GetAttribute("Combo")
	local gojoSFX = RP.SFX.M1sFolder.Gojo
	
	local function GetSound()
		
		if attacker.Ultimate.Char.Value == "Gojo" then
			
			if combo == 1 then
				local hit = gojoSFX.Hit.Punch1:Clone()
				hit.Parent = enemyHumRp
				hit:Play()
				debris:AddItem(hit, 2)
			elseif combo == 2 then
				local hit = gojoSFX.Hit.Punch2:Clone()
				hit.Parent = enemyHumRp
				hit:Play()
				debris:AddItem(hit, 2)
			elseif combo == 3 then
				local hit = gojoSFX.Hit.Punch3:Clone()
				hit.Parent = enemyHumRp
				hit:Play()
				debris:AddItem(hit, 2)
			elseif combo == 4 then
				local hit = gojoSFX.Hit.Punch4:Clone()
				hit.Parent = enemyHumRp
				hit:Play()
				debris:AddItem(hit, 2)
			end
		end
	end

	if not blockBreak then
		if enemyBlocking then
			local direction = (attackerHumRp.Position - enemyHumRp.Position).Unit
			local enemyLook = enemyHumRp.CFrame.LookVector

			local dot = direction:Dot(enemyLook)

			if dot > -0.4 then
				print("Blocked!!!!!!")
				return
			else
				enemy:SetAttribute("Blocking", false)
			end 
		end
	end
	
    GetSound()
	
	if combo == 1 or combo == 2 or combo == 3 then
		local chance = math.random(1,3)
		if chance == 1 then
			local anim = enemyHum:LoadAnimation(RP.Animations.HitAnims.Hit1)
			anim:Play()
		elseif chance == 2 then
			local anim = enemyHum:LoadAnimation(RP.Animations.HitAnims.Hit2)
			anim:Play()
		elseif chance == 3 then
			local anim = enemyHum:LoadAnimation(RP.Animations.HitAnims.Hit3)
			anim:Play()
		end
	end

	enemyHum:TakeDamage(Damage)
	
	local HitEffects = RP.Assets.VFX.Combat["Hit Effect"].Attachment:Clone()
	
	HitEffects.Parent = enemyHumRp
	for _,Particles in pairs(HitEffects:GetDescendants()) do
		if Particles:IsA("ParticleEmitter") then
			Particles:Emit(Particles:GetAttribute("EmitCount"))
		end
	end
	game.Debris:AddItem(HitEffects, 2)

	if knockback then
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = maxForce
		bv.P = math.huge
		bv.Velocity = knockback
		bv.Parent = enemyHumRp

		debris:AddItem(bv, 0.2)
	end

	if attackerKnockback then
		StunHandler.Stun(enemyHum, 1)
		if enemy:GetAttribute("Dummy") == true then

		else
			RP.Remotes.Cancel:FireClient(enemyplr)
		end
		task.delay(0,function()
			if plr.Character.Ultimate.Ultimate.Value == false then
				if plr.Character.Ultimate.Ult.Value == 40 then return end
				plr.Character.Ultimate.Ult.Value += 0.2
			end
		end)
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = maxForce
		bv.P = math.huge
		bv.Velocity = attackerKnockback
		bv.Parent = attackerHumRp

		debris:AddItem(bv, 0.2)
	end

	if ragdoll then
		RagdollModule.Ragdoll(enemy)
		task.delay(2, function()
			RagdollModule.EndRagdoll(enemy)
		end)
	end
end

return module
