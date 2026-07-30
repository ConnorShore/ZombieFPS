local DamageSplashController = {}

DamageSplashController.VisibleTime = 5.0
DamageSplashController.FadeTime = 3.0

function DamageSplashController:OnCreate(entity)
    self.Visible = false
    self.VisibleTimer = 0.0

    self.SpriteComponent = entity:GetComponent("SpriteComponent")

    EventManager.Subscribe("OnPlayerDamaged", function(damage)
        self.Visible = true
        self.VisibleTimer = self.VisibleTime
    end)
end

function DamageSplashController:OnUpdate(entity, delta)
    if not self.SpriteComponent then
        Log.Warning("SpriteComponent not found in DamageSplashController")
        return
    end

    local alpha = 0.0
    if self.Visible then
        self.VisibleTimer = self.VisibleTimer - delta
        if self.VisibleTimer <= self.FadeTime then
            -- Fade transparency of the sprite color based on the remaining fade time
            alpha = Math.Max(self.VisibleTimer / self.FadeTime, 0.0)
        else
            alpha = 1.0
        end
    else
        alpha = 0.0
    end

    self.SpriteComponent.Color = Vector4f.new(1.0, 1.0, 1.0, alpha)
end

return DamageSplashController