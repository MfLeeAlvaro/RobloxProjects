local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local zoneLabel = script.Parent:WaitForChild("ZoneLabel")
local zonesFolder = workspace:WaitForChild("Zones")

-- Zone colors and display names
local zoneInfo = {
	GreenZone = {
		displayName = "🟢 Green Zone - Safe",
		color = Color3.fromRGB(0, 255, 0)
	},
	YellowZone = {
		displayName = "🟡 Yellow Zone - Caution",
		color = Color3.fromRGB(255, 255, 0)
	},
	RedZone = {
		displayName = "🔴 Red Zone - Danger",
		color = Color3.fromRGB(255, 0, 0)
	},
	BlackZone = {
		displayName = "⚫ Black Zone - EXTREME DANGER",
		color = Color3.fromRGB(150, 0, 0)
	}
}

local currentZone = nil

-- Function to check which zone player is in
local function checkZone()
	local playerPos = humanoidRootPart.Position
	local inZone = false

	for _, zonePart in pairs(zonesFolder:GetChildren()) do
		if zonePart:IsA("BasePart") then
			-- Check if player is inside this zone's bounds
			local zonePos = zonePart.Position
			local zoneSize = zonePart.Size

			local isInside = math.abs(playerPos.X - zonePos.X) <= zoneSize.X / 2
				and math.abs(playerPos.Y - zonePos.Y) <= zoneSize.Y / 2
				and math.abs(playerPos.Z - zonePos.Z) <= zoneSize.Z / 2

			if isInside then
				local info = zoneInfo[zonePart.Name]

				if info and currentZone ~= zonePart.Name then
					currentZone = zonePart.Name
					zoneLabel.Text = info.displayName
					zoneLabel.TextColor3 = info.color
					zoneLabel.Visible = true
					inZone = true
					break
				elseif info then
					inZone = true
					break
				end
			end
		end
	end

	-- Not in any zone
	if not inZone and currentZone ~= nil then
		currentZone = nil
		zoneLabel.Text = "No Zone"
		zoneLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		zoneLabel.Visible = true
	end
end

-- Check zone every 0.5 seconds
RunService.Heartbeat:Connect(function()
	if tick() % 0.5 < 0.016 then -- Roughly every 0.5 seconds
		checkZone()
	end
end)

-- Update when character respawns
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	currentZone = nil
end)