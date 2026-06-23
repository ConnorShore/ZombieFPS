local MountBehavior = {}

MountBehavior.MountPrefab = PrefabRef()

MountBehavior.MountType = {
    Sight = 1,
    Stock = 2,
    Muzzle = 3,
    Grip = 4
}

function MountBehavior:OnCreate(entity)
    self.Entity = entity

end

function MountBehavior:OnUpdate(entity, delta)

end

function MountBehavior:OnAttach(prefabHandle)
    self.MountPrefab = prefabHandle
    local transform = self.Entity:GetComponent("TransformComponent")
    self.MountPrefabEntity = Scene.InstantiatePrefab(self.MountPrefab, self.Entity)
    if not self.MountPrefabEntity:IsValid() then
        Log.Error("Failed to instantiate mount prefab: " .. tostring(self.MountPrefab))
        return
    end

    -- Find way to check mount point type and attach to correct mount point entity
    -- on the current weapon
end

function MountBehavior:OnDetach()
    Log.Info("Detaching mount")
    if self.MountPrefabEntity and self.MountPrefabEntity:IsValid() then
        Scene.RemoveEntity(self.MountPrefabEntity)
        self.MountPrefabEntity = nil
        Log.Info("Mount detached and prefab removed")
    else
        Log.Warn("No mount prefab to detach")
    end
    
end

return MountBehavior