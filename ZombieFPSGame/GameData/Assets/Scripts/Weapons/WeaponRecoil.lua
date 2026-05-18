local WeaponRecoil = {}

WeaponRecoil.KickbackZ = 0.2
WeaponRecoil.KickUpY = 0.05
WeaponRecoil.RotationX = 5.0
WeaponRecoil.Snappiness = 20.0
WeaponRecoil.ReturnSpeed = 5.0
WeaponRecoil.ADSKickMultiplier = 0.1 

function WeaponRecoil:OnCreate(entity)
    -- Local Gun Recoil State
    self.TargetPositionOffset  = Vector3f.new(0, 0, 0)
    self.TargetRotationOffset  = Vector3f.new(0, 0, 0)
    
    -- Independent Camera Recoil State
    self.TargetCameraPitch = 0.0
    self.CurrentCameraPitch = 0.0
    self.PreviousCameraPitch = 0.0
    
    self.Camera = Scene.GetEntityByName("Camera")
end

function WeaponRecoil:OnUpdate(entity, delta)
    local transform = entity:GetComponent("TransformComponent")

    -- 1. LOCAL GUN RECOIL (Visually bouncing in hands)
    self.TargetPositionOffset = Math.Lerp(self.TargetPositionOffset, Vector3f.new(0,0,0), self.ReturnSpeed * delta)
    self.TargetRotationOffset = Math.Lerp(self.TargetRotationOffset, Vector3f.new(0,0,0), self.ReturnSpeed * delta)

    transform.Position = Math.Lerp(transform.Position, self.TargetPositionOffset, self.Snappiness * delta)
    transform.Rotation = Math.Lerp(transform.Rotation, self.TargetRotationOffset, self.Snappiness * delta)
    
    -- 2. CAMERA RECOIL (The player's head kicking up)
    self.TargetCameraPitch = Math.Lerp(self.TargetCameraPitch, 0.0, self.ReturnSpeed * delta)
    self.CurrentCameraPitch = Math.Lerp(self.CurrentCameraPitch, self.TargetCameraPitch, self.Snappiness * delta)
    
    -- Calculate how much the camera recoil changed THIS frame
    local pitchDelta = self.CurrentCameraPitch - self.PreviousCameraPitch
    
    -- Inject it directly into the MouseLook/PlayerController script
    if pitchDelta ~= 0.0 and self.Camera then
        local mouseLook = self.Camera:GetScriptInstance() -- Replace with whatever script handles your mouse pitch
        if mouseLook then
            mouseLook.Pitch = mouseLook.Pitch + pitchDelta
        end
    end
    
    self.PreviousCameraPitch = self.CurrentCameraPitch
end

function WeaponRecoil:Fire(entity)
    local aimingEntity = Scene.GetEntityByName("WeaponAiming")
    local isADS = aimingEntity and aimingEntity:GetScriptInstance().IsAiming or false

    if isADS then
        -- 1. ADS STATE
        -- The gun ONLY kicks straight back into the shoulder. NO local rotation!
        self.TargetPositionOffset.z = self.TargetPositionOffset.z + (self.KickbackZ * self.ADSKickMultiplier)
        
        -- ALL the rotational kick goes straight to the camera!
        self.TargetCameraPitch = self.TargetCameraPitch + Math.Radians(self.RotationX)
    else
        -- 2. HIP FIRE STATE
        -- The gun bounces wildly in the hands locally
        self.TargetPositionOffset.z = self.TargetPositionOffset.z + self.KickbackZ
        self.TargetPositionOffset.y = self.TargetPositionOffset.y + self.KickUpY
        self.TargetRotationOffset.x = self.TargetRotationOffset.x + Math.Radians(self.RotationX)
        
        -- Optional: Give the camera a tiny bit of kick even in hip-fire so the screen still shakes
        self.TargetCameraPitch = self.TargetCameraPitch + Math.Radians(self.RotationX * 0.2)
    end
end

return WeaponRecoil