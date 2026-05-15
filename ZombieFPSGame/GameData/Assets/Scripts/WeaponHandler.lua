local WeaponHandler = {}

WeaponHandler.ADS_Speed = 15.0

function WeaponHandler:OnCreate(entity)
    local transform = entity:GetComponent("TransformComponent")
    local pos = transform.Position
    local rot = transform.Rotation

    -- Hip-fire rest transform (value copies, not references)
    self.StartPosition  = Vector3f.new(pos.x, pos.y, pos.z)
    self.BaseRotation   = Vector3f.new(rot.x, rot.y, rot.z)
    -- Tracks the smoothed base position independently of recoil so the lerp
    -- is never contaminated by the recoil offset added each frame.
    self.SmoothedPosition = Vector3f.new(pos.x, pos.y, pos.z)

    self.AimNode = Scene.GetEntityByName("ADS_Node")
    if not self.AimNode then
        Log.Warn("WeaponHandler: Cannot find ADS_Node!")
    end

end

function WeaponHandler:OnUpdate(entity, delta)
    -- Lazy-init: WeaponRecoil is a child of this entity so its OnCreate runs
    -- after ours. Resolve the reference on the first update instead.
    if not self.RecoilScript then
        local recoilEntity = Scene.GetEntityByName("WeaponRecoil")
        self.RecoilScript = recoilEntity and recoilEntity:GetScriptInstance() or nil
        if not self.RecoilScript then
            Log.Warn("WeaponHandler: Cannot find WeaponRecoil entity!")
        end
    end
    self:HandleADS(entity, delta)
end

function WeaponHandler:HandleADS(entity, delta)
    local transform = entity:GetComponent("TransformComponent")

    -- Determine the target base position (ADS or hip-fire)
    local targetPosition
    if Input.IsMouseButtonPressed(MouseButton.Right) and self.AimNode then
        Log.Info("Aiming down sights!")
        -- ADS_Node must be a child of WeaponHandler, placed at the iron sight.
        -- Negate its local offset so WeaponHandler shifts until the sight is at camera center.
        local aimNodeTransform = self.AimNode:GetComponent("TransformComponent")
        local viewOffset = Vector3f.new(0.0, 0.0, -0.2)
        targetPosition = viewOffset - aimNodeTransform.Position
    else
        Log.Info("NOT Aiming down sights!")
        targetPosition = self.StartPosition
    end

    -- Smooth the base position toward the target
    self.SmoothedPosition = Math.Lerp(self.SmoothedPosition, targetPosition, delta * self.ADS_Speed)

    -- Read recoil offsets (zero if no recoil script found)
    local posOffset = Vector3f.new(0, 0, 0)
    local rotOffset = Vector3f.new(0, 0, 0)
    if self.RecoilScript then
        posOffset = self.RecoilScript.CurrentPositionOffset
        rotOffset = self.RecoilScript.CurrentRotationOffset
    end

    -- WeaponHandler is the sole writer of this transform
    transform.Position = self.SmoothedPosition + posOffset
    transform.Rotation = self.BaseRotation + rotOffset
end

return WeaponHandler