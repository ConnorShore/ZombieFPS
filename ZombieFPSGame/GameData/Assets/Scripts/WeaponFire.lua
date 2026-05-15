local WeaponFire = {}

-- Expose properties to the editor by adding them to this table. For Example:
-- WeaponFire.MyExampleVar = 10

WeaponFire.FireRate = 300 -- Rounds per minute
WeaponFire.ImpactForce = 2.0
WeaponFire.Damage = 10
WeaponFire.Range = 100.0
WeaponFire.GunshotSound = "M4_Shot"

function WeaponFire:OnCreate(entity)
    self.TimeSinceLastShot = 0.0
end

function WeaponFire:OnUpdate(entity, delta)
    self.TimeSinceLastShot = self.TimeSinceLastShot + delta
    local timeBetweenShots = 60.0 / self.FireRate
    local canFire = self.TimeSinceLastShot >= timeBetweenShots

    if canFire and Input.IsMouseButtonPressed(MouseButton.Left) then
        self:Fire(entity)
        self.TimeSinceLastShot = 0.0
    end

end

function WeaponFire:Fire(entity)

    AudioSystem.PlaySound(self.GunshotSound)

    local transform = entity:GetComponent("TransformComponent")
    local forward = transform:GetForward()

    local position = transform.WorldPosition
    local endPoint = position + forward * self.Range

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

        -- Apply force to the hit entity if it has a RigidbodyComponent
        if hitEntity:ContainsComponent("RigidBodyComponent") then
            local rigidbody = hitEntity:GetComponent("RigidBodyComponent")
            rigidbody:ApplyImpulse(forward * self.ImpactForce)
        end

    else
        Log.Info("Missed! No entity hit.")
    end

    -- Trigger recoil
    local recoilEntity = Scene.GetEntityByName("WeaponRecoil")
    if recoilEntity then
        local recoilScript = recoilEntity:GetScriptInstance()
        recoilScript:Fire()
    end
end

return WeaponFire