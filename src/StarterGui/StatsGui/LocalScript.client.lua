local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent

local levelUpRemote = ReplicatedStorage:WaitForChild("LevelUpRemote", 10)
local giveXPRemote = ReplicatedStorage:WaitForChild("GiveXPRemote", 10)

if not levelUpRemote or not giveXPRemote then
	warn("XP remotes not found - XP system may not be working")
	return
end

-- Create RemoteEvent for upgrading stats
local upgradeStatRemote = ReplicatedStorage:FindFirstChild("UpgradeStatRemote")
if not upgradeStatRemote then
	upgradeStatRemote = Instance.new("RemoteEvent")
	upgradeStatRemote.Name = "UpgradeStatRemote"
	upgradeStatRemote.Parent = ReplicatedStorage
end

-- Create Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "StatsFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 500)
mainFrame.Position = UDim2.new(1, -420, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 40)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "STATS"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Exit Button
local exitButton = Instance.new("TextButton")
exitButton.Size = UDim2.new(0, 35, 0, 35)
exitButton.Position = UDim2.new(1, -45, 0, 10)
exitButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
exitButton.Text = "✕"
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.Font = Enum.Font.GothamBold
exitButton.TextSize = 20
exitButton.Parent = mainFrame

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 5)
exitCorner.Parent = exitButton

-- Hover effects for exit button
exitButton.MouseEnter:Connect(function()
	exitButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
end)

exitButton.MouseLeave:Connect(function()
	exitButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

-- Close the stats GUI when exit is clicked
exitButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Level Display
local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.new(1, -20, 0, 30)
levelLabel.Position = UDim2.new(0, 10, 0, 50)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "Level: 1"
levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextSize = 20
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.Parent = mainFrame

-- XP Bar Container
local xpBarContainer = Instance.new("Frame")
xpBarContainer.Size = UDim2.new(1, -20, 0, 25)
xpBarContainer.Position = UDim2.new(0, 10, 0, 85)
xpBarContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
xpBarContainer.BorderSizePixel = 0
xpBarContainer.Parent = mainFrame

local xpBarCorner = Instance.new("UICorner")
xpBarCorner.CornerRadius = UDim.new(0, 5)
xpBarCorner.Parent = xpBarContainer

local xpBar = Instance.new("Frame")
xpBar.Size = UDim2.new(0, 0, 1, 0)
xpBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
xpBar.BorderSizePixel = 0
xpBar.Parent = xpBarContainer

local xpBarCorner2 = Instance.new("UICorner")
xpBarCorner2.CornerRadius = UDim.new(0, 5)
xpBarCorner2.Parent = xpBar

local xpText = Instance.new("TextLabel")
xpText.Size = UDim2.new(1, 0, 1, 0)
xpText.BackgroundTransparency = 1
xpText.Text = "0 / 100 XP"
xpText.TextColor3 = Color3.fromRGB(255, 255, 255)
xpText.Font = Enum.Font.GothamBold
xpText.TextSize = 14
xpText.TextStrokeTransparency = 0.5
xpText.Parent = xpBarContainer

-- Points Display
local pointsLabel = Instance.new("TextLabel")
pointsLabel.Size = UDim2.new(1, -20, 0, 30)
pointsLabel.Position = UDim2.new(0, 10, 0, 120)
pointsLabel.BackgroundTransparency = 1
pointsLabel.Text = "Stat Points: 0 | Mastery Points: 0"
pointsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
pointsLabel.Font = Enum.Font.Gotham
pointsLabel.TextSize = 16
pointsLabel.TextXAlignment = Enum.TextXAlignment.Left
pointsLabel.Parent = mainFrame

-- Separator
local separator1 = Instance.new("Frame")
separator1.Size = UDim2.new(1, -20, 0, 2)
separator1.Position = UDim2.new(0, 10, 0, 160)
separator1.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
separator1.BorderSizePixel = 0
separator1.Parent = mainFrame

-- STAT UPGRADES SECTION
local statTitle = Instance.new("TextLabel")
statTitle.Size = UDim2.new(1, -20, 0, 30)
statTitle.Position = UDim2.new(0, 10, 0, 170)
statTitle.BackgroundTransparency = 1
statTitle.Text = "⚔️ STATS"
statTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
statTitle.Font = Enum.Font.GothamBold
statTitle.TextSize = 18
statTitle.TextXAlignment = Enum.TextXAlignment.Left
statTitle.Parent = mainFrame

-- Create stat buttons
local statButtons = {}
local stats = {
	{name = "Strength", description = "+5% Damage", yPos = 205},
	{name = "Vitality", description = "+10 Max Health", yPos = 245},
	{name = "Endurance", description = "+10 Max Stamina", yPos = 285}
}

for _, stat in ipairs(stats) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -60, 0, 35)
	button.Position = UDim2.new(0, 10, 0, stat.yPos)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.Text = ""
	button.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 5)
	btnCorner.Parent = button

	local statLabel = Instance.new("TextLabel")
	statLabel.Size = UDim2.new(0.6, 0, 1, 0)
	statLabel.Position = UDim2.new(0, 10, 0, 0)
	statLabel.BackgroundTransparency = 1
	statLabel.Text = stat.name .. ": 1"
	statLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statLabel.Font = Enum.Font.GothamBold
	statLabel.TextSize = 16
	statLabel.TextXAlignment = Enum.TextXAlignment.Left
	statLabel.Parent = button

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
	descLabel.Position = UDim2.new(0, 10, 0.5, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = stat.description
	descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = button

	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Size = UDim2.new(0, 40, 0, 30)
	upgradeBtn.Position = UDim2.new(1, -45, 0.5, -15)
	upgradeBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	upgradeBtn.Text = "+"
	upgradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	upgradeBtn.Font = Enum.Font.GothamBold
	upgradeBtn.TextSize = 20
	upgradeBtn.Parent = button

	local upgradeCorner = Instance.new("UICorner")
	upgradeCorner.CornerRadius = UDim.new(0, 5)
	upgradeCorner.Parent = upgradeBtn

	upgradeBtn.MouseButton1Click:Connect(function()
		upgradeStatRemote:FireServer("Stat", stat.name)
	end)

	statButtons[stat.name] = {label = statLabel, button = upgradeBtn}
end

-- Separator
local separator2 = Instance.new("Frame")
separator2.Size = UDim2.new(1, -20, 0, 2)
separator2.Position = UDim2.new(0, 10, 0, 330)
separator2.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
separator2.BorderSizePixel = 0
separator2.Parent = mainFrame

-- MASTERY SECTION
local masteryTitle = Instance.new("TextLabel")
masteryTitle.Size = UDim2.new(1, -20, 0, 30)
masteryTitle.Position = UDim2.new(0, 10, 0, 340)
masteryTitle.BackgroundTransparency = 1
masteryTitle.Text = "🎯 MASTERY"
masteryTitle.TextColor3 = Color3.fromRGB(150, 100, 255)
masteryTitle.Font = Enum.Font.GothamBold
masteryTitle.TextSize = 18
masteryTitle.TextXAlignment = Enum.TextXAlignment.Left
masteryTitle.Parent = mainFrame

-- Create mastery buttons
local masteryButtons = {}
local masteries = {
	{name = "CombatMastery", display = "Combat", description = "+3% Combat XP", yPos = 375},
	{name = "MiningMastery", display = "Mining", description = "+3% Mining XP", yPos = 415},
	{name = "SurvivalMastery", display = "Survival", description = "+2% Health Regen", yPos = 455}
}

for _, mastery in ipairs(masteries) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -60, 0, 35)
	button.Position = UDim2.new(0, 10, 0, mastery.yPos)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.Text = ""
	button.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 5)
	btnCorner.Parent = button

	local masteryLabel = Instance.new("TextLabel")
	masteryLabel.Size = UDim2.new(0.6, 0, 1, 0)
	masteryLabel.Position = UDim2.new(0, 10, 0, 0)
	masteryLabel.BackgroundTransparency = 1
	masteryLabel.Text = mastery.display .. ": 1"
	masteryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	masteryLabel.Font = Enum.Font.GothamBold
	masteryLabel.TextSize = 16
	masteryLabel.TextXAlignment = Enum.TextXAlignment.Left
	masteryLabel.Parent = button

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
	descLabel.Position = UDim2.new(0, 10, 0.5, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = mastery.description
	descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = button

	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Size = UDim2.new(0, 40, 0, 30)
	upgradeBtn.Position = UDim2.new(1, -45, 0.5, -15)
	upgradeBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
	upgradeBtn.Text = "+"
	upgradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	upgradeBtn.Font = Enum.Font.GothamBold
	upgradeBtn.TextSize = 20
	upgradeBtn.Parent = button

	local upgradeCorner = Instance.new("UICorner")
	upgradeCorner.CornerRadius = UDim.new(0, 5)
	upgradeCorner.Parent = upgradeBtn

	upgradeBtn.MouseButton1Click:Connect(function()
		upgradeStatRemote:FireServer("Mastery", mastery.name)
	end)

	masteryButtons[mastery.name] = {label = masteryLabel, button = upgradeBtn}
end

-- Update UI
local function updateUI()
	local level = player:FindFirstChild("Level")
	local xp = player:FindFirstChild("XP")
	local xpNeeded = player:FindFirstChild("XPNeeded")
	local statPoints = player:FindFirstChild("StatPoints")
	local masteryPoints = player:FindFirstChild("MasteryPoints")

	if level then
		levelLabel.Text = "Level: " .. level.Value
	end

	if xp and xpNeeded then
		local percent = xp.Value / xpNeeded.Value
		TweenService:Create(xpBar, TweenInfo.new(0.3), {
			Size = UDim2.new(percent, 0, 1, 0)
		}):Play()
		xpText.Text = xp.Value .. " / " .. xpNeeded.Value .. " XP"
	end

	if statPoints and masteryPoints then
		pointsLabel.Text = "Stat Points: " .. statPoints.Value .. " | Mastery Points: " .. masteryPoints.Value
	end

	-- Update stat values
	for name, button in pairs(statButtons) do
		local stat = player:FindFirstChild(name)
		if stat then
			button.label.Text = name .. ": " .. stat.Value
		end
	end

	-- Update mastery values
	for name, button in pairs(masteryButtons) do
		local mastery = player:FindFirstChild(name)
		if mastery then
			local displayName = name:gsub("Mastery", "")
			button.label.Text = displayName .. ": " .. mastery.Value
		end
	end
end

-- Listen for stat changes
for _, child in pairs(player:GetChildren()) do
	if child:IsA("IntValue") then
		child.Changed:Connect(updateUI)
	end
end

player.ChildAdded:Connect(function(child)
	if child:IsA("IntValue") then
		child.Changed:Connect(updateUI)
	end
end)

-- Listen for XP gain
giveXPRemote.OnClientEvent:Connect(function(amount, source)
	-- Show XP gain notification
	local notification = Instance.new("TextLabel")
	notification.Size = UDim2.new(0, 150, 0, 30)
	notification.Position = UDim2.new(0.5, -75, 0.8, 0)
	notification.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	notification.BackgroundTransparency = 0.3
	notification.Text = "+ " .. amount .. " XP"
	notification.TextColor3 = Color3.fromRGB(255, 255, 255)
	notification.Font = Enum.Font.GothamBold
	notification.TextSize = 18
	notification.Parent = gui

	local notiCorner = Instance.new("UICorner")
	notiCorner.CornerRadius = UDim.new(0, 8)
	notiCorner.Parent = notification

	-- Fade out
	task.wait(1)
	TweenService:Create(notification, TweenInfo.new(0.5), {
		BackgroundTransparency = 1,
		TextTransparency = 1,
		Position = UDim2.new(0.5, -75, 0.7, 0)
	}):Play()
	task.wait(0.5)
	notification:Destroy()
end)

-- Listen for level up
levelUpRemote.OnClientEvent:Connect(function(newLevel, statPts, masteryPts)
	-- Big level up notification
	local levelUpFrame = Instance.new("Frame")
	levelUpFrame.Size = UDim2.new(0, 400, 0, 200)
	levelUpFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
	levelUpFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	levelUpFrame.BorderSizePixel = 0
	levelUpFrame.Parent = gui

	local lvlCorner = Instance.new("UICorner")
	lvlCorner.CornerRadius = UDim.new(0, 15)
	lvlCorner.Parent = levelUpFrame

	local lvlText = Instance.new("TextLabel")
	lvlText.Size = UDim2.new(1, 0, 0.5, 0)
	lvlText.BackgroundTransparency = 1
	lvlText.Text = "🎉 LEVEL UP! 🎉"
	lvlText.TextColor3 = Color3.fromRGB(0, 0, 0)
	lvlText.Font = Enum.Font.GothamBold
	lvlText.TextSize = 32
	lvlText.Parent = levelUpFrame

	local lvlNum = Instance.new("TextLabel")
	lvlNum.Size = UDim2.new(1, 0, 0.3, 0)
	lvlNum.Position = UDim2.new(0, 0, 0.5, 0)
	lvlNum.BackgroundTransparency = 1
	lvlNum.Text = "Level " .. newLevel
	lvlNum.TextColor3 = Color3.fromRGB(0, 0, 0)
	lvlNum.Font = Enum.Font.GothamBold
	lvlNum.TextSize = 28
	lvlNum.Parent = levelUpFrame

	local rewardText = Instance.new("TextLabel")
	rewardText.Size = UDim2.new(1, 0, 0.2, 0)
	rewardText.Position = UDim2.new(0, 0, 0.8, 0)
	rewardText.BackgroundTransparency = 1
	rewardText.Text = "+1 Stat Point | +1 Mastery Point"
	rewardText.TextColor3 = Color3.fromRGB(50, 50, 50)
	rewardText.Font = Enum.Font.Gotham
	rewardText.TextSize = 16
	rewardText.Parent = levelUpFrame

	-- Fade out
	task.wait(3)
	TweenService:Create(levelUpFrame, TweenInfo.new(0.5), {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 450, 0, 220)
	}):Play()
	TweenService:Create(lvlText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	TweenService:Create(lvlNum, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	TweenService:Create(rewardText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	task.wait(0.5)
	levelUpFrame:Destroy()
end)

-- Initial update
task.wait(1)
updateUI()
