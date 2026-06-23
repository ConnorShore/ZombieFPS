local WeaponAiming = {}

WeaponAiming.ADS_Speed = 15.0
WeaponAiming.AimNodeRef = EntityRef()
WeaponAiming.CrosshairRef = EntityRef()
WeaponAiming.CameraSocketRef = EntityRef() 

-- NOTE: Set this slightly forward so the gun mesh doesn't clip through the camera's near plane
WeaponAiming.ADSCameraViewOffset = Vector3f.new(0, 0.0, -0.15) 
WeaponAiming.DebugADSLogging = false

function WeaponAiming:ResolveWeaponPrefabRoot(entity)
    local current = entity
    while current and current:IsValid() do
        if current:ContainsComponent("PrefabComponent") then
            return current
        end
        if current:IsRootParent() then
            break
        end
        current = current:GetParent()
    end
    return entity:GetRootParent()
end

function WeaponAiming:OnCreate(entity)
    self.HipPosition = Vector3f.new(0, 0, 0)
    self.IsAiming = false
    self.RootScale = Vector3f.new(1, 1, 1)
    
    self.AimNode = Scene.GetEntityByUUID(self.AimNodeRef)
    self.Crosshair = Scene.GetEntityByUUID(self.CrosshairRef)
    
    self.CameraSocket = Scene.GetEntityByUUID(self.CameraSocketRef)
    if not self.CameraSocket:IsValid() then
        Log.Warn("WeaponAiming: Cannot find CameraSocketRef!")
    end
end

function WeaponAiming:OnUpdate(entity, delta)
    local transform = entity:GetComponent("TransformComponent")
    
    local rootPos = Vector3f.new(0, 0, 0)
    self.WeaponRoot = self:ResolveWeaponPrefabRoot(entity)
    if self.WeaponRoot and self.WeaponRoot:IsValid() then
        local rootTransform = self.WeaponRoot:GetComponent("TransformComponent")
        self.RootScale = rootTransform.Scale
        rootPos = rootTransform.Position
    end
    
    self.IsAiming = Input.IsMouseButtonPressed(MouseButton.Right) and self.AimNode:IsValid()
    
    local targetPosition = self.HipPosition
    
    if self.IsAiming then
        local aimNodeTransform = self.AimNode:GetComponent("TransformComponent")
        local socketPos = Vector3f.new(0, 0, 0)
        
        if self.CameraSocket and self.CameraSocket:IsValid() then
            socketPos = self.CameraSocket:GetComponent("TransformComponent").Position
        end
        
        -- 1. CameraSpace to SocketSpace 
        local targetInSocketSpace = Vector3f.new(
            self.ADSCameraViewOffset.x - socketPos.x,
            self.ADSCameraViewOffset.y - socketPos.y,
            self.ADSCameraViewOffset.z - socketPos.z
        )
        
        -- 2. SocketSpace to RootSpace (Subtract the weapon's EquipPositionOffset)
        local targetInRootSpaceUnscaled = Vector3f.new(
            targetInSocketSpace.x - rootPos.x,
            targetInSocketSpace.y - rootPos.y,
            targetInSocketSpace.z - rootPos.z
        )
        
        -- 3. Apply Root Scale to convert to local weapon space
        local targetInRootSpace = Vector3f.new(
            targetInRootSpaceUnscaled.x / self.RootScale.x,
            targetInRootSpaceUnscaled.y / self.RootScale.y,
            targetInRootSpaceUnscaled.z / self.RootScale.z
        )
        
        -- 4. Subtract the ADS Node's local offset to perfectly align it
        targetPosition = Vector3f.new(
            targetInRootSpace.x - aimNodeTransform.Position.x,
            targetInRootSpace.y - aimNodeTransform.Position.y,
            targetInRootSpace.z - aimNodeTransform.Position.z
        )
        
        if self.Crosshair:IsValid() then self.Crosshair:SetActive(false) end
    else
        if self.Crosshair:IsValid() then self.Crosshair:SetActive(true) end
    end
    
    transform.Position = Math.Lerp(transform.Position, targetPosition, delta * self.ADS_Speed)
end

return WeaponAiming