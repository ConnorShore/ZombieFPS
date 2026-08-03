local PickupWeapon = {}
PickupWeapon.Base = "PurchasableItem"

PickupWeapon.WeaponPrefab = PrefabRef()
PickupWeapon.WeaponHolderRef = EntityRef()
PickupWeapon.Cost = 0

function PickupWeapon:OnCreate(entity)

end

function PickupWeapon:OnUpdate(entity, delta)

end

function PickupWeapon:OnPickup(entity, otherEntity)
    if not self:TryPurchase() then
        Log.Warn("Not enough points to pick up '" .. entity:GetName() .. "'")
        return
    end

    local weaponHolderEntity = Scene.GetEntityByUUID(self.WeaponHolderRef)
    if not weaponHolderEntity:IsValid() then
        Log.Warn("Cannot find WeaponHolder entity in scene! Cannot pick up weapon.")
        return
    end

    local weaponHolderScript = weaponHolderEntity:GetScriptInstance()
    if not weaponHolderScript then
        Log.Warn("Other entity '" .. otherEntity:GetName() .. "' does not have a WeaponHolder script attached! Cannot pick up weapon.")
        return
    end

    weaponHolderScript:EquipWeapon(self.WeaponPrefab) -- For now, always equip to slot 1

    Scene.RemoveEntity(entity)
end

return PickupWeapon