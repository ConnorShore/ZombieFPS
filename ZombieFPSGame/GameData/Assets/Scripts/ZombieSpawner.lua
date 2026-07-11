local ZombieSpawner = {}

ZombieSpawner.ZombiePrefab = PrefabRef()

function ZombieSpawner:OnCreate(entity)
end

function ZombieSpawner:Spawn(entity)
    if self.ZombiePrefab and self.ZombiePrefab:IsValid() then
        -- 1. Get the exact world position of this specific spawner
        local transform = entity:GetComponent("TransformComponent")
        local spawnPos = transform.WorldPosition
        
        -- 2. Spawn the zombie (or retrieve it from a pool)
        Scene.InstantiatePrefab(self.ZombiePrefab, spawnPos)
        
        -- Optional: Play a cool dirt particle effect or zombie groan sound right here!
        Log.Info("Spawned zombie at " .. tostring(spawnPos))
    end
end

return ZombieSpawner