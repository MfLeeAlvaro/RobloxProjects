local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Create RemoteEvent for combat
local combatRemote = ReplicatedStorage:FindFirstChild("SimpleCombatRemote")
if not combatRemote then
	combatRemote = Instance.new("RemoteEvent")
	combatRemote.Name = "SimpleCombatRemote"
	combatRemote.Parent = ReplicatedStorage
end

-- Combat settings
local isAttacking = false
local comboCount = 0
local comboResetTime = 1
local lastAttackTime = 0

-- Attack on left click
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Left mouse button
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isAttacking then return end

		-- Reset combo if too much time passed
		if tick() - lastAttackTime > comboResetTime then
			comboCount = 0
		end

		isAttacking = true

		-- Cycle combo (1, 2, 3, then back to 1)
		comboCount = (comboCount % 3) + 1
		lastAttackTime = tick()

		-- Play attack animation
		if _G.PlayAttackAnimation then
			_G.PlayAttackAnimation(comboCount)
		end

		-- Tell server to damage enemies
		combatRemote:FireServer(comboCount)

		-- Attack cooldown
		task.wait(0.5)
		isAttacking = false
	end
end)

print("✅ Simple combat loaded")