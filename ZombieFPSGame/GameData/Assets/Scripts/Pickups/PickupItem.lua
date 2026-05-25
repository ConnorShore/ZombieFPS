local PickUpItem = {}

PickUpItem.AttachmentType = {
    Sight = 1,
    Stock = 2,
    Muzzle = 3,
    Grip = 4
}

-- TODO: Remove this prefab name and just have the actual model
-- and attach this script to it
PickUpItem.PrefabName = ""

function PickUpItem:OnCreate(entity)
    local transform = entity:GetComponent("TransformComponent")
    self.PrefabEntity = Scene.InstantiatePrefab(self.PrefabName, transform.WorldPosition)
end

function PickUpItem:OnUpdate(entity, delta)
end

function PickUpItem:OnPickup(entity, otherEntity)
    if self.PrefabEntity then
        Scene.RemoveEntity(self.PrefabEntity)
        self.PrefabEntity = nil
    end

    Scene.RemoveEntity(entity)
end

function PickUpItem:GetAttachmentData()
    return {
        Type = self.AttachmentType,
        PrefabName = self.PrefabName
    }
end

return PickUpItem