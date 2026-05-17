local PickUpItem = {}

PickUpItem.PickupPrefabName = ""

-- In future may need to split to types like (attachment, ammo, health, etc.) 
-- but for now just one type for all pickups
PickUpItem.PickupType = {
    Sight = 1,
    Stock = 2,
    Muzzle = 3,
    Grip = 4
}

function PickUpItem:OnCreate(entity)
    if self.PickupPrefabName == "" then
        Log.Error("PickupPrefabName is not set for entity " .. entity)
        return
    end

    local transform = entity:GetComponent("TransformComponent")
    self.PickupPrefab = Scene.InstantiatePrefab(self.PickupPrefabName, transform.Position)
    if self.PickupPrefab == nil then
        Log.Error("Failed to instantiate pickup prefab: " .. self.PickupPrefabName)
        return
    end
end

function PickUpItem:OnUpdate(entity, delta)
    
end

function PickUpItem:OnPickup(entity, otherEntity)
    
    Scene.RemoveEntity(entity)
end

return PickUpItem