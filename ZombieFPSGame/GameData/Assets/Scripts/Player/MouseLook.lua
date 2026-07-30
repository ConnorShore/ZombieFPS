local MouseLook = {}

MouseLook.Sensitivity = 5.0

function MouseLook:OnCreate(entity)
    self.Pitch = 0.0
    self.SensitivityScale = 1000.0

    -- Cache our own transform handle (safe for the entity's lifetime; it re-resolves the
    -- live component internally) so OnUpdate doesn't do a string-keyed lookup every frame.
    self.transform = entity:GetComponent("TransformComponent")
end

function MouseLook:OnUpdate(entity, delta)
    local mouseDelta = Input.GetMouseDelta()

    -- YAW (Looking Left/Right)
    local parentEntity = entity:GetRootParent()
    if parentEntity then
        local parentTransform = parentEntity:GetComponent("TransformComponent")
        parentTransform.Rotation.y = parentTransform.Rotation.y - (mouseDelta.x * (self.Sensitivity / self.SensitivityScale))
    end

    -- PITCH (Looking Up/Down)
    self.Pitch = self.Pitch - (mouseDelta.y * (self.Sensitivity / self.SensitivityScale))
    self.Pitch = Math.Clamp(self.Pitch, Math.Radians(-89.0), Math.Radians(89.0))

    local transform = self.transform
    transform.Rotation.x = self.Pitch
end

return MouseLook