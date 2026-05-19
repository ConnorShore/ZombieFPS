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
WeaponFire.TracerCadence = 3 -- Spawn a tracer every 3 shots (1 = every shot, 2 = every other shot, etc.)

WeaponFire.GunshotSound = "M4_Shot"

function WeaponFire:OnCreate(entity)
    self.TimeSinceLastShot = 0.0
    self.CurrentBloom = self.BaseHipBloom
    self.ShotCount = 0
end

function WeaponFire:OnUpdate(entity, delta)
    self.TimeSinceLastShot = self.TimeSinceLastShot + delta
    local timeBetweenShots = 60.0 / self.FireRate
    local canFire = self.TimeSinceLastShot >= timeBetweenShots

    -- Handle bloom increase/decrease
    if self.CurrentBloom > self.BaseHipBloom then
        self.CurrentBloom = self.CurrentBloom - (self.BloomDecayRate * delta)
        if self.CurrentBloom < self.BaseHipBloom then
            self.CurrentBloom = self.BaseHipBloom
        end
    end

    -- Shoot when left mouse button is pressed and we are allowed to fire based on the fire rate
    if canFire and Input.IsMouseButtonPressed(MouseButton.Left) then
        self:Fire(entity)
        self.TimeSinceLastShot = 0.0
    end

end

function WeaponFire:Fire(entity)
    self.ShotCount = self.ShotCount + 1

    AudioSystem.PlaySound(self.GunshotSound)
    
    local transform = entity:GetComponent("TransformComponent")
    local forward = transform:GetForward()
    local right = transform:GetRight()
    local up = transform:GetUp()

    local aimingEntity = Scene.GetEntityByName("WeaponAiming")
    local isADS = aimingEntity and aimingEntity:GetScriptInstance().IsAiming or false

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
    local muzzleFlash = Scene.GetEntityByName("MuzzleFlash")
    if muzzleFlash then
        local muzzleFlashScript = muzzleFlash:GetScriptInstance()
        muzzleFlashScript:PlayFlash()
    end

    -- Spawn tracer
    if self.TracerEnabled and (self.ShotCount % self.TracerCadence == 0) then
        self:SpawnTracer(endPoint)
    end

    -- Cast a ray to detect hits
    local hitResult = Physics.CastRay(position, endPoint)
    if hitResult.Hit then
        local hitEntity = hitResult.Entity

        -- Apply force to the hit entity if it has a RigidbodyComponent
        if hitEntity:ContainsComponent("RigidBodyComponent") then
            local rigidbody = hitEntity:GetComponent("RigidBodyComponent")
            rigidbody:ApplyImpulseAtPoint(forward * self.ImpactForce, hitResult.CollisionPoint)

            -- TODO: Move impact logic to a separate script on the hit entity (or some other place probably)
            -- Offset slightly along the surface normal to avoid z-fighting with the hit surface
            local impactPos = hitResult.CollisionPoint + hitResult.SurfaceNormal * 0.01
            local impactEffect = Scene.InstantiatePrefab("ImpactConcrete", impactPos)
            if impactEffect then
                local impactTransform = impactEffect:GetComponent("TransformComponent")
                impactTransform.Rotation = Math.LookAt(hitResult.CollisionPoint, hitResult.SurfaceNormal + hitResult.CollisionPoint)
                local particleEmitter = impactEffect:GetComponent("ParticleEmitterComponent")
                Particles.Burst(particleEmitter, impactPos, 100)
            end
        end
    end

    -- Trigger recoil
    local recoilEntity = Scene.GetEntityByName("WeaponRecoil")
    if recoilEntity then
        local recoilScript = recoilEntity:GetScriptInstance()
        recoilScript:Fire()
    end
end

function WeaponFire:SpawnTracer(endPos)
    local gunTip = Scene.GetEntityByName("BarrelTip")
    local forward = gunTip and gunTip:GetComponent("TransformComponent"):GetForward() or Vector3f.new(0, 0, 1)
    local startPos = gunTip and gunTip:GetComponent("TransformComponent").WorldPosition or Vector3f.new(0, 0, 0)

    -- Spawn it a bit infront of the gun tip to avoid z-fighting with the gun model
    startPos = startPos + Math.Normalize(forward) * 0.3

    local tracer = Scene.InstantiatePrefab("Tracer", startPos)
    if tracer and startPos then
        local tracerScript = tracer:GetScriptInstance()
        if not tracerScript then
            Log.Error("Tracer prefab does not have a script instance!")
            return
        end
        tracerScript:Spawn(tracer, startPos, endPos)
    end
end

return WeaponFire