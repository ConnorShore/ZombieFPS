local WeaponFire = {}

WeaponFire.FireRate = 300 -- Rounds per minute
WeaponFire.Range = 100.0
WeaponFire.Damage = 10
WeaponFire.ImpactForce = 2.0

-- Bloom (Cone of Fire) Settings
WeaponFire.BaseHipBloom = 0.02    -- Starting inaccuracy when hip firing
WeaponFire.MaxHipBloom = 0.15     -- Maximum inaccuracy when holding the trigger
WeaponFire.BloomPerShot = 0.03    -- How much the cone grows per shot
WeaponFire.BloomDecayRate = 0.5   -- How fast the cone shrinks when not shooting

WeaponFire.TracerEnabled = true
WeaponFire.TracerCadence = 3 -- Spawn a tracer every 3 shots

WeaponFire.GunshotSound = AudioClipRef()
WeaponFire.TracerPrefab = PrefabRef()
WeaponFire.WeaponAimingRef = EntityRef()
WeaponFire.WeaponRecoilRef = EntityRef()

function WeaponFire:OnCreate(entity)
    self.TimeSinceLastShot = 60.0 / self.FireRate -- Initialize so that we can shoot immediately
    self.CurrentBloom = self.BaseHipBloom
    self.ShotCount = 0
    self.CanShoot = true
    self.WeaponAiming = Scene.GetEntityByUUID(self.WeaponAimingRef)
    self.WeaponRecoil = Scene.GetEntityByUUID(self.WeaponRecoilRef)
end

function WeaponFire:OnUpdate(entity, delta)
    self.TimeSinceLastShot = self.TimeSinceLastShot + delta
    local timeBetweenShots = 60.0 / self.FireRate
    self.CanShoot = self.TimeSinceLastShot >= timeBetweenShots

    -- Handle bloom increase/decrease
    if self.CurrentBloom > self.BaseHipBloom then
        self.CurrentBloom = self.CurrentBloom - (self.BloomDecayRate * delta)
        if self.CurrentBloom < self.BaseHipBloom then
            self.CurrentBloom = self.BaseHipBloom
        end
    end
end

function WeaponFire:ResolveAimingScript(weaponEntity)
    if weaponEntity and weaponEntity:IsValid() then
        local aimingScript = weaponEntity:GetScriptInstance("WeaponAiming")
        if aimingScript then
            return aimingScript
        end
    end

    if self.WeaponAiming and self.WeaponAiming:IsValid() then
        return self.WeaponAiming:GetScriptInstance()
    end

    return nil
end

function WeaponFire:ResolveRecoilScript(weaponEntity)
    if weaponEntity and weaponEntity:IsValid() then
        local recoilScript = weaponEntity:GetScriptInstance("WeaponRecoil")
        if recoilScript then
            return recoilScript
        end
    end

    if self.WeaponRecoil and self.WeaponRecoil:IsValid() then
        return self.WeaponRecoil:GetScriptInstance()
    end

    return nil
end

function WeaponFire:Fire(entity, weaponEntity)
    self.TimeSinceLastShot = 0.0
    self.ShotCount = self.ShotCount + 1

    AudioSystem.PlaySound(self.GunshotSound)
    
    local transform = entity:GetComponent("TransformComponent")
    local forward = transform:GetForward()
    local right = transform:GetRight()
    local up = transform:GetUp()

    local weaponController = weaponEntity and weaponEntity:IsValid() and weaponEntity:GetScriptInstance() or nil

    local isADS = false
    if weaponController and weaponController.IsAiming then
        isADS = weaponController:IsAiming()
    else
        local aimingScript = self:ResolveAimingScript(weaponEntity)
        isADS = aimingScript and aimingScript.IsAiming or false
    end

    -- determine spread
    local finalShootDirection = forward
    if not isADS then
        -- Generate random offsets between -CurrentBloom and +CurrentBloom
        local randomX = Math.RandomFloat(-self.CurrentBloom, self.CurrentBloom)
        local randomY = Math.RandomFloat(-self.CurrentBloom, self.CurrentBloom)
        
        finalShootDirection = forward + (right * randomX) + (up * randomY)
        finalShootDirection = Math.Normalize(finalShootDirection)
        
        -- Increase the heat for the next shot!
        self.CurrentBloom = self.CurrentBloom + self.BloomPerShot
        if self.CurrentBloom > self.MaxHipBloom then
            self.CurrentBloom = self.MaxHipBloom
        end
    end

    local position = transform.WorldPosition
    local endPoint = position + finalShootDirection * self.Range

    -- Spawn muzzle flash from the MuzzleFlash script
    local muzzleFlash = weaponController and weaponController:GetMuzzleFlashEntity() or nil
    if muzzleFlash and muzzleFlash:IsValid() then
        local muzzleFlashScript = muzzleFlash:GetScriptInstance()
        muzzleFlashScript:PlayFlash()
    end

    -- Cast a ray to detect hits
    local hitResult = Physics.CastRay(position, endPoint)

    -- Tracer should end at the actual impact point when we hit something.
    local tracerEndPoint = hitResult.Hit and hitResult.CollisionPoint or endPoint
    if self.TracerEnabled and (self.ShotCount % self.TracerCadence == 0) then
        self:SpawnTracer(tracerEndPoint, weaponController)
    end

    if hitResult.Hit then
        local hitEntity = hitResult.Entity

        -- Apply force to the hit entity if it has a RigidbodyComponent
        if hitEntity:ContainsComponent("RigidBodyComponent") then
            local rigidbody = hitEntity:GetComponent("RigidBodyComponent")
            rigidbody:ApplyImpulseAtPoint(finalShootDirection * self.ImpactForce, hitResult.CollisionPoint)

            -- TODO: Move impact logic to a separate script on the hit entity (or some other place probably)
            -- Offset slightly along the surface normal to avoid z-fighting with the hit surface
            local impactPos = hitResult.CollisionPoint + hitResult.SurfaceNormal * 0.01

            local impactEffect = Scene.RetrieveFromPool("ImpactConcretePool", impactPos)
            if impactEffect then
                local impactTransform = impactEffect:GetComponent("TransformComponent")
                local impactRotation = Math.LookAt(hitResult.CollisionPoint, hitResult.SurfaceNormal + hitResult.CollisionPoint)
                impactTransform.Rotation = impactRotation
                hitEntity:AddChild(impactEffect, true)

                local particleEmitter = impactEffect:GetComponent("ParticleEmitterComponent")
                Particles.Burst(particleEmitter, impactPos, 100, Math.ToQuaternion(impactRotation))
            end
        end
    end

    -- Trigger recoil
    if weaponController and weaponController.TriggerRecoil and weaponController:TriggerRecoil() then
        return
    end

    local recoilScript = self:ResolveRecoilScript(weaponEntity)
    if recoilScript then
        recoilScript:Fire()
    end
end

function WeaponFire:SpawnTracer(endPos, weaponController)
    local gunTip = weaponController and weaponController:GetBarrelTipEntity() or nil
    local forward = gunTip and gunTip:IsValid() and gunTip:GetComponent("TransformComponent"):GetForward() or Vector3f.new(0, 0, 1)
    local startPos = gunTip and gunTip:IsValid() and gunTip:GetComponent("TransformComponent").WorldPosition or Vector3f.new(0, 0, 0)

    -- Spawn it a bit infront of the gun tip to avoid z-fighting with the gun model
    startPos = startPos + Math.Normalize(forward) * 0.3

    local tracer = Scene.InstantiatePrefab(self.TracerPrefab, startPos)
    if tracer:IsValid() and startPos then
        local tracerScript = tracer:GetScriptInstance()
        if not tracerScript then
            Log.Error("Tracer prefab does not have a script instance!")
            return
        end
        tracerScript:Spawn(tracer, startPos, endPos)
    end
end

return WeaponFire