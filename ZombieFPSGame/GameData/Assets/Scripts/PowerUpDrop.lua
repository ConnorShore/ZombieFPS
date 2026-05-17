local PowerUpDrop = {}

PowerUpDrop.MoveSpeed = 3.0
PowerUpDrop.MoveDistance = 0.2

PowerUpDrop.PickupType = {
    Ammo = 1,
    Health = 2,
    Points = 3
}

function PowerUpDrop:OnCreate(entity)
    self.TimeSinceStart = 0.0
    
    -- Start point for the bobbing motion
    local transform = entity:GetComponent("TransformComponent")
    self.StartY = transform.Position.y
end

function PowerUpDrop:OnUpdate(entity, delta)
    self.TimeSinceStart = self.TimeSinceStart + delta

    local transform = entity:GetComponent("TransformComponent")
    transform.Position.y = self.StartY + (self.MoveDistance * math.sin(self.TimeSinceStart * self.MoveSpeed))
end

function PowerUpDrop:OnPickup(entity, otherEntity)

    if self.PickupType == PowerUpDrop.PickupType.Ammo then
        Log.Info("Picked up ammo!")
    elseif self.PickupType == PowerUpDrop.PickupType.Health then
        Log.Info("Picked up health!")
    elseif self.PickupType == PowerUpDrop.PickupType.Points then
        Log.Info("Picked up points!")
    end

    Scene.RemoveEntity(entity)
end


return PowerUpDrop