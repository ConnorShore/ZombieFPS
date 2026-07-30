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
    self.Spawners = {}
    self.RoundNum = 1

    -- Automatically find all child entities (Spawners) attached to this Manager
    if entity:ContainsComponent("RelationshipComponent") then
        local relComp = entity:GetComponent("RelationshipComponent")
        for i, childUUID in ipairs(relComp.Children) do
            local spawnerEntity = Scene.GetEntityByUUID(childUUID)
            if spawnerEntity and spawnerEntity:IsValid() then
                table.insert(self.Spawners, spawnerEntity)
            end
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
    if #self.Spawners == 0 then
        Log.Warn("SpawnManager cannot spawn: No child spawners found!")
        return
    end

    local randomIndex = Math.RandomInt(1, #self.Spawners)
    local spawnerEntity = self.Spawners[randomIndex]
    if spawnerEntity and spawnerEntity:IsValid() then
        local spawnerScript = spawnerEntity:GetScriptInstance()
        if spawnerScript and spawnerScript.Spawn then
            spawnerScript:Spawn(spawnerEntity, self.RoundNum)

            self.ZombiesSpawned = self.ZombiesSpawned + 1
            self.ActiveZombies = self.ActiveZombies + 1
        else
            Log.Error("Child entity '" .. spawnerEntity:GetName() .. "' is missing a Spawner script!")
        end
    else
        Log.Error("SpawnManager picked an invalid spawner entity at index: " .. tostring(randomIndex))
    end
end

return SpawnManager