local UEHelpers = require("UEHelpers")

print("[SimpleMod][MM] Loaded!\n")

local fly = false
local noclip = false

local verticalSpeed = 0

local flySpeed = 2000
local flyVerticalSpeed = 2000

local hyperDashForce = 10000
local hyperJumpForce = 2000

local planeVelocity = {X = 0, Y = 0}
local planeVelocitySlowdown = 0.5

local function isNumber(num)
    return (tonumber(tostring(num)) ~= nil)
end

local _lastFoundPlayer = nil

local function getPlayer()
    if (_lastFoundPlayer) then return _lastFoundPlayer end

    local player = FindFirstOf("Character")

    if (not isNumber(player.BaseTranslationOffset.X)) then return end
    if (not player:IsValid()) then return end

    _lastFoundPlayer = player

    return player
end

local _lastPlayerMovement = nil

local function getPlayerMovement()
    if (_lastPlayerMovement) then return _lastPlayerMovement end

    local player = getPlayer()
    if (not player) then return end

    local movement = player.CharacterMovement

    if (not movement) then return end

    _lastPlayerMovement = movement

    return movement
end

local _oldBrakingDecelerationFlying = 0
local _oldMaxAcceleration = 0
local _oldMaxFlySpeed = 0
local _oldGravity = 0

local function toggleFly()
    if (fly) then
        print("[SimpleMod][MM] Fly enabled\n")

        local movement = getPlayerMovement()

        if (not movement) then return end

        _oldBrakingDecelerationFlying = movement.BrakingDecelerationFlying
        _oldMaxAcceleration = movement.MaxAcceleration
        _oldMaxFlySpeed = movement.MaxFlySpeed
        _oldGravity = movement.GravityScale

        movement:SetMovementMode(5, 0)
        movement.bCheatFlying = true
        movement.MaxFlySpeed = flySpeed
        movement.BrakingDecelerationFlying = flySpeed * 10
        movement.MaxAcceleration = flySpeed * 10
        movement.GravityScale = 0.0
    else
        print("[SimpleMod][MM] Fly disabled\n")

        verticalSpeed = 0

        planeVelocity = {X = 0, Y = 0}

        local movement = getPlayerMovement()

        if (not movement) then return end

        movement:SetMovementMode(1, 0)
        movement.bCheatFlying = false
        movement.MaxFlySpeed = _oldMaxFlySpeed
        movement.BrakingDecelerationFlying = _oldBrakingDecelerationFlying
        movement.MaxAcceleration = _oldMaxAcceleration
        movement.GravityScale = _oldGravity
    end
end

local function toggleNoclip()
    local player = getPlayer()

    if (noclip) then
        print("[SimpleMod][MM] Noclip enabled\n")

        player:SetActorEnableCollision(false)
    else
        print("[SimpleMod][MM] Noclip disabled\n")

        player:SetActorEnableCollision(true)
    end
end

local function getVectorAngle(vec)
    return math.atan(vec.Y, vec.X)
end

local function rotateVector(vec, angle)
    local cos = math.cos(angle)
    local sin = math.sin(angle)

    return {
        X = ((vec.X * cos) - (vec.Y * sin)),
        Y = ((vec.X * sin) + (vec.Y * cos)),
        Z = 0
    }
end

local function alignVector(mainVector, directionVector)
    return rotateVector(mainVector, getVectorAngle(directionVector))
end

local function addPlaneVector(vec1, vec2)
    return {X = vec1.X + vec2.X, Y = vec1.Y + vec2.Y}
end

local function keyDown(key)
    if (key == "C") then
        fly = not fly

        toggleFly()
    elseif (key == "V") then
        noclip = not noclip

        toggleNoclip()
    elseif (key == "B") then
        local walls = FindAllOf("SupraEABlockingVolume_C")

        if (not walls) then return end

        if (#walls > 0) then
            for _, wall in ipairs(walls) do
                if (wall) then
                    if (wall:IsValid()) then
                        wall:K2_DestroyActor()
                    end
                end
            end
            
            print("[SimpleMod][MM] Removed all early access walls\n")
        end
    elseif (key == "Left Alt") then
        if (fly) then
            local fpc = UEHelpers:GetPlayerController()
            local pawn = fpc.Pawn

            if (not pawn:IsValid()) then return end

            local rotation = pawn:K2_GetActorRotation()

            if (not rotation) then return end

            local result = rotateVector({X = hyperDashForce, Y = 0, Z = 0}, (rotation.Yaw * (math.pi / 180)))

            planeVelocity = addPlaneVector(planeVelocity, {X = result.X, Y = result.Y})
        else
            local movement = getPlayerMovement()

            if (not movement) then return end

            movement.Velocity = {X = movement.Velocity.X, Y = movement.Velocity.Y, Z = math.max(0, movement.Velocity.Z)}

            movement:AddImpulse({X = 0, Y = 0, Z = hyperJumpForce}, true)
        end
    elseif (key == "Space Bar") then
        verticalSpeed = verticalSpeed + 1
    elseif (key == "Left Ctrl") then
        verticalSpeed = verticalSpeed - 1
    end
end

local function keyUp(key)
    if (key == "Space Bar") then
        verticalSpeed = verticalSpeed - 1
    elseif (key == "Left Ctrl") then
        verticalSpeed = verticalSpeed + 1
    end
end

local function addVectors(v1, v2)
    return {X = v1.X + v2.X, Y = v1.Y + v2.Y, Z = v1.Z + v2.Z}
end

local function tick(dt)
    if (not fly) then return end

    local fpc = UEHelpers:GetPlayerController()
    local pawn = fpc.Pawn

    if (not pawn:IsValid()) then return end

    local position = pawn:K2_GetActorLocation()
    local rotation = pawn:K2_GetActorRotation()

    pawn:K2_TeleportTo(addVectors(position, {X = planeVelocity.X * dt, Y = planeVelocity.Y * dt, Z = dt * verticalSpeed * flyVerticalSpeed}), rotation)

    planeVelocity = {X = planeVelocity.X - (planeVelocity.X / planeVelocitySlowdown * dt), Y = planeVelocity.Y - (planeVelocity.Y / planeVelocitySlowdown * dt)}

    local movement = getPlayerMovement()

    if (not movement) then return end

    movement.Velocity = {X = movement.Velocity.X, Y = movement.Velocity.Y, Z = 0}

    if (not fly) then return end

    if (movement.MovementMode ~= 5) then
        movement:SetMovementMode(5, 0)
    end
end

RegisterCustomEvent("keyDown", function(_, key, ...)
    key = key:get():ToString()

    keyDown(key)
end)

RegisterCustomEvent("keyUp", function(_, key, ...)
    key = key:get():ToString()

    keyUp(key)
end)

RegisterCustomEvent("tick", function(_, dt, ...)
    dt = dt:get()
    if (not isNumber(dt)) then return end

    tick(dt)
end)
