local WeaponRecoil = {}

-- Exposed to your ImGui Editor for tweaking the "feel"
WeaponRecoil.KickbackZ = 0.2     -- How far the gun pushes into the camera
WeaponRecoil.KickUpY = 0.05      -- How far the barrel kicks up
WeaponRecoil.RotationX = 5.0     -- Degrees the gun tilts up
WeaponRecoil.Snappiness = 20.0   -- How fast it kicks back
WeaponRecoil.ReturnSpeed = 5.0   -- How fast it returns to rest

-- TODO: Add some random variance to the recoil pattern so it's not exactly the same every time

function WeaponRecoil:OnCreate(entity)
    self.TargetPositionOffset  = Vector3f.new(0, 0, 0)
    self.TargetRotationOffset  = Vector3f.new(0, 0, 0)
    self.CurrentPositionOffset = Vector3f.new(0, 0, 0)
    self.CurrentRotationOffset = Vector3f.new(0, 0, 0)
end

function WeaponRecoil:OnUpdate(entity, delta)
    -- 1. Smoothly return the TARGET offset back to zero (resting state)
    self.TargetPositionOffset = Math.Lerp(self.TargetPositionOffset, Vector3f.new(0,0,0), self.ReturnSpeed * delta)
    self.TargetRotationOffset = Math.Lerp(self.TargetRotationOffset, Vector3f.new(0,0,0), self.ReturnSpeed * delta)

    -- 2. Snap the CURRENT offset toward the TARGET offset
    self.CurrentPositionOffset = Math.Lerp(self.CurrentPositionOffset, self.TargetPositionOffset, self.Snappiness * delta)
    self.CurrentRotationOffset = Math.Lerp(self.CurrentRotationOffset, self.TargetRotationOffset, self.Snappiness * delta)
    -- WeaponHandler reads CurrentPositionOffset / CurrentRotationOffset and applies them.
end

-- Call this function from your Player script EXACTLY when the raycast fires!
function WeaponRecoil:Fire(entity)
    -- Add the kick to the target offset. 
    -- Because we ADD it, firing really fast (like an SMG) will stack the recoil!
    
    -- Kick backward (Z) and slightly up (Y)
    self.TargetPositionOffset.z = self.TargetPositionOffset.z + self.KickbackZ
    self.TargetPositionOffset.y = self.TargetPositionOffset.y + self.KickUpY
    
    -- Tilt the barrel up
    self.TargetRotationOffset.x = self.TargetRotationOffset.x + Math.Radians(self.RotationX)
    
    -- Optional: Add a tiny bit of random side-to-side X rotation for variance
    -- self.TargetRotationOffset.y = self.TargetRotationOffset.y + Math.RandomFloat(-1.0, 1.0)
end

return WeaponRecoil