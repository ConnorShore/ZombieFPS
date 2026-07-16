local EnemyController = {}

EnemyController.BaseHealth = 50
EnemyController.HealthMultiplierPerRound = 20
EnemyController.TurnSpeed = 90 -- degrees per second

function EnemyController:OnCreate(entity)
    self.Entity = entity
    self.IsWalking = false
    self.PreviewRotationRads = 0.0
end

function EnemyController:OnUpdate(entity, delta)
    local pathComp = entity:GetComponent("AIPathComponent")
    local transform = entity:GetComponent("TransformComponent")
    local controller = entity:GetComponent("CharacterControllerComponent")
    
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
    
    -- Create the movement vector
    local moveVec = Vector3f.new(dirX * pathComp.Speed * delta, 0.0, dirZ * pathComp.Speed * delta)
    
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

    -- Set walking animation if moving, idle if not
    local animComp = entity:GetComponent("AnimatorComponent")
    Log.Info("Animator component exists: " .. tostring(animComp ~= nil))
    local isMoving = Math.Length(controller.MovementVelocity) > 0
    if isMoving and not self.IsWalking then
        Log.Info("Enemy started walking")
        animComp:SetBool("isWalking", true)
        self.IsWalking = true
    elseif not isMoving and self.IsWalking then
        Log.Info("Enemy stopped walking")
        animComp:SetBool("isWalking", false)
        self.IsWalking = false
    end
end

function EnemyController:InitializeForRound(roundNum)
    self.Health = self.BaseHealth + ((roundNum - 1) * self.HealthMultiplierPerRound)
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