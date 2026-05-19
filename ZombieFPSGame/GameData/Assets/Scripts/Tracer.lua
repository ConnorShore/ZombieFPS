local Tracer = {}

Tracer.Speed = 100.0 -- Meters per second

function Tracer:OnCreate(entity)
    self.StartPosition = Vector3f.new(0, 0, 0)
    self.EndPosition = Vector3f.new(0, 0, 0)
    
    self.DistanceTraveled = 0.0
    self.TotalDistance = 0.0
    self.Entity = entity
end

function Tracer:Spawn(entity, startPos, endPos)
    self.StartPosition = startPos
    self.EndPosition = endPos
    self.TotalDistance = Math.Distance(startPos, endPos)
    
    local transform = entity:GetComponent("TransformComponent")
    transform.Position = startPos
    transform.Rotation = Math.LookAt(startPos, endPos)
end

function Tracer:OnUpdate(entity, delta)
    self.DistanceTraveled = self.DistanceTraveled + (self.Speed * delta)
    
    -- Calculate how far along the path we are (0.0 to 1.0)
    local progress = self.DistanceTraveled / self.TotalDistance
    
    if progress >= 1.0 then
        -- We hit the target! Destroy the fake bullet.
        Scene.RemoveEntity(entity)
    else
        local transform = entity:GetComponent("TransformComponent")
        transform.Position = Math.Lerp(self.StartPosition, self.EndPosition, progress)
    end
end

return Tracer