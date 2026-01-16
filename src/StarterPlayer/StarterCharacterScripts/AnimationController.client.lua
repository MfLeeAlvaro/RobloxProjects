local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Animation IDs (Replace these with your own!)
local ANIMATIONS = {
	Idle = "rbxassetid://507766388", -- Default idle
	Walk = "rbxassetid://507777826", -- Default walk
	Run = "rbxassetid://507767714", -- Default run
	Jump = "rbxassetid://507765000", -- Default jump
	Fall = "rbxassetid://507767968", -- Default fall
	Attack1 = "rbxassetid://0", -- Replace with your attack animation
	Attack2 = "rbxassetid://0", -- Optional combo attack
	Attack3 = "rbxassetid://0", -- Optional combo attack
}

-- Load animations
local loadedAnimations = {}

local function loadAnimation(name, animId)
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	local animTrack = humanoid:LoadAnimation(anim)
	loadedAnimations[name] = animTrack
	return animTrack
end

-- Load all animations
for name, id in pairs(ANIMATIONS) do
	if id ~= "rbxassetid://0" then
		loadAnimation(name, id)
	end
end

-- Track current state
local currentAnim = nil
local isAttacking = false

-- Play animation
local function playAnimation(name, loop)
	if not loadedAnimations[name] then return end

	-- Stop current animation
	if currentAnim and currentAnim ~= loadedAnimations[name] then
		currentAnim:Stop(0.2)
	end

	-- Play new animation
	currentAnim = loadedAnimations[name]
	currentAnim.Looped = loop or false
	currentAnim:Play(0.2)

	return currentAnim
end

-- Handle movement animations
local function updateMovementAnimation()
	if isAttacking then return end -- Don't interrupt attacks

	-- Check humanoid state
	if humanoid.FloorMaterial == Enum.Material.Air then
		-- In air
		if humanoid.MoveDirection.Magnitude > 0 then
			playAnimation("Jump", false)
		else
			playAnimation("Fall", false)
		end
	elseif humanoid.MoveDirection.Magnitude > 0 then
		-- Moving
		if humanoid.WalkSpeed > 20 then
			playAnimation("Run", true)
		else
			playAnimation("Walk", true)
		end
	else
		-- Idle
		playAnimation("Idle", true)
	end
end

-- Update animations every frame
game:GetService("RunService").RenderStepped:Connect(function()
	updateMovementAnimation()
end)

-- Handle attacks (will be used by combat system later)
local function performAttack(attackNumber)
	if isAttacking then return end

	isAttacking = true

	local attackName = "Attack" .. (attackNumber or 1)
	local attackAnim = playAnimation(attackName, false)

	if attackAnim then
		-- Wait for animation to finish
		attackAnim.Stopped:Wait()
	else
		-- No attack animation, just wait
		task.wait(0.5)
	end

	isAttacking = false
end

-- Expose attack function globally for combat system
_G.PlayAttackAnimation = performAttack

