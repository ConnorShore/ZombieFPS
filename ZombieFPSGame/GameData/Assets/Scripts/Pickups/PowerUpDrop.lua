local PowerUpDrop = {}

PowerUpDrop.MoveSpeed = 3.0
PowerUpDrop.MoveDistance = 0.2
PowerUpDrop.RotationSpeed = 30.0
PowerUpDrop.PickupSound = AudioClipRef()
PowerUpDrop.WeaponHolderRef = EntityRef()

PowerUpDrop.PickupType = {
    Ammo = 1,
    Nuke = 2
}

function PowerUpDrop:OnCreate(entity)
    self.TimeSinceStart = 0.0
    self.WeaponHolder = Scene.GetEntityByUUID(self.WeaponHolderRef)

    -- Component handles are safe to cache for the entity's lifetime (they re-resolve the
    -- live component internally), so fetch it once here instead of every frame in OnUpdate.
    self.transform = entity:GetComponent("TransformComponent")

    -- Start point for the bobbing motion
    self.StartY = self.transform.Position.y
end

function PowerUpDrop:OnUpdate(entity, delta)
    self.TimeSinceStart = self.TimeSinceStart + delta

    local transform = self.transform
    transform.Position.y = self.StartY + (self.MoveDistance * math.sin(self.TimeSinceStart * self.MoveSpeed))

    local rotation = transform.Rotation
    rotation.y = rotation.y + (Math.Radians(self.RotationSpeed) * delta)
end

function PowerUpDrop:OnOverlapTriggerEnter(entity, otherEntity)
    Log.Info("PowerUpDrop: OnOverlapTriggerEnter called for " .. entity:GetName() .. " with otherEntity: " .. otherEntity:GetName())
    if otherEntity:GetName() ~= "Player" then
        return
    end

    if self.PickupType == PowerUpDrop.PickupType.Ammo then
        EventManager.Broadcast("OnAmmoPickup")
    elseif self.PickupType == PowerUpDrop.PickupType.Nuke then
        Log.Trace("Nuke pickup occurred, broadcasting OnNukePickup event")
        EventManager.Broadcast("OnNukePickup")
    end

    AudioSystem.PlaySound(self.PickupSound)
    Scene.RemoveEntity(entity)
end

return PowerUpDrop