local Crosshair = {}

Crosshair.Size = 20

function Crosshair:OnCreate(entity)
    -- Component handles are safe to cache for the entity's lifetime (they re-resolve the
    -- live component internally), so fetch it once here instead of every frame in OnUpdate.
    self.transform = entity:GetComponent("TransformComponent")

    local transform = self.transform
    local screenSize = Renderer.GetViewportSize()

    transform.Position = Vector3f.new(0.5, 0.5, 0)

    self.scaledSizeX = self.Size / screenSize.x
    self.scaledSizeY = self.Size / screenSize.y
    transform.Scale = Vector3f.new(self.scaledSizeX, self.scaledSizeY, 1)

    Log.Info("Crosshair created at position: " .. tostring(transform.Position.x) .. ", " .. tostring(transform.Position.y))
    Log.Info("Crosshair scaled to: " .. tostring(transform.Scale.x) .. ", " .. tostring(transform.Scale.y))
end

function Crosshair:OnUpdate(entity, delta)
    local transform = self.transform
    local screenSize = Renderer.GetViewportSize()

    -- Keep centered
    transform.Position = Vector3f.new(0.5, 0.5, 0)

    self.scaledSizeX = self.Size / screenSize.x
    self.scaledSizeY = self.Size / screenSize.y
    transform.Scale = Vector3f.new(self.scaledSizeX, self.scaledSizeY, 1)
end

return Crosshair