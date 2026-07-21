local MuzzleFlash = {}

MuzzleFlash.FlashDuration = 0.1

function MuzzleFlash:OnCreate(entity)
    self.Entity = entity
    self.FlashTime = 0.0
    self.IsFlashing = false

    -- Component handles are now safe to cache for the entity's lifetime: they store the
    -- owning entity and re-resolve the live component internally on every access, so a
    -- prefab spawn reallocating the component pool no longer dangles them (which is why
    -- these used to be re-fetched every frame).
    if not entity:ContainsComponent("ParticleEmitterComponent") then
        Log.Warn("MuzzleFlash: No ParticleEmitterComponent found on entity!")
    end
    if not entity:ContainsComponent("PointLightComponent") then
        Log.Warn("MuzzleFlash: No PointLightComponent found on entity!")
    end

    self.emitter = entity:GetComponent("ParticleEmitterComponent")
    self.light = entity:GetComponent("PointLightComponent")
    if self.light then
        self.light.IsActive = false -- Ensure light starts off
    end
end

function MuzzleFlash:OnUpdate(entity, delta)
    if self.IsFlashing then
        self.FlashTime = self.FlashTime + delta

        local light = self.light
        if light then
            light.IsActive = true
        end

        -- Deactivate the flash after the duration has passed
        if self.FlashTime >= self.FlashDuration then
            local emitter = self.emitter
            if emitter then
                emitter.IsActive = false
            end
            if light then
                light.IsActive = false
            end
            self.IsFlashing = false
        end
    end
end

function MuzzleFlash:PlayFlash()
    local emitter = self.emitter
    if emitter then
        emitter.IsActive = true
        self.FlashTime = 0.0
        self.IsFlashing = true
    else
        Log.Warning("MuzzleFlash: No ParticleEmitterComponent found on entity!")
    end
end

return MuzzleFlash