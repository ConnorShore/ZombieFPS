local Hitbox = {}

-- Expose to editor so a Headshot hitbox can be 2.0, and a toe can be 0.5
Hitbox.DamageMultiplier = 1.0 
Hitbox.ImpactSound = AudioClipRef()

function Hitbox:OnCreate(entity)
    self.ParentEnemy = entity:GetRootParent()
end

function Hitbox:OnTakeDamage(entity, damageInfo)
    -- Spawn Blood Particles at the exact hit point
    local impactPos = damageInfo.HitPoint + damageInfo.HitNormal * 0.01
    -- local impactEffect = Scene.RetrieveFromPool("ImpactFleshPool", impactPos)
    -- if impactEffect then
    --     local impactRotation = Math.LookAt(damageInfo.HitPoint, damageInfo.HitNormal + damageInfo.HitPoint)
    --     impactEffect:GetComponent("TransformComponent").Rotation = impactRotation
        
    --     local particleEmitter = impactEffect:GetComponent("ParticleEmitterComponent")
    --     Particles.Burst(particleEmitter, impactPos, 50, Math.ToQuaternion(impactRotation))
    -- end

    -- Play impact sound
    AudioSystem.PlaySound(self.ImpactSound)

    -- Calculate final damage and forward it to the main Enemy Controller
    local finalDamage = damageInfo.Damage * self.DamageMultiplier
    
    local parentScript = self.ParentEnemy:GetScriptInstance()
    if parentScript and parentScript.ApplyDamage then
        Log.Info("Hitbox applying damage to parent enemy. Base Damage: " .. tostring(damageInfo.Damage) .. ", Multiplier: " .. tostring(self.DamageMultiplier) .. ", Final Damage: " .. tostring(finalDamage))
        parentScript:ApplyDamage(finalDamage)
    else
        Log.Error("Hitbox could not find parent enemy script to apply damage! Parent Enemy: '" .. self.ParentEnemy:GetName() .. "'")
    end
end

return Hitbox