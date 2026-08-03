local PickupItem = {}
PickupItem.Base = "PurchasableItem"

PickupItem.AttachmentType = {
    Sight = 1,
    Stock = 2,
    Muzzle = 3,
    Grip = 4
}

PickupItem.Prefab = PrefabRef()
PickupItem.Cost = 0

function PickupItem:OnCreate(entity)
    local transform = entity:GetComponent("TransformComponent")
    self.PrefabEntity = Scene.InstantiatePrefab(self.Prefab, transform.WorldPosition)
end

function PickupItem:OnUpdate(entity, delta)
end

function PickupItem:OnPickup(entity, otherEntity)
    if not self:TryPurchase() then
        Log.Warn("Not enough points to pick up '" .. entity:GetName() .. "'")
        return
    end

    if self.PrefabEntity and self.PrefabEntity:IsValid() then
        Scene.RemoveEntity(self.PrefabEntity)
        self.PrefabEntity = nil
    end

    Scene.RemoveEntity(entity)
end

function PickupItem:GetAttachmentData()
    return {
        Type = self.AttachmentType,
        PrefabHandle = self.Prefab
    }
end

return PickupItem