local DamageSplashController = {}

DamageSplashController.FadeTime = 3.0

function DamageSplashController:OnCreate(entity)
    self.Alpha = 0.0
    self.SpriteComponent = entity:GetComponent("SpriteComponent")

    EventManager.Subscribe("OnPlayerHealthPercentChanged", function(healthPercent)
        self.Alpha = 1.0 - healthPercent
    end)
end

function DamageSplashController:OnUpdate(entity, delta)
    if not self.SpriteComponent then
        Log.Warning("SpriteComponent not found in DamageSplashController")
        return
    end

    self.SpriteComponent.Color = Vector4f.new(1.0, 1.0, 1.0, self.Alpha)
end

return DamageSplashController