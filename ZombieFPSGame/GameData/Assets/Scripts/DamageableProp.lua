local DamageableProp = {}

DamageableProp.MaxHealth = 100.0

function DamageableProp:OnCreate(entity)
    self.CurrentHealth = self.MaxHealth
end

function DamageableProp:OnTakeDamage(entity, damageInfo)
    -- Spawn wood/metal sparks using damageInfo.HitPoint
    -- Play a specific metallic ping sound
    
    self.CurrentHealth = self.CurrentHealth - damageInfo.Damage
    if self.CurrentHealth <= 0 then
        -- Spawn an explosion prefab, then destroy this entity
        Scene.RemoveEntity(entity)
    end
end

return DamageableProp