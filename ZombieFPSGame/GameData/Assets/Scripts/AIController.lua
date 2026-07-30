local AIController = {}

function AIController:OnCreate(entity)
    -- Reused every frame in OnUpdate to avoid allocating a Vector3f (a GC object) per frame.
    self.moveVec = Vector3f.new(0.0, 0.0, 0.0)

    -- Component handles are safe to cache for the entity's lifetime (they re-resolve the
    -- live component internally), so fetch them once instead of every frame in OnUpdate.
    self.pathComp = entity:GetComponent("AIPathComponent")
    self.transform = entity:GetComponent("TransformComponent")
    self.controller = entity:GetComponent("CharacterControllerComponent")
end

function AIController:OnUpdate(entity, delta)
    local pathComp = self.pathComp
    local transform = self.transform
    local controller = self.controller

    -- Check if we have waypoints to follow
    if #pathComp.Waypoints == 0 then 
        return 
    end
    
    local targetPos = pathComp:GetNextWaypointPosition() 
    local currentPos = transform.WorldPosition
    
    -- Calculate distance
    local dx = targetPos.x - currentPos.x
    local dz = targetPos.z - currentPos.z
    local distance = math.sqrt(dx*dx + dz*dz)
    
    -- Did we arrive?
    if distance <= pathComp.ArrivalTolerance then
        -- Cycle to the next waypoint
        pathComp.CurrentWaypointIndex = (pathComp.CurrentWaypointIndex + 1) % #pathComp.Waypoints
        return 
    end
    
    -- Normalize the direction
    local dirX = dx / distance
    local dirZ = dz / distance
    
    -- Create the movement vector (reuse the cached vector; Move copies it immediately)
    local moveVec = self.moveVec
    moveVec.x = dirX * pathComp.Speed * delta
    moveVec.y = 0.0
    moveVec.z = dirZ * pathComp.Speed * delta

    -- Move using the Character Controller
    controller:Move(moveVec)

    -- Rotate the AI to face the waypoint
    local targetAngle = math.deg(math.atan(dirX, dirZ)) 
    transform.Rotation.y = targetAngle
end

return AIController