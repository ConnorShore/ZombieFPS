local SpawnManager = {}

SpawnManager.MaxConcurrentZombies = 24 -- CoD standard limit for active zombies on the map
SpawnManager.BaseSpawnInterval = 3.0 -- Seconds between spawns
SpawnManager.MinSpawnInterval = 0.5 -- Minimum seconds between spawns at higher rounds
SpawnManager.SpawnIntervalDecreasePerRound = 0.05 -- Percentage decrease in spawn interval per round (5% decrease each round)

function SpawnManager:OnCreate(entity)
    self.TimeSinceLastSpawn = 0.0
    self.ZombiesSpawned = 0
    self.TotalZombiesForWave = 0
    self.ActiveZombies = 0
    self.IsWaveActive = false
    self.SpawnInterval = self.BaseSpawnInterval
    self.SpawnerUUIDs = {}
    self.RoundNum = 1

    -- Automatically find all child entities (Spawners) attached to this Manager
    if entity:ContainsComponent("RelationshipComponent") then
        local relComp = entity:GetComponent("RelationshipComponent")
        Log.Info("SpawnManager found " .. tostring(#relComp.Children) .. " child spawners.")
        for i, childUUID in ipairs(relComp.Children) do
            table.insert(self.SpawnerUUIDs, childUUID)
        end
    end

    -- Listen for zombie deaths to free up our concurrent spawn slots!
    EventManager.Subscribe("OnEnemyKilled", function(enemyUUID)
        if self.ActiveZombies > 0 then
            self.ActiveZombies = self.ActiveZombies - 1
        end
    end)
end

-- Called by the RoundManager when intermission ends
function SpawnManager:StartWave(roundNum, totalZombies)
    self.TotalZombiesForWave = totalZombies
    self.ZombiesSpawned = 0
    self.ActiveZombies = 0
    self.TimeSinceLastSpawn = 0.0
    self.IsWaveActive = true
    self.RoundNum = roundNum
    self.SpawnInterval = math.max(self.MinSpawnInterval, self.BaseSpawnInterval * (1.0 - (roundNum * self.SpawnIntervalDecreasePerRound))) -- Decrease spawn interval by 5% each round, down to a minimum of MinSpawnInterval
end

function SpawnManager:OnUpdate(entity, delta)
    -- Don't do anything if we are in intermission or finished our quota
    if not self.IsWaveActive then return end

    -- Stop spawning if we've hit the total wave cap
    if self.ZombiesSpawned >= self.TotalZombiesForWave then
        self.IsWaveActive = false
        return 
    end

    self.TimeSinceLastSpawn = self.TimeSinceLastSpawn + delta

    -- Time to spawn! Check concurrency limits first.
    if self.TimeSinceLastSpawn >= self.SpawnInterval then
        if self.ActiveZombies < self.MaxConcurrentZombies then
            self.TimeSinceLastSpawn = 0.0
            self:TriggerRandomSpawner()
        end
    end
end

function SpawnManager:TriggerRandomSpawner()
    if #self.SpawnerUUIDs == 0 then
        Log.Warn("SpawnManager cannot spawn: No child spawners found!")
        return
    end

    -- 1. Pick a random spawner from our list of children
    local randomIndex = Math.RandomInt(1, #self.SpawnerUUIDs)
    local spawnerUUID = self.SpawnerUUIDs[randomIndex]
    
    local spawnerEntity = Scene.GetEntityByUUID(spawnerUUID)

    if spawnerEntity and spawnerEntity:IsValid() then
        -- 2. Call the spawn function on the chosen child's script
        local spawnerScript = spawnerEntity:GetScriptInstance()
        if spawnerScript and spawnerScript.Spawn then
            spawnerScript:Spawn(spawnerEntity, self.RoundNum)
            
            -- Keep track of our numbers!
            self.ZombiesSpawned = self.ZombiesSpawned + 1
            self.ActiveZombies = self.ActiveZombies + 1
        else
            Log.Error("Child entity '" .. spawnerEntity:GetName() .. "' is missing a Spawner script!")
        end
    end
end

return SpawnManager