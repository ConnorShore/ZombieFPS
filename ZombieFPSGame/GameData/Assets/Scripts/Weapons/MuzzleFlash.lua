local MuzzleFlash = {}

-- Expose properties to the editor by adding them to this table. For Example:
-- MuzzleFlash.MyExampleVar = 10

MuzzleFlash.FlashDuration = 0.1

function MuzzleFlash:OnCreate(entity)
    self.Entity = entity
    self.FlashTime = 0.0
    self.IsFlashing = false
    self.ParticleEmitter = entity:GetComponent("ParticleEmitterComponent")
    self.Light = entity:GetComponent("PointLightComponent")
    self.Light.IsActive = false -- Ensure light starts off
    if not self.ParticleEmitter then
        Log.Warn("MuzzleFlash: No ParticleEmitterComponent found on entity!")
    end
    if not self.Light then
        Log.Warn("MuzzleFlash: No PointLightComponent found on entity!")
    end
end

function MuzzleFlash:OnUpdate(entity, delta)
    if self.IsFlashing then
        self.FlashTime = self.FlashTime + delta

        -- Mark light as active if flashing
        if self.Light then
            self.Light.IsActive = true
        end

        -- Deactivate the flash after the duration has passed
        if self.FlashTime >= self.FlashDuration then
            if self.ParticleEmitter then
                self.ParticleEmitter.IsActive = false
            end
            if self.Light then
                self.Light.IsActive = false
            end
            self.IsFlashing = false
        end
    end
end

function MuzzleFlash:PlayFlash()
    if self.ParticleEmitter then
        self.ParticleEmitter.IsActive = true
        self.FlashTime = 0.0
        self.IsFlashing = true
    else
        Log.Warning("MuzzleFlash: No ParticleEmitterComponent found on entity!")
    end
end

return MuzzleFlash