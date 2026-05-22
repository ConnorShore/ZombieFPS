local PowerUpDrop = {}

PowerUpDrop.MoveSpeed = 3.0
PowerUpDrop.MoveDistance = 0.2
PowerUpDrop.RotationSpeed = 30.0
PowerUpDrop.PickupSound = ""

PowerUpDrop.PickupType = {
    Ammo = 1,
    Health = 2,
    Points = 3
}

PowerUpDrop.Amount = 10

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

    local rotation = transform.Rotation
    rotation.y = rotation.y + (Math.Radians(self.RotationSpeed) * delta)
end

function PowerUpDrop:OnOverlapTriggerEnter(entity, otherEntity)
    if otherEntity:GetName() ~= "Player" then
        return
    end

    if self.PickupType == PowerUpDrop.PickupType.Ammo then
        self:AddAmmo(self.Amount)
    elseif self.PickupType == PowerUpDrop.PickupType.Health then
        self:AddHealth(self.Amount)
    elseif self.PickupType == PowerUpDrop.PickupType.Points then
        self:AddPoints(self.Amount)
    end

    AudioSystem.PlaySound(self.PickupSound)
    Scene.RemoveEntity(entity)
end

function PowerUpDrop:AddAmmo(amount)
    local weaponHolderEntity = Scene.GetEntityByName("WeaponHolder")
    local weaponHolderScript = weaponHolderEntity and weaponHolderEntity:GetScriptInstance()
    if weaponHolderScript and weaponHolderScript.CurrentWeapon ~= "" then
        local weaponEntity = Scene.GetEntityByName(weaponHolderScript.CurrentWeapon)
        local weaponControllerScript = weaponEntity and weaponEntity:GetScriptInstance()
        if weaponControllerScript then
            weaponControllerScript:AddAmmo(amount)
        else
            Log.Warn("Current weapon entity does not have a WeaponController script attached!")
        end
    else
        Log.Warn("No current weapon equipped or WeaponHolder script not found!")
    end
end

function PowerUpDrop:AddPoints(amount)
    Log.Info("Added " .. tostring(amount) .. " points!")
end

function PowerUpDrop:AddHealth(amount)
    Log.Info("Added " .. tostring(amount) .. " health!")
end

return PowerUpDrop