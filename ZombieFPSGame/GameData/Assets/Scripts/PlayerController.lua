local PlayerController = {}

PlayerController.ActiveWeaponEntity = ""

function PlayerController:OnCreate(entity)
    self.ActiveWeapon = nil
    self:EquipGun(self.ActiveWeaponEntity)
end

function PlayerController:OnUpdate(entity, delta)

end

function PlayerController:EquipGun(gunEntity)
    self.ActiveWeaponEntity = gunEntity
    
    if self.ActiveWeaponEntity == "" then
        self.ActiveWeapon = nil
        Log.Warn("Player is now unarmed.")
        return
    end

    self.ActiveWeapon = Scene.GetEntityByName(self.ActiveWeaponEntity)
    Log.Info("Player equipped weapon: " .. self.ActiveWeapon:GetName())
end

return PlayerController