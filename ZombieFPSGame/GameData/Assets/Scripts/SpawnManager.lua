local SpawnManager = {}

SpawnManager.MaxConcurrentZombies = 24 -- CoD standard limit for active zombies on the map
SpawnManager.SpawnInterval = 2.0 -- Seconds between spawns

function SpawnManager:OnCreate(entity)
    self.TimeSinceLastSpawn = 0.0
    self.ZombiesSpawned = 0
    self.TotalZombiesForWave = 0
    self.ActiveZombies = 0
    self.IsWaveActive = false
    self.SpawnerUUIDs = {}

    -- Automatically find all child entities (Spawners) attached to this Manager
    if entity:ContainsComponent("RelationshipComponent") then
        local relComp = entity:GetComponent("RelationshipComponent")
        Log.Info("HERE")
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

    Log.Info("SpawnManager initialized with " .. tostring(#self.SpawnerUUIDs) .. " spawners.")
end

-- Called by the RoundManager when intermission ends
function SpawnManager:StartWave(totalZombies)
    self.TotalZombiesForWave = totalZombies
    self.ZombiesSpawned = 0
    self.ActiveZombies = 0
    self.TimeSinceLastSpawn = 0.0
    self.IsWaveActive = true
    Log.Info("SpawnManager instructed to spawn " .. tostring(totalZombies) .. " zombies this wave.")
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
            spawnerScript:Spawn(spawnerEntity)
            
            -- Keep track of our numbers!
            self.ZombiesSpawned = self.ZombiesSpawned + 1
            self.ActiveZombies = self.ActiveZombies + 1
        else
            Log.Error("Child entity '" .. spawnerEntity:GetName() .. "' is missing a Spawner script!")
        end
    end
end

return SpawnManager