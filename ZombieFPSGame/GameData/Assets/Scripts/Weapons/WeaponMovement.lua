local WeaponMovement = {}

-- Expose properties to the editor by adding them to this table. For Example:
-- WeaponMovement.MyExampleVar = 10

WeaponMovement.SwayPosStep = 0.01
WeaponMovement.SwayPosAmount = 0.05
WeaponMovement.SwayRotStep = 3
WeaponMovement.SwayRotAmount = 5
WeaponMovement.SwayPosSmoothness = 5.0
WeaponMovement.SwayRotSmoothness = 5.0

WeaponMovement.BobSpeed = 0.05

function WeaponMovement:OnCreate(entity)

end

function WeaponMovement:OnUpdate(entity, delta)
    local transform = entity:GetComponent("TransformComponent")
    local mouseDelta = Input.GetMouseDelta()

    -- Weapon Sway
    self:Sway(transform, mouseDelta, delta)

    -- Weapon Bob
    self:Bob(transform, delta)
end

function WeaponMovement:Sway(transform, mouseDelta, delta)
    local invertedMouseDelta = Vector3f.new(-mouseDelta.x, -mouseDelta.y, 0) * -self.SwayPosStep;
    invertedMouseDelta.y = Math.Clamp(invertedMouseDelta.y, -self.SwayPosAmount, self.SwayPosAmount)
    invertedMouseDelta.x = Math.Clamp(invertedMouseDelta.x, -self.SwayPosAmount, self.SwayPosAmount)
    local swayPos = invertedMouseDelta

    -- Then add sway based on mouse movement (lerp towards target sway based on mouse delta)
    transform.Position = Math.Lerp(transform.Position, swayPos, self.SwayPosSmoothness * delta)

    local invertedMouseDeltaRot = Vector3f.new(-mouseDelta.x, -mouseDelta.y, 0) * -self.SwayRotStep;
    invertedMouseDeltaRot.y = Math.Clamp(invertedMouseDeltaRot.y, Math.Radians(-self.SwayRotAmount), Math.Radians(self.SwayRotAmount))
    invertedMouseDeltaRot.x = Math.Clamp(invertedMouseDeltaRot.x, Math.Radians(-self.SwayRotAmount), Math.Radians(self.SwayRotAmount))
    local swayRot = Vector3f.new(invertedMouseDeltaRot.y, invertedMouseDeltaRot.x, invertedMouseDeltaRot.x)

    -- Then add sway based on mouse movement (lerp towards target sway based on mouse delta)
    local rotQuaternion = Math.ToQuaternion(swayRot)
    local currentRotQuaternion = Math.ToQuaternion(transform.Rotation)
    local targetRotQuaternion = Math.Slerp(currentRotQuaternion, rotQuaternion, self.SwayRotSmoothness * delta)
    transform.Rotation = Math.ToEulerAngles(targetRotQuaternion)
end

function WeaponMovement:Bob(transform, delta)
    local playerController = Scene.GetEntityByName("Player"):GetComponent("CharacterControllerComponent")
    -- Bob Position offset


    -- bob rotation offset
end

return WeaponMovement