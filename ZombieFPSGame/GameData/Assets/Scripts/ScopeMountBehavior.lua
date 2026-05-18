local ScopeMountBehavior = {}

ScopeMountBehavior.ScopeMountPrefabName = ""

function ScopeMountBehavior:OnCreate(entity)
    self.Entity = entity
    Log.Info("Scope mount behavior created for entity: " .. entity:GetName())
    self:OnAttach(self.ScopeMountPrefabName)
end

function ScopeMountBehavior:OnUpdate(entity, delta)

end

function ScopeMountBehavior:OnAttach(prefabName)
    Log.Info("Attaching prefab: " .. tostring(prefabName))
    Log.Info("[DEBUG] self.Entity = " .. tostring(self.Entity) .. " | name = " .. (self.Entity and self.Entity:GetName() or "NIL"))
    self.ScopeMountPrefabName = prefabName
    if self.ScopeMountPrefabName == "" then
        Log.Error("ScopeMountPrefabName is not set for entity " .. self.Entity:GetName())
        return
    else
        local transform = self.Entity:GetComponent("TransformComponent")
        self.ScopeMountPrefab = Scene.InstantiatePrefab(self.ScopeMountPrefabName, self.Entity)
        if self.ScopeMountPrefab == nil then
            Log.Error("Failed to instantiate scope mount prefab: " .. self.ScopeMountPrefabName)
            return
        end
        Log.Info("Instantiated scope mount prefab: " .. self.ScopeMountPrefab:GetName())
        local scopeMountTransform = self.ScopeMountPrefab:GetComponent("TransformComponent")
        Log.Info("Scope mount prefab position: (" .. tostring(scopeMountTransform.WorldPosition.x) .. ", " .. tostring(scopeMountTransform.WorldPosition.y) .. ", " .. tostring(scopeMountTransform.WorldPosition.z) .. ")")
        Log.Info("Scope mount position: (" .. tostring(transform.WorldPosition.x) .. ", " .. tostring(transform.WorldPosition.y) .. ", " .. tostring(transform.WorldPosition.z) .. ")")
    end
end

function ScopeMountBehavior:OnDetach()
    Log.Info("Detaching scope mount")
    if self.ScopeMountPrefab then
        Scene.RemoveEntity(self.ScopeMountPrefab)
        self.ScopeMountPrefab = nil
        Log.Info("Scope mount detached and prefab removed")
    else
        Log.Warn("No scope mount prefab to detach")
    end
    
    self.ScopeMountPrefabName = ""
end

return ScopeMountBehavior