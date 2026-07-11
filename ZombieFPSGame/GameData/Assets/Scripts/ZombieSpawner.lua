local ZombieSpawner = {}

ZombieSpawner.ZombiePrefab = PrefabRef()

function ZombieSpawner:OnCreate(entity)
end

function ZombieSpawner:Spawn(entity, roundNum)
    if self.ZombiePrefab and self.ZombiePrefab:IsValid() then
        local transform = entity:GetComponent("TransformComponent")
        local spawnPos = transform.WorldPosition
        
        local zombie = Scene.InstantiatePrefab(self.ZombiePrefab, spawnPos)
        
        if zombie and zombie:IsValid() then
            local zombieScript = zombie:GetScriptInstance()
            if zombieScript and zombieScript.InitializeForRound then
                zombieScript:InitializeForRound(roundNum)
            end
        end

        -- Optional: Play a cool dirt particle effect or zombie groan sound right here!
    end
end

return ZombieSpawner