local WeaponRecoil = {}

WeaponRecoil.KickbackZ = 0.2
WeaponRecoil.KickUpY = 0.05

-- 1. Expose the Base Pull and the Variance to the Editor
WeaponRecoil.RotationX = 5.0          -- Base Vertical Climb
WeaponRecoil.RotationXVariance = 1.5  -- How much the vertical climb randomly fluctuates

WeaponRecoil.RotationY = 0.5          -- Base Horizontal Drift (Positive = Right)
WeaponRecoil.RotationYVariance = 2.0  -- Random horizontal bounce (Left to Right)

WeaponRecoil.Snappiness = 20.0
WeaponRecoil.ReturnSpeed = 5.0
WeaponRecoil.ADSKickMultiplier = 0.1 

function WeaponRecoil:OnCreate(entity)
    self.TargetPositionOffset  = Vector3f.new(0, 0, 0)
    self.TargetRotationOffset  = Vector3f.new(0, 0, 0)
    
    self.TargetCameraPitch = 0.0
    self.CurrentCameraPitch = 0.0
    self.PreviousCameraPitch = 0.0
    self.TargetCameraYaw = 0.0
    self.CurrentCameraYaw = 0.0
    self.PreviousCameraYaw = 0.0
    self.Camera = Scene.GetEntityByName("Camera")
end

function WeaponRecoil:OnUpdate(entity, delta)
    local transform = entity:GetComponent("TransformComponent")

    -- LOCAL GUN RECOIL (Visually bouncing in hands)
    self.TargetPositionOffset = Math.Lerp(self.TargetPositionOffset, Vector3f.new(0,0,0), self.ReturnSpeed * delta)
    self.TargetRotationOffset = Math.Lerp(self.TargetRotationOffset, Vector3f.new(0,0,0), self.ReturnSpeed * delta)

    transform.Position = Math.Lerp(transform.Position, self.TargetPositionOffset, self.Snappiness * delta)
    transform.Rotation = Math.Lerp(transform.Rotation, self.TargetRotationOffset, self.Snappiness * delta)
    
    -- CAMERA RECOIL (The player's head kicking up)
    self.TargetCameraPitch = Math.Lerp(self.TargetCameraPitch, 0.0, self.ReturnSpeed * delta)
    self.CurrentCameraPitch = Math.Lerp(self.CurrentCameraPitch, self.TargetCameraPitch, self.Snappiness * delta)
    self.TargetCameraYaw = Math.Lerp(self.TargetCameraYaw, 0.0, self.ReturnSpeed * delta)
    self.CurrentCameraYaw = Math.Lerp(self.CurrentCameraYaw, self.TargetCameraYaw, self.Snappiness * delta)
    
    -- Calculate how much the camera recoil changed THIS frame
    local pitchDelta = self.CurrentCameraPitch - self.PreviousCameraPitch
    local yawDelta = self.CurrentCameraYaw - self.PreviousCameraYaw
    
-- Calculate how much the camera recoil changed THIS frame
    local pitchDelta = self.CurrentCameraPitch - self.PreviousCameraPitch
    local yawDelta = self.CurrentCameraYaw - self.PreviousCameraYaw
    
    if self.Camera then
        -- Inject Pitch directly into the MouseLook script (Camera local X rotation)
        if pitchDelta ~= 0.0 then
            local mouseLook = self.Camera:GetScriptInstance()
            if mouseLook then
                mouseLook.Pitch = mouseLook.Pitch + pitchDelta
            end
        end
        
        -- Inject Yaw directly into the Player Root (Body global Y rotation)
        if yawDelta ~= 0.0 then
            local parentEntity = self.Camera:GetRootParent()
            if parentEntity then
                local parentTransform = parentEntity:GetComponent("TransformComponent")
                parentTransform.Rotation.y = parentTransform.Rotation.y + yawDelta
            end
        end
    end
    
    self.PreviousCameraPitch = self.CurrentCameraPitch
    self.PreviousCameraYaw = self.CurrentCameraYaw
end

function WeaponRecoil:Fire(entity)
    local aimingEntity = Scene.GetEntityByName("WeaponAiming")
    local isADS = aimingEntity and aimingEntity:GetScriptInstance().IsAiming or false

    -- Generate the unique recoil math for this specific bullet
    local actualPitch = self.RotationX + Math.RandomFloat(-self.RotationXVariance, self.RotationXVariance)
    local actualYaw = self.RotationY + Math.RandomFloat(-self.RotationYVariance, self.RotationYVariance)

    if isADS then
        self.TargetPositionOffset.z = self.TargetPositionOffset.z + (self.KickbackZ * self.ADSKickMultiplier)
        
        -- Apply the randomized variables to the camera!
        self.TargetCameraPitch = self.TargetCameraPitch + Math.Radians(actualPitch)
        self.TargetCameraYaw = self.TargetCameraYaw + Math.Radians(actualYaw)
    else
        self.TargetPositionOffset.z = self.TargetPositionOffset.z + self.KickbackZ
        self.TargetPositionOffset.y = self.TargetPositionOffset.y + self.KickUpY
        
        -- Apply the randomized variables to the gun mesh!
        self.TargetRotationOffset.x = self.TargetRotationOffset.x + Math.Radians(actualPitch)
        self.TargetRotationOffset.y = self.TargetRotationOffset.y + Math.Radians(actualYaw)
        
        self.TargetCameraPitch = self.TargetCameraPitch + Math.Radians(actualPitch * 0.2)
        self.TargetCameraYaw = self.TargetCameraYaw + Math.Radians(actualYaw * 0.2)
    end
end

return WeaponRecoil