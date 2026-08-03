local Hitbox = {}

-- Expose to editor so a Headshot hitbox can be 2.0, and a toe can be 0.5
Hitbox.DamageMultiplier = 1.0
Hitbox.ApplyHeadshotMultiplier = false
Hitbox.ImpactSound = AudioClipRef()

function Hitbox:OnCreate(entity)
    self.ParentEnemy = entity:GetRootParent()

    -- Component handles are safe to cache for the entity's lifetime (they re-resolve the
    -- live component internally), so fetch them once here instead of on every hit.
    self.transform = entity:GetComponent("TransformComponent")
    if entity:ContainsComponent("ParticleEmitterComponent") then
        self.particleEmitter = entity:GetComponent("ParticleEmitterComponent")
    end
end

function Hitbox:OnTakeDamage(entity, damageInfo)
    -- Spawn Blood Particles at the exact hit point
    local impactPos = damageInfo.HitPoint + damageInfo.HitNormal * 0.01
    if self.particleEmitter then
        local impactRotation = Math.LookAt(damageInfo.HitPoint, damageInfo.HitNormal + damageInfo.HitPoint)
        self.transform.Rotation = impactRotation

        Particles.Burst(self.particleEmitter, impactPos, 50, Math.ToQuaternion(impactRotation))
    end

    -- Play impact sound
    local randomPitch = Math.RandomFloat(0.95, 1.05)
    local props = AudioSoundProperties.new()
    props.Volume      = 2.5
    props.Pitch       = randomPitch
    AudioSystem.PlayOneShot(self.ImpactSound, props)

    -- Calculate final damage and forward it to the main Enemy Controller
    local finalDamage = damageInfo.Damage * self.DamageMultiplier
    
    local parentScript = self.ParentEnemy:GetScriptInstance()
    if parentScript and parentScript.ApplyDamage then
        parentScript:ApplyDamage(finalDamage, self.ApplyHeadshotMultiplier)
    else
        Log.Error("Hitbox could not find parent enemy script to apply damage! Parent Enemy: '" .. self.ParentEnemy:GetName() .. "'")
    end
end

return Hitbox