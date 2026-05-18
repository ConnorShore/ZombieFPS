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
    Log.Info("Pickup type: " .. self.PickupType)

    if self.PickupPrefabName == "" then
        Log.Error("PickupPrefabName is not set for entity " .. entity)
        return
    end

    local transform = entity:GetComponent("TransformComponent")
    self.PickupPrefab = Scene.InstantiatePrefab(self.PickupPrefabName, transform.WorldPosition)
    if self.PickupPrefab == nil then
        Log.Error("Failed to instantiate pickup prefab: " .. self.PickupPrefabName)
        return
    end

    Log.Info("Instantiated pickup prefab: " .. self.PickupPrefab:GetName())
end

function PickUpItem:OnUpdate(entity, delta)
    
end

function PickUpItem:OnPickup(entity, otherEntity)
    Log.Info("Picked up item: " .. entity:GetName() .. " by " .. otherEntity:GetName())
    if self.PickupType == PickUpItem.PickupType.Sight then
        Log.Info("Picked up sight!")
        -- TODO: MAke ScopeMountScript a generic MountScript then we just call
        -- OnAttach here with prefabb and type and then have the logic to attach
        -- to the mount point in the MountScript.
        local scopeMount = Scene.GetEntityByName("ScopeMount")
        Log.Info("Found scope mount entity: " .. scopeMount:GetName())
        local scopeMountScript = scopeMount:GetScriptInstance()
        if scopeMountScript and type(scopeMountScript.OnAttach) == "function" then
            Log.Info("Calling OnAttach on scope mount script with prefab: " .. self.PickupPrefabName)
            scopeMountScript:OnAttach(self.PickupPrefabName)
        else
            Log.Warn("Scope mount script not found or does not have OnAttach function")
        end
    elseif self.PickupType == PickUpItem.PickupType.Stock then
        Log.Info("Picked up stock!")
    elseif self.PickupType == PickUpItem.PickupType.Muzzle then
        Log.Info("Picked up muzzle!")
    elseif self.PickupType == PickUpItem.PickupType.Grip then
        Log.Info("Picked up grip!")
    end
    
    if self.PickupPrefab then
         Scene.RemoveEntity(self.PickupPrefab)
         self.PickupPrefab = nil
    end

    Scene.RemoveEntity(entity)
end

return PickUpItem