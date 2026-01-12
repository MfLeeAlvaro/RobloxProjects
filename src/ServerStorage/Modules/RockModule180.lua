local RockModule = {}

local TweenService = game:GetService("TweenService")

function RockModule.RayCastEffect(rootpart, numrocks, distance, distance2, Size, Size2)
	local RayParams = RaycastParams.new()
	RayParams.FilterDescendantsInstances = {workspace.DebrisFolder}
	RayParams.FilterType = Enum.RaycastFilterType.Blacklist

	local Angle = 0
	local distancefromplayer = 0

	for i = 1,numrocks do
		
		task.wait(.01)
		
		local MainPart = Instance.new("Part")
		MainPart.Anchored = true
		MainPart.Size = Vector3.new(1,1,1)
		MainPart.CFrame = rootpart.CFrame * CFrame.new(0,0,-2.5)
		MainPart.CanCollide = false

		local Part = Instance.new("Part")
		Part.Anchored = true
		Part.CFrame = MainPart.CFrame * CFrame.fromEulerAnglesXYZ(0,math.rad(Angle),0) * CFrame.new(distance,1,distancefromplayer) --* CFrame.Angles(0,0,math.rad(20))
		
		local Part2 = Instance.new("Part")
		Part2.Anchored = true
		Part2.CFrame = MainPart.CFrame * CFrame.fromEulerAnglesXYZ(0,math.rad(Angle),0) * CFrame.new(distance2,1,distancefromplayer) --* CFrame.Angles(0,0,math.rad(20))

		game.Debris:AddItem(Part2,5.5)
		game.Debris:AddItem(Part,5.5)

		local RayCast = workspace:Raycast(Part.CFrame.p,Part.CFrame.UpVector * - 20, RayParams)
		local RayCast2 = workspace:Raycast(Part2.CFrame.p,Part2.CFrame.UpVector * - 20, RayParams)

		if RayCast and RayCast2 then
			Part.CanCollide = false 
			Part.Position = RayCast.Position + Vector3.new(0,-5,0)
			Part.Material = RayCast.Instance.Material
			Part.Color = RayCast.Instance.Color
			Part.Size = Vector3.new(Size,Size,Size)
			Part.Orientation = Vector3.new(math.random(-180, 180),math.random(-180, 180),math.random(-180, 180))
			Part.Parent = workspace.DebrisFolder 
			
			Part2.CanCollide = false
			Part2.Position = RayCast2.Position + Vector3.new(0,-5,0)
			Part2.Material = RayCast2.Instance.Material
			Part2.Color = RayCast2.Instance.Color
			Part2.Size = Vector3.new(Size2,Size2,Size2)
			Part2.Orientation = Vector3.new(math.random(-180, 180),math.random(-180, 180),math.random(-180, 180))
			Part2.Parent = workspace.DebrisFolder

			local Tween = TweenService:Create(Part,TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.In),{Position = Part.Position + Vector3.new(0,5,0)}):Play()
			local Tween = TweenService:Create(Part2,TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.In),{Position = Part2.Position + Vector3.new(0,5,0)}):Play()
			delay(4,function()
				local Tween = TweenService:Create(Part,TweenInfo.new(1),{Transparency = 1,Position = Part.Position + Vector3.new(0,-5,0)}):Play()
				local Tween = TweenService:Create(Part,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Position = Part.Position + Vector3.new(0,-5,0)}):Play()
				local Tween = TweenService:Create(Part,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Size = Vector3.new(0,0,0)}):Play()
				local Tween = TweenService:Create(Part2,TweenInfo.new(1),{Transparency = 1,Position = Part2.Position + Vector3.new(0,-5,0)}):Play()
				local Tween = TweenService:Create(Part2,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Position = Part2.Position + Vector3.new(0,-5,0)}):Play()
				local Tween = TweenService:Create(Part2,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Size = Vector3.new(0,0,0)}):Play()
			end)
		end
		--Angle+=180
		distancefromplayer -= 5
		Size2 += .02
		Size += .02
		--Angle+=180
	end
end

return RockModule
