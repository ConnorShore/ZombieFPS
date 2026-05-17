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

    -- ADS recoil camera state
    self.PreviousADSRecoilPitch = 0.0
    self.WasADS = false

    self.AimNode = Scene.GetEntityByName("ADS_Node")
    if not self.AimNode then
        Log.Warn("WeaponHandler: Cannot find ADS_Node!")
    end

    self.Crosshair = Scene.GetEntityByName("Crosshair")
    if not self.Crosshair then
        Log.Warn("WeaponHandler: Cannot find Crosshair entity!")
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

    -- Lazy-init: grab the MouseLook script from the parent camera entity.
    -- MouseLook owns self.Pitch as source of truth, so we inject camera recoil
    -- there rather than writing transform.Rotation.x directly (which it overwrites).
    if not self.MouseLookScript then
        local camera = entity:GetParent()
        self.MouseLookScript = camera and camera:GetScriptInstance() or nil
        if not self.MouseLookScript then
            Log.Warn("WeaponHandler: Cannot find MouseLook script on parent camera!")
        end
    end

    self:HandleADS(entity, delta)
end

function WeaponHandler:HandleADS(entity, delta)
    local transform = entity:GetComponent("TransformComponent")
    local isADS = Input.IsMouseButtonPressed(MouseButton.Right) and self.AimNode ~= nil

    -- Determine the target base position (ADS or hip-fire)
    local targetPosition
    if isADS then
        -- ADS_Node must be a child of WeaponHandler, placed at the iron sight.
        -- Negate its local offset so WeaponHandler shifts until the sight is at camera center.
        local aimNodeTransform = self.AimNode:GetComponent("TransformComponent")
        local viewOffset = Vector3f.new(0.0, 0.0, -0.2)
        targetPosition = viewOffset - aimNodeTransform.Position
    else
        targetPosition = self.StartPosition
    end

    -- Smooth the base position toward the target
    self.SmoothedPosition = Math.Lerp(self.SmoothedPosition, targetPosition, delta * self.ADS_Speed)

    -- Read recoil offsets
    local posOffset = Vector3f.new(0, 0, 0)
    local rotOffset = Vector3f.new(0, 0, 0)
    if self.RecoilScript then
        posOffset = self.RecoilScript.CurrentPositionOffset
        rotOffset = self.RecoilScript.CurrentRotationOffset
    end

    if isADS then
        -- Lock weapon to sight position. Suppress position recoil entirely when ADS
        -- (no KickbackZ clipping, and position kick has no meaning when locked to sight).
        transform.Position = self.SmoothedPosition + Vector3f.new(0, 0, posOffset.z)
        transform.Rotation = self.BaseRotation

        -- Feed recoil pitch into MouseLook.Pitch as a delta each frame.
        -- MouseLook owns Pitch as source of truth and writes Rotation.x itself,
        -- so this is the only safe way to add camera kick without being overwritten.
        if self.MouseLookScript then
            local recoilPitchDelta = rotOffset.x - self.PreviousADSRecoilPitch
            self.MouseLookScript.Pitch = self.MouseLookScript.Pitch + recoilPitchDelta
            self.PreviousADSRecoilPitch = rotOffset.x
        end
        self.WasADS = true

        -- Disable crosshair when ADS
        if self.Crosshair then
            self.Crosshair:SetActive(false)
        end
    else
        -- On the first frame out of ADS, remove any camera pitch recoil we added.
        if self.WasADS and self.PreviousADSRecoilPitch ~= 0.0 then
            if self.MouseLookScript then
                self.MouseLookScript.Pitch = self.MouseLookScript.Pitch - self.PreviousADSRecoilPitch
            end
            self.PreviousADSRecoilPitch = 0.0
        end
        self.WasADS = false

        -- Hip-fire: apply recoil offsets directly to the weapon
        transform.Position = self.SmoothedPosition + posOffset
        transform.Rotation = self.BaseRotation + rotOffset

        -- Enable crosshair when not ADS
        if self.Crosshair then
            self.Crosshair:SetActive(true)
        end
    end
end

return WeaponHandler