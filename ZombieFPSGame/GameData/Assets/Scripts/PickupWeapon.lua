local PickupWeapon = {}

PickupWeapon.WeaponPrefabName = ""

function PickupWeapon:OnCreate(entity)

end

function PickupWeapon:OnUpdate(entity, delta)

end

function PickupWeapon:OnPickup(entity, otherEntity)
    local weaponHolderScript = otherEntity:GetScriptInstance("WeaponHolder")
    if not weaponHolderScript then
        Log.Warn("Other entity '" .. otherEntity:GetName() .. "' does not have a WeaponHolder script attached! Cannot pick up weapon.")
        return
    end

    weaponHolderScript:EquipWeapon(self.WeaponPrefabName) -- For now, always equip to slot 1

    Scene.RemoveEntity(entity)
end

return PickupWeapon