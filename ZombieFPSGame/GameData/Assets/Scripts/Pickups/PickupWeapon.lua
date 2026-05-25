local PickupWeapon = {}

PickupWeapon.WeaponPrefabName = ""

function PickupWeapon:OnCreate(entity)

end

function PickupWeapon:OnUpdate(entity, delta)

end

function PickupWeapon:OnPickup(entity, otherEntity)
    local weaponHolderEntity = Scene.GetEntityByName("WeaponHolder")
    if not weaponHolderEntity then
        Log.Warn("Cannot find WeaponHolder entity in scene! Cannot pick up weapon.")
        return
    end

    local weaponHolderScript = weaponHolderEntity:GetScriptInstance()
    if not weaponHolderScript then
        Log.Warn("Other entity '" .. otherEntity:GetName() .. "' does not have a WeaponHolder script attached! Cannot pick up weapon.")
        return
    end

    weaponHolderScript:EquipWeapon(self.WeaponPrefabName) -- For now, always equip to slot 1

    Scene.RemoveEntity(entity)
end

return PickupWeapon