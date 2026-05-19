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

WeaponFire.GunshotSound = "M4_Shot"

function WeaponFire:OnCreate(entity)
    self.TimeSinceLastShot = 0.0
    self.CurrentBloom = self.BaseHipBloom

    -- keep list of recent 10 shot contact points
    self.RecentShots = {}
end

function WeaponFire:OnUpdate(entity, delta)
    self.TimeSinceLastShot = self.TimeSinceLastShot + delta
    local timeBetweenShots = 60.0 / self.FireRate
    local canFire = self.TimeSinceLastShot >= timeBetweenShots

    -- Draw debug hitpoints
    for _, point in ipairs(self.RecentShots) do
        Debug.DrawCube(point, Vector3f.new(0.1, 0.1, 0.1), Vector4f.new(1.0, 0.0, 0.0, 1.0))
    end

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

    -- Cast a ray to detect hits
    local hitResult = Physics.CastRay(position, endPoint)
    if hitResult.Hit then
        local hitEntity = hitResult.Entity

        -- Draw cube at hit point for debugging
        self.RecentShots[#self.RecentShots + 1] = hitResult.CollisionPoint
        if #self.RecentShots > 10 then
            table.remove(self.RecentShots, 1)
        end

        -- Apply force to the hit entity if it has a RigidbodyComponent
        if hitEntity:ContainsComponent("RigidBodyComponent") then
            local rigidbody = hitEntity:GetComponent("RigidBodyComponent")
            rigidbody:ApplyImpulseAtPoint(forward * self.ImpactForce, hitResult.CollisionPoint)
        end
    end

    -- Trigger recoil
    local recoilEntity = Scene.GetEntityByName("WeaponRecoil")
    if recoilEntity then
        local recoilScript = recoilEntity:GetScriptInstance()
        recoilScript:Fire()
    end
end

return WeaponFire