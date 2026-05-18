local MountBehavior = {}

MountBehavior.MountPrefabName = ""

MountBehavior.MountType = {
    Sight = 1,
    Stock = 2,
    Muzzle = 3,
    Grip = 4
}

function MountBehavior:OnCreate(entity)
    self.Entity = entity

    if self.MountPrefabName ~= "" then
        self:OnAttach(self.MountPrefabName)
    end
end

function MountBehavior:OnUpdate(entity, delta)

end

function MountBehavior:OnAttach(prefabName)
    self.MountPrefabName = prefabName
    if self.MountPrefabName == "" then
        Log.Error("MountPrefabName is not set for entity " .. self.Entity:GetName())
        return
    end

    local transform = self.Entity:GetComponent("TransformComponent")
    self.MountPrefab = Scene.InstantiatePrefab(self.MountPrefabName, self.Entity)
    if self.MountPrefab == nil then
        Log.Error("Failed to instantiate mount prefab: " .. self.MountPrefabName)
        return
    end

    -- Find way to check mount point type and attach to correct mount point entity
    -- on the current weapon
end

function MountBehavior:OnDetach()
    Log.Info("Detaching mount")
    if self.MountPrefab then
        Scene.RemoveEntity(self.MountPrefab)
        self.MountPrefab = nil
        Log.Info("Mount detached and prefab removed")
    else
        Log.Warn("No mount prefab to detach")
    end
    
    self.MountPrefabName = ""
end

return MountBehavior