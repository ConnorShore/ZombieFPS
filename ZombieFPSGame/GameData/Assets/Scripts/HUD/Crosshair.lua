local Crosshair = {}

Crosshair.Size = 20

function Crosshair:OnCreate(entity)
    local transform = entity:GetComponent("TransformComponent")
    local screenSize = Renderer.GetViewportSize()

    transform.Position = Vector3f.new(0.5, 0.5, 0)

    self.scaledSizeX = self.Size / screenSize.x
    self.scaledSizeY = self.Size / screenSize.y
    transform.Scale = Vector3f.new(self.scaledSizeX, self.scaledSizeY, 1)

    Log.Info("Crosshair created at position: " .. tostring(transform.Position.x) .. ", " .. tostring(transform.Position.y))
    Log.Info("Crosshair scaled to: " .. tostring(transform.Scale.x) .. ", " .. tostring(transform.Scale.y))
end

function Crosshair:OnUpdate(entity, delta)
    local transform = entity:GetComponent("TransformComponent")
    local screenSize = Renderer.GetViewportSize()

    -- Keep centered
    transform.Position = Vector3f.new(0.5, 0.5, 0)

    self.scaledSizeX = self.Size / screenSize.x
    self.scaledSizeY = self.Size / screenSize.y
    transform.Scale = Vector3f.new(self.scaledSizeX, self.scaledSizeY, 1)
end

return Crosshair