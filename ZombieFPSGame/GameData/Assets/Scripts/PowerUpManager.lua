local PowerUpManager = {}

PowerUpManager.SpawnHeight = 1.0 -- Height at which the power-up spawns in the world
PowerUpManager.MoveSpeed = 2.0 -- Speed at which the power-up moves up and down
PowerUpManager.MoveDistance = 0.2 -- Distance the power-up moves up and down
PowerUpManager.RotationSpeed = 45.0 -- Speed at which the power-up rotates

PowerUpManager.PowerUpDuration = 10.0 -- Duration of the power-up effect in seconds

PowerUpManager.BaseSpawnChance = 0.1 -- Base chance for a power-up to spawn after a zombie is killed
-- Populated in the Inspector: click + and drag a power-up prefab onto each slot
PowerUpManager.PowerUpPrefabs = PrefabRefArray()

-- TODO: Eventually associate a spawn percentage with each powerup type
-- TODO: Eventually change spawn chance based on the current round or other factors

function PowerUpManager:OnCreate(entity)
    self.SpawnChance = self.BaseSpawnChance

    -- Drop empty Inspector slots up front so a half-filled list can't roll a failed spawn
    self.PowerUpPool = {}
    for _, prefab in ipairs(self.PowerUpPrefabs) do
        if prefab:IsValid() then
            table.insert(self.PowerUpPool, prefab)
        end
    end

    if #self.PowerUpPool == 0 then
        Log.Warn("PowerUpManager has no power-up prefabs assigned - nothing will spawn.")
    end

    EventManager.Subscribe("OnEnemyKilled", function(enemyUUID)
        local enemyEntity = Scene.GetEntityByUUID(enemyUUID)
        if enemyEntity:IsValid() then
            self:TrySpawnPowerUp(enemyEntity)
        else
            Log.Warn("OnEnemyKilled event received with invalid enemy UUID: " .. tostring(enemyUUID))
        end
    end)
end

function PowerUpManager:OnUpdate(entity, delta)

end

function PowerUpManager:TrySpawnPowerUp(zombieEntity)
    if #self.PowerUpPool == 0 then
        return
    end

    if Math.RandomFloat(0.0, 1.0) <= self.SpawnChance then
        local transform = zombieEntity:GetComponent("TransformComponent")

        -- Get ground height and adjust spawn position accordingly
        local groundHeight = 0.0
        local raycastResult = Physics.CastRay(transform.WorldPosition, Vector3f.new(0.0, -1.0, 0.0), 10.0, CollisionFilter.Environment)
        if raycastResult.Hit then
            groundHeight = raycastResult.CollisionPoint.y
            Log.Trace("PowerUpManager: Ground height detected at " .. groundHeight .. " for zombie entity: " .. zombieEntity:GetName())
        else
            Log.Trace("PowerUpManager: No ground detected for zombie entity: " .. zombieEntity:GetName())
        end

        local spawnPosition = Vector3f.new(transform.WorldPosition.x, groundHeight + self.SpawnHeight, transform.WorldPosition.z)
        local powerUpPrefab = self.PowerUpPool[Math.RandomInt(1, #self.PowerUpPool)]

        -- Spawn the power-up entity in the scene
        local powerUpEntity = Scene.InstantiatePrefab(powerUpPrefab, spawnPosition)
        if not powerUpEntity:IsValid() then
            Log.Warn("Failed to instantiate power-up prefab.")
            return
        end

        -- Set the power-up's movement and rotation properties
        local powerUpScript = powerUpEntity:GetScriptInstance()
        if powerUpScript then
            powerUpScript.MoveSpeed = self.MoveSpeed
            powerUpScript.MoveDistance = self.MoveDistance
            powerUpScript.RotationSpeed = self.RotationSpeed
        else
            Log.Warn("Failed to get script instance for spawned power-up entity: " .. powerUpEntity:GetName())
        end
    end
end

return PowerUpManager