local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

local staminaRemote = ReplicatedStorage:WaitForChild("StaminaRemote", 10)

if not staminaRemote then
	warn("StaminaRemote not found!")
	return
end

-- Settings
local NORMAL_SPEED = 16
local SPRINT_SPEED = 24
local STAMINA_DRAIN_RATE = 10 -- Per second
local STAMINA_REGEN_RATE = 5 -- Per second
local MIN_STAMINA_TO_SPRINT = 5

local isSprinting = false
local canSprint = true

-- Get player stats
local function getStats()
	return {
		stamina = player:FindFirstChild("Stamina"),
		maxStamina = player:FindFirstChild("MaxStamina")
	}
end

-- Check if player is moving
local function isMoving()
	return humanoid.MoveDirection.Magnitude > 0
end

-- Update sprint state
local function updateSprint(dt)
	local stats = getStats()
	if not stats.stamina or not stats.maxStamina then return end

	local moving = isMoving()
	local inAir = humanoid.FloorMaterial == Enum.Material.Air

	-- Sprinting logic
	if isSprinting and moving and not inAir and stats.stamina.Value >= MIN_STAMINA_TO_SPRINT and canSprint then
		-- SPRINTING - drain stamina
		humanoid.WalkSpeed = SPRINT_SPEED
		local drainAmount = STAMINA_DRAIN_RATE * dt
		staminaRemote:FireServer("Drain", drainAmount)
		if stats.stamina.Value <= 0 then
			canSprint = false
		end
	else
		-- NOT SPRINTING
		humanoid.WalkSpeed = NORMAL_SPEED

		-- Regenerate stamina
		local regenAmount = 0
		if not moving and not inAir then
			-- Standing still - fast regen
			regenAmount = STAMINA_REGEN_RATE * dt
		elseif not inAir then
			-- Walking - slow regen
			regenAmount = STAMINA_REGEN_RATE * 0.3 * dt
		end
		-- In air - no regen
		if regenAmount > 0 then
			staminaRemote:FireServer("Regen", regenAmount)
		end

		-- Can sprint again when stamina is above 20%
		if stats.stamina.Value >= stats.maxStamina.Value * 0.2 then
			canSprint = true
		end
	end
end

-- Handle input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
	end
end)

-- Update loop
RunService.Heartbeat:Connect(function(dt)
	updateSprint(dt)
end)
