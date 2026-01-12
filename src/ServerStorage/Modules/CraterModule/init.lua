local Crater = {}
--------------------
local TweenService = game:GetService("TweenService")
local partCacheModule = require(script.PartCache)
--------------------
Crater.Settings = {
	useGroundMaterial = true; --Determines whether the crater will use the ground below it as a base for material, color, and transparency.
	debrisColor = Color3.new(0.6,0.6,0.6); --Color for debris. Only used if useGroundMaterial is set to false.
	debrisMaterial = Enum.Material.Slate; --Material for debris. Only used if useGroundMaterial is set to false.
	timeBeforeRemoval = 7; --The time it takes for craters and debris to disappear.
	doFlyingDebris = true; --Determines whether or not debris will fly out of the crater.
	centerFlyingDebris = false; --Determines whether or not the debris will come from the center of the crater or all around the crater's radius.
	hasDust = true; --Toggles dust emissions on crater creation.
	rockSkipInterval = 7; --Inversely proportional to the number of rocks which will be skipped when making the crater. Creates a sort of "jagged" effect on your craters. Set to 0 to disable.
	debrisFolder = game.Workspace.Debris; --Recommended to create a folder named "Debris" or something of the like for this. This folder will house all of your PartCache instances and debris.
	FilterDescendantsInstances = { --Used for raycasting. Add anything which you would not like to be recognized as ground.
		game.Workspace.Debris;
	}
}
table.insert(Crater.Settings.FilterDescendantsInstances,Crater.Settings.debrisFolder)
--------------------
--[[
	Use example:
	This module should only be used on the client.
	----------------
	local Crater = require(game:GetService("ReplicatedStorage").Crater)
	local chr = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
	
	while wait(5) do
		Crater.formCrater({
			Position = chr.HumanoidRootPart.Position;
			Radius = 10;
			rockSize = 2.5;
		})
	end
	
	game.ReplicatedStorage.RemoteEvent.OnClientEvent:Connect(function()
		Crater:UpdateSettings({
			useGroundMaterial = false; 
			debrisColor = Color3.fromRGB(86, 66, 54); 
			debrisMaterial = Enum.Material.Slate;
			timeBeforeRemoval = 10; 
			doFlyingDebris = false; 
			centerFlyingDebris = false; 
			hasDust = false; 
			rockSkipInterval = 0; 
			debrisFolder = game.Workspace.Temp; 
			FilterDescendantsInstances = { 
				Crater.Settings.debrisFolder;
				game.Players.LocalPlayer.Character;
				game.Workspace.filteredFolder1;
				game.Workspace.filteredFolder2;
			}
		})
	end)
]]

--------------------
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {workspace.World.Map}
local partCache = partCacheModule.new(Instance.new("Part"), 1000, Crater.Settings.debrisFolder)
--------------------
function Crater.formCrater(craterProperties)
	local self = Crater
	local random = Random.new()
	local radius: number = craterProperties.Radius
	local Position: Vector3 = craterProperties.Position
	local rockSize: Vector3 = Vector3.new(craterProperties.rockSize,craterProperties.rockSize,craterProperties.rockSize)
	local Material
	local Transparency 
	local Color
	local raycast = workspace:Raycast(Position,Vector3.new(0,-25,0),params)
	if raycast and raycast.Instance then
		Position = raycast.Position + Vector3.new(0,1,0)
	end
	if self.Settings.hasDust == true then
		local dust = script.VFX.CraterDust:Clone()
		dust.Parent = self.Settings.debrisFolder
		dust.Position = Position
		dust.Size = Vector3.new(radius,2,radius)
		dust.Smoke.Size = NumberSequence.new(radius * 0.5)
		dust.Smoke.Speed = NumberRange.new(radius * 1.5,radius * 3)
		local dustEmitCount = math.floor(radius * 1.5) + math.floor(craterProperties.rockSize * 1.5)
		if dustEmitCount > 75 then
			dustEmitCount = 75
		end
		dust.Smoke:Emit(dustEmitCount)
		game.Debris:AddItem(dust,10)
		if raycast and raycast.Instance then
			dust.Smoke.Color = ColorSequence.new(raycast.Instance.Color)
		end
	end
	local parts = 0
	for i = 0,radius * 8,craterProperties.rockSize do
		parts += 1
	end
	local function getXAndZPositions(angle)
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		return x, z
	end
	local angle = 30
	local otherAngle = 360/parts
	local noPartInterval = math.random(self.Settings.rockSkipInterval - 1,self.Settings.rockSkipInterval + 1)
	local lastSkipped = 0
	for i = 1, parts do
		local cf = CFrame.new(Position)
		local newCF = cf * CFrame.fromEulerAnglesXYZ(0, math.rad(angle), 0) * CFrame.new(radius/2 + radius/15, 10, 0)
		local ray = game.Workspace:Raycast(newCF.Position, Vector3.new(0, -15, 0), params)
		angle += otherAngle
		--chance to not make rocks
		if i - lastSkipped < 3 then continue end
		if i % noPartInterval == 0 and self.Settings.rockSkipInterval > 0 then
			lastSkipped = i
			noPartInterval = math.random(6,8)
			continue;
		end
		if ray then
			local part = partCache:GetPart()
			part.CFrame = CFrame.new(ray.Position - Vector3.new(0, (rockSize.Y * 0.4) + rockSize.Y * 1.5, 0), Position) * CFrame.fromEulerAnglesXYZ(random:NextNumber(-1,-0.3),random:NextNumber(-0.15,0.15),random:NextNumber(-.15,.15))
			part.Size = Vector3.new(rockSize.X * math.random(1150,1500) / 1000, rockSize.Y * math.random(600,900) / 1000, rockSize.Z * math.random(1150,1500) / 1000) * random:NextNumber(1, 1.5)
			TweenService:Create(part,TweenInfo.new(math.random(50,150) / 1000, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{CFrame = CFrame.new(ray.Position - Vector3.new(0, rockSize.Y * math.random(225,525) / 1000, 0), Position) * CFrame.fromEulerAnglesXYZ(random:NextNumber(-1,-0.3),random:NextNumber(-0.15,0.15),random:NextNumber(-.15,.15))}):Play()
			part.Parent = self.Settings.debrisFolder
			if self.Settings.useGroundMaterial == true and ray.Instance ~= nil then
				part.Material = ray.Instance.Material;
				part.Transparency = ray.Instance.Transparency;
				part.Color = ray.Instance.Color;
				if ray.Instance.Material == Enum.Material.Grass then
					part.Color = Color3.fromRGB(86, 66, 54)
					part.Material = Enum.Material.Slate
				end
			elseif self.Settings.useGroundMaterial == false then
				part.Material = self.Settings.debrisMaterial;
				part.Color = self.Settings.debrisColor;
				part.Transparency = 0;
			elseif ray.Instance == nil then
				continue;
			end
			Material = ray.Instance.Material
			Color = ray.Instance.Color
			Transparency = ray.Instance.Transparency
			
			part.Anchored = true
			part.CanTouch = true
			part.CanCollide = true
			
			task.delay(self.Settings.timeBeforeRemoval + math.random(-600,600) / 1000, function()
				TweenService:Create(part,TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),{Transparency = 1; CFrame = part.CFrame * CFrame.new(0,-craterProperties.rockSize * 2,0)}):Play()
				task.delay(0.75, function()
					partCache:ReturnPart(part)
				end)
			end)
		end
	end
	local numOfRocks = math.round(radius / 5)
	if numOfRocks > 8 then
		numOfRocks = 8
	end
	if self.Settings.doFlyingDebris == true then
		for i = 0,numOfRocks do
			local part = partCache:GetPart()
			part.Transparency = 0
			part.CanCollide = true
			part.Anchored = false;
			part.CollisionGroup = "rocks"
			part.Size = Vector3.new(0,0,0)
			part.Massless = true
			part.Name = "Debris"
			TweenService:Create(part,TweenInfo.new(0.2),{Size = Vector3.new(math.random(100,craterProperties.rockSize * 100) / 100,math.random(100,craterProperties.rockSize * 100) / 100,math.random(100,craterProperties.rockSize * 100) / 100)}):Play()
			if self.Settings.centerFlyingDebris == true then
				part.Position = Position
			else
				part.Position = Position + Vector3.new(math.random(-radius,radius),rockSize,math.random(-radius,radius))
			end
			local raycast = workspace:Raycast(part.Position + Vector3.new(0,7.5,0),Vector3.new(0,-15,0),params)
			if raycast == nil then partCache:ReturnPart(part) continue end
			if self.Settings.useGroundMaterial == true and raycast.Instance ~= nil then
				part.Material = raycast.Instance.Material
				part.Transparency = raycast.Instance.Transparency
				part.Color = raycast.Instance.Color
				if raycast.Instance.Material == Enum.Material.Grass then
					part.Color = Color3.fromRGB(86, 66, 54)
					part.Material = Enum.Material.Slate
				end
			elseif self.Settings.useGroundMaterial == false then
				part.Material = self.Settings.debrisMaterial
				part.Transparency = 0
				part.Color = self.Settings.debrisColor
			elseif raycast.Instance == nil then
				partCache:ReturnPart(part)
				return;
			end
			local v = Instance.new("BodyVelocity")
			v.Parent = part
			v.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
			v.Velocity = Vector3.new(math.random(-craterProperties.rockSize * 10,craterProperties.rockSize * 10),math.random(craterProperties.rockSize * 5,craterProperties.rockSize * 10),math.random(-craterProperties.rockSize * 10,craterProperties.rockSize * 10))
			game.Debris:AddItem(v,0.2)
			part.AssemblyAngularVelocity = Vector3.new(math.random(-45,45),math.random(-45,45),math.random(-45,45))
			task.spawn(function()
				task.wait(self.Settings.timeBeforeRemoval)
				TweenService:Create(part,TweenInfo.new(0.5,Enum.EasingStyle.Cubic),{Size = Vector3.new(0,0,0)}):Play()
				task.delay(1,function()
					partCache:ReturnPart(part)
				end)
			end)
		end
	end
	return
end

function Crater:UpdateSettings(settingsTable)
	if settingsTable.useGroundMaterial ~= nil then
		self.Settings.useGroundMaterial = settingsTable.useGroundMaterial
	end
	if settingsTable.debrisColor ~= nil then
		self.Settings.debrisColor = settingsTable.debrisColor
	end
	if settingsTable.debrisMaterial ~= nil then
		self.Settings.debrisMaterial = settingsTable.debrisMaterial
	end
	if settingsTable.timeBeforeRemoval ~= nil then
		self.Settings.timeBeforeRemoval = settingsTable.timeBeforeRemoval
	end
	if settingsTable.doFlyingDebris ~= nil then
		self.Settings.doFlyingDebris = settingsTable.doFlyingDebris
	end
	if settingsTable.centerFlyingDebris ~= nil then
		self.Settings.centerFlyingDebris = settingsTable.centerFlyingDebris
	end
	if settingsTable.hasDust ~= nil then
		self.Settings.hasDust = settingsTable.hasDust
	end
	if settingsTable.rockSkipInterval ~= nil then
		self.Settings.rockSkipInterval = settingsTable.rockSkipInterval
	end
	if settingsTable.debrisFolder ~= nil then
		self.Settings.debrisFolder = settingsTable.debrisFolder
		partCacheModule:SetCacheParent(settingsTable.debrisFolder)
	end
end

return Crater