local ZombieSpawner = {}

ZombieSpawner.ZombiePrefab = PrefabRef()

function ZombieSpawner:OnCreate(entity)
    self.SpawnTimer = 0.0
    self.SpawnInterval = 5.0 -- Start with 1 zombie every 5 seconds
    self.MinSpawnInterval = 1.0 -- Cap at 3 zombies per second
    self.SpawnIntervalDecreaseRate = 0.05 -- Decrease spawn interval by this amount every second
    self.SpawnRadius = 3.0 -- Zombies will spawn within this radius around the spawner
end

-- TODO: Need to see why spawned zombies have weird physics and start bouncing going up ramps

function ZombieSpawner:OnUpdate(entity, delta)

    -- Spawn zombies slow at start and faster over time
    self.SpawnTimer = self.SpawnTimer + delta
    if self.SpawnTimer >= self.SpawnInterval then
        self.SpawnTimer = self.SpawnTimer - self.SpawnInterval

        -- Spawn a new zombie at a random position around the spawner
        local spawnPos = entity:GetComponent("TransformComponent").WorldPosition
        local randomOffset = Vector3f.new(
            Math.RandomFloat(-self.SpawnRadius, self.SpawnRadius),
            0.0,
            Math.RandomFloat(-self.SpawnRadius, self.SpawnRadius)
        )

        Log.Info("Spawning zombie [" .. tostring(self.ZombiePrefab) .. "] at position: " .. tostring(spawnPos + randomOffset) .. ". Current Spawn Interval: " .. tostring(self.SpawnInterval))
        local zombieEntity = Scene.InstantiatePrefab(self.ZombiePrefab, spawnPos + randomOffset)
        Log.Info("Zombie spawned with Entity ID: " .. tostring(zombieEntity:GetID()))

        -- Decrease spawn interval to increase difficulty, but never go below the minimum
        self.SpawnInterval = math.max(self.MinSpawnInterval, self.SpawnInterval - self.SpawnIntervalDecreaseRate * delta)
    end
end

return ZombieSpawner