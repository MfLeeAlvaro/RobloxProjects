--// Variables \\--

local TS = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local effectCreator = {}

local assets = replicatedStorage:FindFirstChild("Assets")
local effectFolder = game:GetService("Workspace"):FindFirstChild("World"):FindFirstChild("Effects")

--// Create Effect \\--

local function raycast(origin, direction, filterType, filterTable)
	
	--// Creating raycast \\--
	
	local raycastParameters = RaycastParams.new()
	raycastParameters.FilterType = filterType
	raycastParameters.FilterDescendantsInstances = filterTable
	raycastParameters.RespectCanCollide = true
	
	local raycastResult = game:GetService("Workspace"):Raycast(origin, direction, raycastParameters)
	
	--// Returning result \\--
	
	if raycastResult ~= nil then		
		return raycastResult	
	else		
		return "Nothing was hit"		
	end
	
end

function effectCreator.Create(Parameters)
	
	local allDebris = {}
	
	--// Variables \\--
	
	local localPlayer = players.LocalPlayer
	
	local parameterList = {
		Subject = Parameters.Subject,
		Radius = tonumber(Parameters.Radius) * 100,
		enchancedSpeed = Parameters.enchancedSpeed
	}
	
	if parameterList.enchancedSpeed == nil then
		parameterList.enchancedSpeed = false
	end
	
	local rate = 0.1
	
	if parameterList.enchancedSpeed == true then
		rate = 0.05
	end
	
	local subjectHRP = parameterList.Subject:FindFirstChild("HumanoidRootPart")
	local subjectHumanoid = parameterList.Subject:FindFirstChildOfClass("Humanoid")
	local subjectStates = parameterList.Subject:FindFirstChild("States")

	--// Creating effect \\--
	
	local createEffect = coroutine.wrap(function()
		
		repeat wait(rate)
			
			--// Checking distance \\--
			
			local currCamera = game.Workspace.CurrentCamera
			local Pos, InScreen = game.Workspace.CurrentCamera:WorldToScreenPoint(parameterList.Subject.PrimaryPart.Position)
			local distanceTo = (currCamera.CFrame.Position - parameterList.Subject.PrimaryPart.Position).Magnitude
			
			--// Checking \\--
			
			if distanceTo < 150 and InScreen == true then
				
				--// Getting random point \\--

				local randomPoint = CFrame.new(
					subjectHRP.Position.X,
					subjectHRP.Position.Y,
					subjectHRP.Position.Z
				) * CFrame.Angles(0, math.rad(math.random(-180,180)), 0)

				randomPoint *= CFrame.new(0, 0, (math.random(-parameterList.Radius, parameterList.Radius) / 100))

				local raycasting = raycast(
					randomPoint.Position,
					Vector3.new(0,-15,0),
					Enum.RaycastFilterType.Include,
					{
						game.Workspace.World.Map
					}
				)

				--// Getting raycast \\--

				if raycasting ~= "Nothing was hit" then

					--// Creating debris \\--

					local debrisSize = math.random(20,100) / 100
					
					if parameterList.enchancedSpeed == true then
						debrisSize *= 2.5
					end
					
					local newDebris = workspace.World.Map.ConcretePaths.Concrete
					newDebris.CanCollide = false

					newDebris.Material = raycasting.Instance.Material
					newDebris.Color = raycasting.Instance.Color
					newDebris.Position = raycasting.Position
					newDebris.Orientation = Vector3.new(math.random(-180,180), math.random(-180,180), math.random(-180,180))

					newDebris.Size = Vector3.new(
						debrisSize * (math.random(80,120) / 100),
						debrisSize * (math.random(80,120) / 100),
						debrisSize * (math.random(80,120) / 100)
					)

					table.insert(allDebris, newDebris)
					newDebris.Parent = effectFolder.Debris

					--// Adding velocities \\--

					local angular = Instance.new("BodyAngularVelocity", newDebris)
					angular.MaxTorque = Vector3.new(25000,25000,25000)
					angular.AngularVelocity = Vector3.new(math.random(-50,50) / 10, math.random(-50,50) / 10, math.random(-50,50) / 10)
					
					local upSpeed = math.random(15,70) / 10
					
					if parameterList.enchancedSpeed == true then
						upSpeed *= 3.5
					end
					
					local velocity = Instance.new("BodyVelocity", newDebris)
					velocity.MaxForce = Vector3.new(250000,250000,250000)
					velocity.Velocity = Vector3.new(0, upSpeed, 0)

				end
				
				--// Checking rocks \\--

				for i, v in pairs(allDebris) do

					local magnitudeDistance = (subjectHRP.Position - v.Position).Magnitude

					if magnitudeDistance > (parameterList.Radius / 100) then

						table.remove(allDebris, i)

						game.Debris:AddItem(v, 1.5)

						TS:Create(v, TweenInfo.new(1, Enum.EasingStyle.Sine),{
							Transparency = 1
						}):Play()

					end

				end
				
			end
						
		until parameterList.Subject.Parent == nil or subjectHumanoid.Health <= 0 or not subjectStates:FindFirstChild("Floating Rocks")
		
		--// Making all rocks fall \\--
		
		for i, v in pairs(allDebris) do
			
			v.CanCollide = true
			
			--// Destroying velocity \\--
			
			for i, v in pairs(v:GetChildren()) do
				if v:IsA("BodyVelocity") or v:IsA("BodyAngularVelocity") then
					
					v:Destroy()
					
				end
			end
			
			--// Hitting ground \\--
			
			local groundHit
			
			groundHit = v.Touched:Connect(function(hitPart)
				if hitPart:FindFirstAncestor("Map") then
					
					groundHit:Disconnect()
					
					--// Sound effect \\--
					
					local allSounds = v:FindFirstChild("collisionSound"):GetChildren()
					local randomSound = allSounds[math.random(1,#allSounds)]

					randomSound.PlaybackSpeed = math.random(80,120) / 100
					randomSound:Play()
					
					--// Despawning \\--
					
					local despawn = coroutine.wrap(function()
						
						wait(math.random(10,35) / 10)
						
						v.Anchored = true
						v.CanCollide = false
						
						game.Debris:AddItem(v, 2.5)
						
						TS:Create(v, TweenInfo.new(2, Enum.EasingStyle.Sine),{
							Transparency = 1,
							Position = v.Position + Vector3.new(0,-2,0),
							Orientation = v.Orientation + Vector3.new(math.random(-90,90), math.random(-90,90), math.random(-90,90))
						}):Play()
						
					end)
					
					despawn()
					
				end
			end)
			
		end
		
	end)
	
	createEffect()
	
end

--// Returning \\--

return effectCreator