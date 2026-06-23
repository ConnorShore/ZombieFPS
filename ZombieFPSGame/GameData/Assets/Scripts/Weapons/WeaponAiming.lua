local WeaponAiming = {}

WeaponAiming.ADS_Speed = 15.0
WeaponAiming.AimNodeRef = EntityRef()
WeaponAiming.CrosshairRef = EntityRef()
WeaponAiming.WeaponHandlerRef = EntityRef()

function WeaponAiming:OnCreate(entity)
    self.HipPosition = Vector3f.new(0, 0, 0)
    self.IsAiming = false
    
    self.AimNode = Scene.GetEntityByUUID(self.AimNodeRef)
    if not self.AimNode:IsValid() then
        Log.Warn("WeaponAiming: Cannot find ADS_Node!")
    end

    self.Crosshair = Scene.GetEntityByUUID(self.CrosshairRef)
    
    -- Cache the root WeaponHandler so we can grab the Hip Offset
    self.WeaponHandler = Scene.GetEntityByUUID(self.WeaponHandlerRef)
    if not self.WeaponHandler:IsValid() then
        Log.Warn("WeaponAiming: Cannot find WeaponHandler root!")
    end
end

function WeaponAiming:OnUpdate(entity, delta)
    local transform = entity:GetComponent("TransformComponent")
    
    self.IsAiming = Input.IsMouseButtonPressed(MouseButton.Right) and self.AimNode:IsValid()
    
    local targetPosition = self.HipPosition
    
    if self.IsAiming then
        local aimNodeTransform = self.AimNode:GetComponent("TransformComponent")
        local viewOffset = Vector3f.new(0.0, 0.0, -0.2)
        
        -- Default to (0,0,0) if for some reason the handler wasn't found
        local hipOffset = Vector3f.new(0, 0, 0)
        if self.WeaponHandler:IsValid() then
            hipOffset = self.WeaponHandler:GetComponent("TransformComponent").Position
        end
        
        -- Subtract the hip offset to climb back up to Camera Space
        targetPosition = viewOffset - aimNodeTransform.Position - hipOffset
        
        if self.Crosshair:IsValid() then self.Crosshair:SetActive(false) end
    else
        if self.Crosshair:IsValid() then self.Crosshair:SetActive(true) end
    end
    
    transform.Position = Math.Lerp(transform.Position, targetPosition, delta * self.ADS_Speed)
end

return WeaponAiming