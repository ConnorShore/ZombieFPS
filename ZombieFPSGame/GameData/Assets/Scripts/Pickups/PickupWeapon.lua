-- A weapon lying in the world; interacting buys it and equips it on the player's weapon holder.
local PickupWeapon = {}
PickupWeapon.Base = "PurchasableItem"

PickupWeapon.WeaponPrefab = PrefabRef()
PickupWeapon.WeaponHolderRef = EntityRef()
PickupWeapon.Cost = 0
PickupWeapon.InteractionPrompt = "Press (E) to pick up weapon"

function PickupWeapon:OnCreate(entity)
    self.WeaponHolder = Scene.GetEntityByUUID(self.WeaponHolderRef)
    if not self.WeaponHolder or not self.WeaponHolder:IsValid() then
        Log.Error("PickupWeapon: WeaponHolder entity is not valid on '" .. entity:GetName() .. "'!")
    end
end

function PickupWeapon:OnInteract(entity, playerEntity)
    local weaponHolder = self.WeaponHolder
    if not weaponHolder or not weaponHolder:IsValid() then
        Log.Warn("Cannot find WeaponHolder entity in scene! Cannot pick up weapon.")
        return
    end

    local weaponHolderScript = weaponHolder:GetScriptInstance("WeaponHolder")
    if not weaponHolderScript then
        Log.Warn("Entity '" .. weaponHolder:GetName() .. "' does not have a WeaponHolder script attached! Cannot pick up weapon.")
        return
    end

    if not self:TryPurchase() then
        Log.Warn("Not enough points to pick up '" .. entity:GetName() .. "'")
        return
    end

    weaponHolderScript:EquipWeapon(self.WeaponPrefab)

    Scene.RemoveEntity(entity)
end

return PickupWeapon
