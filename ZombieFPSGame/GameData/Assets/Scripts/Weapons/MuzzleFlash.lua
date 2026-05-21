local MuzzleFlash = {}

MuzzleFlash.FlashDuration = 0.1

function MuzzleFlash:OnCreate(entity)
    self.Entity = entity
    self.FlashTime = 0.0
    self.IsFlashing = false

    -- NOTE: Do NOT cache ParticleEmitterComponent / PointLightComponent handles.
    -- GetComponent returns a raw pointer into EnTT storage; spawning a prefab that
    -- adds the same component type can reallocate the pool and invalidate cached
    -- pointers, causing writes to land on the wrong entity (or freed memory).
    if not entity:ContainsComponent("ParticleEmitterComponent") then
        Log.Warn("MuzzleFlash: No ParticleEmitterComponent found on entity!")
    end
    if not entity:ContainsComponent("PointLightComponent") then
        Log.Warn("MuzzleFlash: No PointLightComponent found on entity!")
    end

    local light = entity:GetComponent("PointLightComponent")
    if light then
        light.IsActive = false -- Ensure light starts off
    end
end

function MuzzleFlash:OnUpdate(entity, delta)
    if self.IsFlashing then
        self.FlashTime = self.FlashTime + delta

        local light = entity:GetComponent("PointLightComponent")
        if light then
            light.IsActive = true
        end

        -- Deactivate the flash after the duration has passed
        if self.FlashTime >= self.FlashDuration then
            local emitter = entity:GetComponent("ParticleEmitterComponent")
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
    local emitter = self.Entity:GetComponent("ParticleEmitterComponent")
    if emitter then
        emitter.IsActive = true
        self.FlashTime = 0.0
        self.IsFlashing = true
    else
        Log.Warning("MuzzleFlash: No ParticleEmitterComponent found on entity!")
    end
end

return MuzzleFlash