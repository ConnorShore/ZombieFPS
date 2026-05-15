local ADS = {}

-- Expose properties to the editor by adding them to this table. For Example:
-- ADS.MyExampleVar = 10

ADS.Speed = 5.0

function ADS:OnCreate(entity)
    self.IsAiming = false
    self.StartPosition = entity:GetComponent("TransformComponent").Position
end

function ADS:OnUpdate(entity, delta)

    if Input.IsMouseButtonPressed(MouseButton.Right) then
        self.IsAiming = true
        self:TransitionToADS(entity, delta)
    else
        self.IsAiming = false
        self:TransitionToHipFire(entity, delta)
    end
end

function ADS:TransitionToADS(entity, delta)
    if not self.IsAiming then
        return
    end

    local transform = entity:GetComponent("TransformComponent")
    local camera = Scene.GetEntityByName("Camera")
    local cameraTransform = camera:GetComponent("TransformComponent")
    local targetPosition = cameraTransform.Position + cameraTransform:GetForward() * 0.5 - cameraTransform:GetRight() * 0.2 - cameraTransform:GetUp() * 0.1

    transform.Position = Vector3f.Lerp(transform.Position, targetPosition, delta * self.Speed)
end

function ADS:TransitionToHipFire(entity, delta)
    if self.IsAiming then
        return
    end

    local transform = entity:GetComponent("TransformComponent")
    transform.Position = Vector3f.Lerp(transform.Position, self.StartPosition, delta * self.Speed)
end

return ADS