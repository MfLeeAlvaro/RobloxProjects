local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent

-- Create HUD
local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUDFrame"
hudFrame.Size = UDim2.new(0, 300, 0, 100)
hudFrame.Position = UDim2.new(0, 20, 1, -120)
hudFrame.BackgroundTransparency = 1
hudFrame.Parent = gui

-- Exit Button (optional - can be removed if HUD should always be visible)
local exitButton = Instance.new("TextButton")
exitButton.Size = UDim2.new(0, 25, 0, 25)
exitButton.Position = UDim2.new(1, -30, 0, 5)
exitButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
exitButton.Text = "✕"
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.Font = Enum.Font.GothamBold
exitButton.TextSize = 16
exitButton.Parent = hudFrame

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

-- Close the HUD when exit is clicked
exitButton.MouseButton1Click:Connect(function()
	hudFrame.Visible = false
end)

-- Health Bar Container
local healthContainer = Instance.new("Frame")
healthContainer.Size = UDim2.new(1, 0, 0, 35)
healthContainer.Position = UDim2.new(0, 0, 0, 0)
healthContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
healthContainer.BorderSizePixel = 0
healthContainer.Parent = hudFrame

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 8)
healthCorner.Parent = healthContainer

-- Health Bar
local healthBar = Instance.new("Frame")
healthBar.Size = UDim2.new(1, 0, 1, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
healthBar.BorderSizePixel = 0
healthBar.Parent = healthContainer

local healthBarCorner = Instance.new("UICorner")
healthBarCorner.CornerRadius = UDim.new(0, 8)
healthBarCorner.Parent = healthBar

-- Health Text
local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.BackgroundTransparency = 1
healthText.Text = "100 / 100"
healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
healthText.Font = Enum.Font.GothamBold
healthText.TextSize = 18
healthText.TextStrokeTransparency = 0.5
healthText.Parent = healthContainer

-- Health Icon
local healthIcon = Instance.new("TextLabel")
healthIcon.Size = UDim2.new(0, 30, 1, 0)
healthIcon.Position = UDim2.new(0, 5, 0, 0)
healthIcon.BackgroundTransparency = 1
healthIcon.Text = "❤️"
healthIcon.TextSize = 20
healthIcon.Parent = healthContainer

-- Stamina Bar Container
local staminaContainer = Instance.new("Frame")
staminaContainer.Size = UDim2.new(1, 0, 0, 35)
staminaContainer.Position = UDim2.new(0, 0, 0, 45)
staminaContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
staminaContainer.BorderSizePixel = 0
staminaContainer.Parent = hudFrame

local staminaCorner = Instance.new("UICorner")
staminaCorner.CornerRadius = UDim.new(0, 8)
staminaCorner.Parent = staminaContainer

-- Stamina Bar
local staminaBar = Instance.new("Frame")
staminaBar.Size = UDim2.new(1, 0, 1, 0)
staminaBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
staminaBar.BorderSizePixel = 0
staminaBar.Parent = staminaContainer

local staminaBarCorner = Instance.new("UICorner")
staminaBarCorner.CornerRadius = UDim.new(0, 8)
staminaBarCorner.Parent = staminaBar

-- Stamina Text
local staminaText = Instance.new("TextLabel")
staminaText.Size = UDim2.new(1, 0, 1, 0)
staminaText.BackgroundTransparency = 1
staminaText.Text = "100 / 100"
staminaText.TextColor3 = Color3.fromRGB(255, 255, 255)
staminaText.Font = Enum.Font.GothamBold
staminaText.TextSize = 18
staminaText.TextStrokeTransparency = 0.5
staminaText.Parent = staminaContainer

-- Stamina Icon
local staminaIcon = Instance.new("TextLabel")
staminaIcon.Size = UDim2.new(0, 30, 1, 0)
staminaIcon.Position = UDim2.new(0, 5, 0, 0)
staminaIcon.BackgroundTransparency = 1
staminaIcon.Text = "⚡"
staminaText.TextSize = 20
staminaIcon.Parent = staminaContainer

-- Update HUD
local function updateHUD()
	local health = player:FindFirstChild("Health")
	local maxHealth = player:FindFirstChild("MaxHealth")
	local stamina = player:FindFirstChild("Stamina")
	local maxStamina = player:FindFirstChild("MaxStamina")

	if health and maxHealth then
		local healthPercent = health.Value / maxHealth.Value

		-- Animate health bar
		TweenService:Create(healthBar, TweenInfo.new(0.2), {
			Size = UDim2.new(healthPercent, 0, 1, 0)
		}):Play()

		healthText.Text = math.floor(health.Value) .. " / " .. maxHealth.Value

		-- Change color based on health
		if healthPercent > 0.5 then
			healthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		elseif healthPercent > 0.25 then
			healthBar.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
		else
			healthBar.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
		end
	end

	if stamina and maxStamina then
		local staminaPercent = stamina.Value / maxStamina.Value

		-- Animate stamina bar
		TweenService:Create(staminaBar, TweenInfo.new(0.1), {
			Size = UDim2.new(staminaPercent, 0, 1, 0)
		}):Play()

		staminaText.Text = math.floor(stamina.Value) .. " / " .. maxStamina.Value

		-- Change color when low
		if staminaPercent < 0.2 then
			staminaBar.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
		else
			staminaBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		end
	end
end

-- Listen for stat changes
player.ChildAdded:Connect(function(child)
	if child.Name == "Health" or child.Name == "Stamina" then
		child.Changed:Connect(updateHUD)
	end
end)

-- Update existing stats
for _, stat in pairs(player:GetChildren()) do
	if stat:IsA("IntValue") then
		stat.Changed:Connect(updateHUD)
	end
end

-- Initial update
task.wait(1)
updateHUD()

-- Update loop (backup)
while task.wait(0.1) do
	updateHUD()
end