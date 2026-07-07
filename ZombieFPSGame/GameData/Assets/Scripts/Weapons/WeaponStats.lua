local WeaponStats = {}

local FIRE_MODE = {
    SemiAuto = 1,
    FullAuto = 2
}

WeaponStats.FireMode = FIRE_MODE

WeaponStats.FireRate = 300 -- Rounds per minute
WeaponStats.Range = 100.0
WeaponStats.Damage = 10
WeaponStats.ImpactForce = 2.0

-- Bloom (Cone of Fire) Settings
WeaponStats.BaseHipBloom = 0.02    -- Starting inaccuracy when hip firing
WeaponStats.MaxHipBloom = 0.15     -- Maximum inaccuracy when holding the trigger
WeaponStats.BloomPerShot = 0.03    -- How much the cone grows per shot
WeaponStats.BloomDecayRate = 0.5   -- How fast the cone shrinks when not shooting

WeaponStats.GunshotSound = AudioClipRef()

function WeaponStats:OnCreate(entity)
	self.CurrentBloom = self.BaseHipBloom
end

function WeaponStats:OnUpdate(entity, delta)

end

function WeaponStats:IsSemiAuto()
    local fireMode = self.FireMode
    if type(fireMode) == "table" then
        fireMode = FIRE_MODE.SemiAuto
    end

    return fireMode == FIRE_MODE.SemiAuto
end

return WeaponStats