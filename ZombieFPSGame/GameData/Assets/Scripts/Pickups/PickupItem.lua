-- A weapon attachment lying in the world; interacting fits it to the weapon the player is holding.
local PickupItem = {}
PickupItem.Base = "PurchasableItem"

PickupItem.AttachmentType = {
    Sight = 1,
    Stock = 2,
    Muzzle = 3,
    Grip = 4
}

PickupItem.Prefab = PrefabRef()
PickupItem.WeaponHolderRef = EntityRef()
PickupItem.Cost = 0
PickupItem.InteractionPrompt = "Press (E) to pick up attachment"

function PickupItem:OnCreate(entity)
    self.WeaponHolder = Scene.GetEntityByUUID(self.WeaponHolderRef)
    if not self.WeaponHolder or not self.WeaponHolder:IsValid() then
        Log.Error("PickupItem: WeaponHolder entity is not valid on '" .. entity:GetName() .. "'!")
    end

    local transform = entity:GetComponent("TransformComponent")
    self.PrefabEntity = Scene.InstantiatePrefab(self.Prefab, transform.WorldPosition)
end

-- An attachment can only be fitted to a weapon the player is currently holding.
function PickupItem:CanInteract(entity, playerEntity)
    return self:CanAfford() and self:GetHeldWeaponController() ~= nil
end

function PickupItem:GetInteractionText(entity, playerEntity)
    if not self:GetHeldWeaponController() then
        return "Equip a weapon to attach this"
    end

    return self:GetPurchasePrompt()
end

function PickupItem:OnInteract(entity, playerEntity)
    local weaponController = self:GetHeldWeaponController()
    if not weaponController then
        Log.Warn("Cannot equip attachment: Player is not holding a weapon!")
        return
    end

    if not self:TryPurchase() then
        Log.Warn("Not enough points to pick up '" .. entity:GetName() .. "'")
        return
    end

    weaponController:EquipAttachment(self.AttachmentType, self.Prefab)

    if self.PrefabEntity and self.PrefabEntity:IsValid() then
        Scene.RemoveEntity(self.PrefabEntity)
        self.PrefabEntity = nil
    end

    Scene.RemoveEntity(entity)
end

-- Returns the WeaponController of the weapon the player currently has equipped, or nil. Stays
-- quiet on failure because the prompt polls it every frame the player is looking at this item.
function PickupItem:GetHeldWeaponController()
    local weaponHolder = self.WeaponHolder
    if not weaponHolder or not weaponHolder:IsValid() then
        return nil
    end

    local weaponHolderScript = weaponHolder:GetScriptInstance("WeaponHolder")
    if not weaponHolderScript then
        return nil
    end

    local weaponEntity = weaponHolderScript:GetCurrentWeapon()
    if not weaponEntity or not weaponEntity:IsValid() then
        return nil
    end

    return weaponEntity:GetScriptInstance("WeaponController")
end

return PickupItem
