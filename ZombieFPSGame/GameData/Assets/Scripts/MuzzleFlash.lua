local MuzzleFlash = {}

-- Expose properties to the editor by adding them to this table. For Example:
-- MuzzleFlash.MyExampleVar = 10

MuzzleFlash.FlashDuration = 0.1

function MuzzleFlash:OnCreate(entity)
    self.Entity = entity
    self.FlashTime = 0.0
    self.IsFlashing = false
    self.ParticleEmitter = entity:GetComponent("ParticleEmitterComponent")
    if not self.ParticleEmitter then
        Log.Warn("MuzzleFlash: No ParticleEmitterComponent found on entity!")
    end
end

function MuzzleFlash:OnUpdate(entity, delta)
    if self.IsFlashing then
        self.FlashTime = self.FlashTime + delta
        if self.FlashTime >= self.FlashDuration then
            if self.ParticleEmitter then
                self.ParticleEmitter.IsActive = false
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


    -- local transform = self.Entity:GetComponent("TransformComponent")
    -- local position = transform.WorldPosition

    -- local flashEmitter = Scene.AddEntity("FlashEmitter")
    -- local emitterTransform = flashEmitter:GetComponent("TransformComponent")
    -- emitterTransform.Position = position;
    
    -- local lifetimeComp = flashEmitter:AttachComponent("LifetimeComponent")
    -- lifetimeComp.Lifetime = 0.05

    -- local emitterComp = flashEmitter:AttachComponent("ParticleEmitterComponent")
    -- emitterComp.EmissionRate = 200.0 

    -- -- local flashTexture = AssetManager.GetAsset("Texture", "FlashParticle")
    
    -- -- PHYSICS: Shoot forward, but spread out wildly in all directions
    -- emitterComp.Velocity = Vector3f.new(0.01, 0.01, -1.0)
    -- emitterComp.VelocityVariation = Vector3f.new(10.0, 10.0, 1.0) 

    -- -- VISUALS: Deep red fading to transparent dark red
    -- emitterComp.ColorBegin = Vector4f.new(0.890, 0.588, 0.006, 1.000)
    -- emitterComp.ColorEnd = Vector4f.new(0.296, 0.296, 0.296, 0.000)
    
    -- emitterComp.ScaleBegin = 0.4
    -- emitterComp.ScaleEnd = 0.2
    -- emitterComp.ScaleVariation = 0.1
    
    -- -- Particles only live for a fraction of a second
    -- emitterComp.Lifetime = 0.25
    -- emitterComp.LifetimeVariation = 0.1

    -- -- emitterComp.TextureHandle = flashTexture:GetUUID()
    
    -- emitterComp.IsActive = true
end

return MuzzleFlash