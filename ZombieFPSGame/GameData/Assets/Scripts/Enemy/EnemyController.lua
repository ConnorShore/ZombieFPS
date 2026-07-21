local EnemyController = {}

EnemyController.BaseHealth = 50
EnemyController.HealthMultiplierPerRound = 20

EnemyController.BaseSpeed = 1.0
EnemyController.SpeedMultiplier = 0.2
EnemyController.TurnSpeed = 90 -- degrees per second

function EnemyController:OnCreate(entity)
    self.Entity = entity
    self.IsWalking = false
    self.PreviewRotationRads = 0.0
    self.Speed = self.BaseSpeed
    -- Reused every frame in OnUpdate so we don't allocate a new Vector3f (a GC object)
    -- per zombie per frame.
    self.moveVec = Vector3f.new(0.0, 0.0, 0.0)

    -- Component handles are stable and safe to cache for the entity's lifetime (they
    -- re-resolve the live component internally), so we fetch them once here instead of
    -- doing a string-keyed GetComponent every frame in OnUpdate.
    self.pathComp = entity:GetComponent("AIPathComponent")
    self.transform = entity:GetComponent("TransformComponent")
    self.controller = entity:GetComponent("CharacterControllerComponent")
    self.animComp = entity:GetComponent("AnimatorComponent")
end

function EnemyController:OnUpdate(entity, delta)
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
    local speed = pathComp.Speed * self.BaseSpeed * self.SpeedMultiplier
    local moveVec = self.moveVec
    moveVec.x = dirX * speed * delta
    moveVec.y = 0.0
    moveVec.z = dirZ * speed * delta

    -- Move using the Character Controller
    controller:Move(moveVec)

    -- Rotate the AI to face the waypoint
    local targetAngle = Math.Atan2(dirX, dirZ)

    -- Smoothly rotate towards the target angle
    local currentAngle = transform.Rotation.y
    local angleDiff = targetAngle - currentAngle
    local maxTurn = Math.Radians(self.TurnSpeed * delta)
    if angleDiff > maxTurn then
        transform.Rotation.y = currentAngle + maxTurn
    elseif angleDiff < -maxTurn then
        transform.Rotation.y = currentAngle - maxTurn
    else
        transform.Rotation.y = targetAngle
    end

    -- Update the walking animation only when the movement state actually changes, so we
    -- avoid redundant SetBool calls every frame.
    local isMoving = Math.Length(controller.MovementVelocity) > 0
    if isMoving ~= self.IsWalking then
        if isMoving then
            self.animComp:SetBool("isWalking", true)
            self.animComp.PlaybackSpeed = self.Speed
        else
            self.animComp:SetBool("isWalking", false)
        end
        self.IsWalking = isMoving
    end
end

function EnemyController:InitializeForRound(roundNum)
    self.Health = self.BaseHealth + ((roundNum - 1) * self.HealthMultiplierPerRound)

    -- Generate random speed between 1.0 and a max number based on the round
    local maxSpeed = self.BaseSpeed + ((roundNum - 1) * self.SpeedMultiplier)
    self.Speed = 1.0 + Math.RandomFloat(0.0, maxSpeed - 1.0)
end

function EnemyController:ApplyDamage(amount)
    self.Health = self.Health - amount
    if self.Health <= 0 then
        self:Die()
    end
end

function EnemyController:Die()
    EventManager.Broadcast("OnEnemyKilled", self.Entity:GetUUID())
    Scene.RemoveEntity(self.Entity)

    -- TODO: Maybe play a death animation or drop loot here
end

return EnemyController