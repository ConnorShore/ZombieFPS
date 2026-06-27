local WeaponAiming = {}

WeaponAiming.ADS_Speed = 15.0
WeaponAiming.AimNodeRef = EntityRef()
WeaponAiming.CrosshairRef = EntityRef()
WeaponAiming.CameraSocketRef = EntityRef() 

-- NOTE: Set this slightly forward so the gun mesh doesn't clip through the camera's near plane
WeaponAiming.ADSCameraViewOffset = Vector3f.new(0, 0.0, -0.15) 

-- AAA FPS SETTING: Locks the physical shoulder depth so scopes don't clip into the camera
WeaponAiming.LockZToIronSights = true 
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
    
    self.DefaultAimNode = Scene.GetEntityByUUID(self.AimNodeRef)
    self.CurrentAimNode = self.DefaultAimNode
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
    
    self.IsAiming = Input.IsMouseButtonPressed(MouseButton.Right) and self.CurrentAimNode:IsValid()
    
    local targetPosition = self.HipPosition
    
    if self.IsAiming then
        local aimNodeTransform = self.CurrentAimNode:GetComponent("TransformComponent")
        local socketPos = Vector3f.new(0, 0, 0)
        
        if self.CameraSocket and self.CameraSocket:IsValid() then
            socketPos = self.CameraSocket:GetComponent("TransformComponent").Position
        end

        -- ==========================================================
        -- THE FIX: Hybrid Space Resolution
        -- ==========================================================
        local aimNodeEffectiveLocalPos = Vector3f.new(0, 0, 0)

        -- 1. If using Iron Sights, bypass all projection and use the perfect local position!
        if self.CurrentAimNode == self.DefaultAimNode then
            aimNodeEffectiveLocalPos = aimNodeTransform.Position
        else
            -- 2. If using a scope, project the world offset onto the weapon's X and Y axes
            local aimNodeWorld = aimNodeTransform.WorldPosition
            local weaponAimingWorld = transform.WorldPosition
            
            local right = Math.Normalize(transform:GetRight())
            local up = Math.Normalize(transform:GetUp())
            
            local offsetWorld = Vector3f.new(
                aimNodeWorld.x - weaponAimingWorld.x,
                aimNodeWorld.y - weaponAimingWorld.y,
                aimNodeWorld.z - weaponAimingWorld.z
            )
            
            local dotX = (offsetWorld.x * right.x) + (offsetWorld.y * right.y) + (offsetWorld.z * right.z)
            local dotY = (offsetWorld.x * up.x) + (offsetWorld.y * up.y) + (offsetWorld.z * up.z)
            
            local effectiveX = dotX / self.RootScale.x
            local effectiveY = dotY / self.RootScale.y
            local effectiveZ = 0.0
            
            if self.LockZToIronSights and self.DefaultAimNode:IsValid() then
                -- Lock Z to Iron Sights depth to keep the gun exactly at the shoulder
                effectiveZ = self.DefaultAimNode:GetComponent("TransformComponent").Position.z
            else
                -- Fallback: If shoulder lock is off, auto-calibrate the Z-axis sign
                local forward = Math.Normalize(transform:GetForward())
                local dotZ = (offsetWorld.x * forward.x) + (offsetWorld.y * forward.y) + (offsetWorld.z * forward.z)
                effectiveZ = dotZ / self.RootScale.z

                if self.DefaultAimNode:IsValid() then
                    local defaultLocalZ = self.DefaultAimNode:GetComponent("TransformComponent").Position.z
                    local defaultWorld = self.DefaultAimNode:GetComponent("TransformComponent").WorldPosition
                    local defaultOffset = Vector3f.new(
                        defaultWorld.x - weaponAimingWorld.x,
                        defaultWorld.y - weaponAimingWorld.y,
                        defaultWorld.z - weaponAimingWorld.z
                    )
                    local defaultDotZ = (defaultOffset.x * forward.x) + (defaultOffset.y * forward.y) + (defaultOffset.z * forward.z)
                    
                    -- If the projected Z sign doesn't match the known local Z sign, flip it!
                    if (defaultDotZ > 0 and defaultLocalZ < 0) or (defaultDotZ < 0 and defaultLocalZ > 0) then
                        effectiveZ = -effectiveZ
                    end
                end
            end
            
            aimNodeEffectiveLocalPos = Vector3f.new(effectiveX, effectiveY, effectiveZ)
        end
        -- ==========================================================

        -- Standard camera-matching math using the resolved effective local position
        local targetInSocketSpace = Vector3f.new(
            self.ADSCameraViewOffset.x - socketPos.x,
            self.ADSCameraViewOffset.y - socketPos.y,
            self.ADSCameraViewOffset.z - socketPos.z
        )
        
        local targetInRootSpaceUnscaled = Vector3f.new(
            targetInSocketSpace.x - rootPos.x,
            targetInSocketSpace.y - rootPos.y,
            targetInSocketSpace.z - rootPos.z
        )
        
        local targetInRootSpace = Vector3f.new(
            targetInRootSpaceUnscaled.x / self.RootScale.x,
            targetInRootSpaceUnscaled.y / self.RootScale.y,
            targetInRootSpaceUnscaled.z / self.RootScale.z
        )
        
        targetPosition = Vector3f.new(
            targetInRootSpace.x - aimNodeEffectiveLocalPos.x,
            targetInRootSpace.y - aimNodeEffectiveLocalPos.y,
            targetInRootSpace.z - aimNodeEffectiveLocalPos.z
        )
        
        if self.Crosshair:IsValid() then self.Crosshair:SetActive(false) end
    else
        if self.Crosshair:IsValid() then self.Crosshair:SetActive(true) end
    end
    
    transform.Position = Math.Lerp(transform.Position, targetPosition, delta * self.ADS_Speed)
end

function WeaponAiming:SetOverrideAimNode(nodeEntity)
    if nodeEntity and nodeEntity:IsValid() then
        self.CurrentAimNode = nodeEntity
    end
end

function WeaponAiming:ClearOverrideAimNode()
    self.CurrentAimNode = self.DefaultAimNode
end

return WeaponAiming