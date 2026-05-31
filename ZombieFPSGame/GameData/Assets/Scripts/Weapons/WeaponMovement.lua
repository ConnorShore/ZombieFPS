local WeaponMovement = {}

WeaponMovement.SwayPosStep = 0.01
WeaponMovement.SwayPosAmount = 0.05
WeaponMovement.SwayRotStep = 3
WeaponMovement.SwayRotAmount = 5

WeaponMovement.BobSpeed = 12.0
WeaponMovement.BobLimit = Vector3f.new(0.05, 0.05, 0.05)    
WeaponMovement.BobTotalLimit = Vector3f.new(0.1, 0.1, 0.1)
WeaponMovement.BobRotMultiplier = Vector3f.new(2, 2, 2)

WeaponMovement.PosSmoothness = 5.0
WeaponMovement.RotSmoothness = 5.0

WeaponMovement.IdleMultiplier = 0.2
WeaponMovement.PlayerRef = EntityRef()

function WeaponMovement:OnCreate(entity)
    self.SwayPos = Vector3f.new(0, 0, 0)
    self.SwayRot = Vector3f.new(0, 0, 0)
    self.BobPos = Vector3f.new(0, 0, 0)
    self.BobRot = Vector3f.new(0, 0, 0)
    
    self.BobTime = 0.0 
    self.Player = Scene.GetEntityByUUID(self.PlayerRef)
end

function WeaponMovement:OnUpdate(entity, delta)
    local transform = entity:GetComponent("TransformComponent")
    local mouseDelta = Input.GetMouseDelta()
    self.BobTime = self.BobTime + delta

    self:Sway(transform, mouseDelta)
    self:Bob(transform, delta)

    -- Apply final sway + bob to weapon transform position
    transform.Position = Math.Lerp(transform.Position, self.SwayPos + self.BobPos, self.PosSmoothness * delta)
    
    local totalRot = self.SwayRot + self.BobRot 
    local rotQuaternion = Math.ToQuaternion(totalRot)
    local currentRotQuaternion = Math.ToQuaternion(transform.Rotation)
    local targetRotQuaternion = Math.Slerp(currentRotQuaternion, rotQuaternion, self.RotSmoothness * delta)
    
    transform.Rotation = Math.ToEulerAngles(targetRotQuaternion)
end

function WeaponMovement:Sway(transform, mouseDelta)
    local invertedMouseDelta = Vector3f.new(-mouseDelta.x, -mouseDelta.y, 0) * -self.SwayPosStep;
    invertedMouseDelta.y = Math.Clamp(invertedMouseDelta.y, -self.SwayPosAmount, self.SwayPosAmount)
    invertedMouseDelta.x = Math.Clamp(invertedMouseDelta.x, -self.SwayPosAmount, self.SwayPosAmount)
    self.SwayPos = invertedMouseDelta

    local invertedMouseDeltaRot = Vector3f.new(-mouseDelta.x, -mouseDelta.y, 0) * -self.SwayRotStep;
    invertedMouseDeltaRot.y = Math.Clamp(invertedMouseDeltaRot.y, Math.Radians(-self.SwayRotAmount), Math.Radians(self.SwayRotAmount))
    invertedMouseDeltaRot.x = Math.Clamp(invertedMouseDeltaRot.x, Math.Radians(-self.SwayRotAmount), Math.Radians(self.SwayRotAmount))
    self.SwayRot = Vector3f.new(invertedMouseDeltaRot.y, invertedMouseDeltaRot.x, invertedMouseDeltaRot.x)
end

function WeaponMovement:Bob(transform, delta)
    if not self.Player:IsValid() then
        return
    end

    local playerController = self.Player:GetComponent("CharacterControllerComponent")
    local playerVelocity = playerController.MovementVelocity
    local requestedMovement = playerController.RequestedMovement
    local hasRequestedMovement = Math.Length(requestedMovement) > 0.0

    -- Advance the clock if we are moving
    if playerController.IsGrounded and Math.Length(playerVelocity) > 0.0 then
        self.BobTime = self.BobTime + (self.BobSpeed * delta)
    end

    -- Position Bob Math
    local bobPos = Vector3f.new(0, 0, 0)
    bobPos.x = (Math.Cos(self.BobTime) * self.BobLimit.x * (playerController.IsGrounded and 1 or 0)) - (requestedMovement.x * self.BobLimit.x)
    bobPos.y = (Math.Sin(self.BobTime * 2.0) * self.BobLimit.y) - (playerVelocity.y * self.BobLimit.y) -- Uses Sin * 2 (Up/Down twice per stride)
    bobPos.z = -(requestedMovement.z * self.BobLimit.z)

    bobPos.x = Math.Clamp(bobPos.x, -self.BobTotalLimit.x, self.BobTotalLimit.x)
    bobPos.y = Math.Clamp(bobPos.y, -self.BobTotalLimit.y, self.BobTotalLimit.y)
    bobPos.z = Math.Clamp(bobPos.z, -self.BobTotalLimit.z, self.BobTotalLimit.z)

    -- Scale bobbing down when idle
    if not hasRequestedMovement then
        bobPos = bobPos * self.IdleMultiplier
    end
    
    self.BobPos = bobPos

    local bobRot = Vector3f.new(0, 0, 0)
    if hasRequestedMovement then
        bobRot.x = Math.Radians(self.BobRotMultiplier.x * Math.Sin(self.BobTime * 2.0))
        bobRot.y = Math.Radians(self.BobRotMultiplier.y * Math.Cos(self.BobTime))
        bobRot.z = Math.Radians(self.BobRotMultiplier.z * Math.Cos(self.BobTime * 2.0) * requestedMovement.x)
    end
    
    self.BobRot = bobRot
end

return WeaponMovement