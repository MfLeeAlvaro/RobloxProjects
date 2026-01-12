--|| Services ||--
local Players = game:GetService("Players")

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage") 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--|| Modules ||--

local Ragdoll = {}

Ragdoll.StartRagdoll = function(Character, Type)
	if Character and Character:FindFirstChild("Ragdoll") then return end
	if not Character then return end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	local Humanoid = Character:FindFirstChild("Humanoid")
	local Torso = Character:FindFirstChild("Torso")
	
	for _, AnimationTrack in ipairs(Humanoid:GetPlayingAnimationTracks()) do
		AnimationTrack:Stop()
	end

	Humanoid.PlatformStand = true
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	Humanoid.AutoRotate = false

	local ragdollValue = Instance.new("BoolValue")
	ragdollValue.Name = "Ragdoll"
	ragdollValue.Parent = Character

	for _,v in ipairs(Torso:GetChildren()) do
		if v:IsA("Motor6D") and v.Part0 == Torso then
			local ballSocket = Instance.new("BallSocketConstraint")
			ballSocket.Name = "DeleteMe"

			local attachment0 = Instance.new("Attachment")
			local attachment1 = Instance.new("Attachment")

			attachment0.Name = "DeleteMe"
			attachment1.Name = "DeleteMe"

			attachment0.Parent = v.Part0
			attachment0.CFrame = v.C0

			attachment1.Parent = v.Part1
			attachment1.CFrame = v.C1

			ballSocket.Parent = v.Part0

			ballSocket.Attachment0 = attachment0
			ballSocket.Attachment1 = attachment1

			v.Part0 = nil
		end
	end
	for _,v in ipairs(Character:GetChildren()) do
		if v:IsA("Part") and v.Name ~= "HumanoidRootPart" then
			local Hitbox = v:Clone()
			Hitbox.Name = "DeleteMe"
			Hitbox.Parent = Character
			Hitbox.Size = v.Size
			Hitbox.Anchored = false
			Hitbox.CanCollide = true
			Hitbox.Transparency = 1

			local weld = Instance.new("Weld")
			weld.Parent = Hitbox
			weld.Name = "DeleteMe"

			weld.Part0 = v
			weld.Part1 = Hitbox
		end
	end
end

Ragdoll.EndRagdoll = function(Character)
	if not Character then return end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	local Humanoid = Character:FindFirstChild("Humanoid")
	local Torso = Character:FindFirstChild("Torso")

	for _,v in ipairs(Character:GetDescendants()) do
		if v.Name == "DeleteMe" or v.Name == "Ragdoll" then
			v:Destroy()
		end
	end
	for _,v in ipairs(Torso:GetChildren()) do
		if v:IsA("Motor6D") then
			v.Part0 = Torso
		end
	end

	local oldRotation = HumanoidRootPart.Orientation
	Humanoid.PlatformStand = false
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	Humanoid.AutoRotate = true
end

Ragdoll.DurationRagdoll = function(Character,Duration)
	coroutine.resume(coroutine.create(function()
		Ragdoll.StartRagdoll(Character)
		wait(Duration)
		Ragdoll.EndRagdoll(Character)
	end))
end

return Ragdoll