local PickupItem = {}

PickupItem.MoveSpeed = 3.0
PickupItem.MoveDistance = 0.2

PickupItem.PickupType = {
    Ammo = 1,
    Health = 2,
    Points = 3
}

function PickupItem:OnCreate(entity)
    self.TimeSinceStart = 0.0
    
    -- Start point for the bobbing motion
    local transform = entity:GetComponent("TransformComponent")
    self.StartY = transform.Position.y
end

function PickupItem:OnUpdate(entity, delta)
    self.TimeSinceStart = self.TimeSinceStart + delta

    local transform = entity:GetComponent("TransformComponent")
    transform.Position.y = self.StartY + (self.MoveDistance * math.sin(self.TimeSinceStart * self.MoveSpeed))
end

function PickupItem:OnPickup(entity, otherEntity)

    if self.PickupType == PickupItem.PickupType.Ammo then
        Log.Info("Picked up ammo!")
    elseif self.PickupType == PickupItem.PickupType.Health then
        Log.Info("Picked up health!")
    elseif self.PickupType == PickupItem.PickupType.Points then
        Log.Info("Picked up points!")
    end

    Scene.RemoveEntity(entity)
end


return PickupItem