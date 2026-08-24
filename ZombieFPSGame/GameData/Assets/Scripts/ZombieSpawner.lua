local ZombieSpawner = {}

ZombieSpawner.ZombiePrefab = PrefabRef()

function ZombieSpawner:OnCreate(entity)
    -- Cache our own transform handle (safe for the entity's lifetime; it re-resolves the
    -- live component internally) so each Spawn call doesn't do a string-keyed lookup.
    self.transform = entity:GetComponent("TransformComponent")
end

function ZombieSpawner:Spawn(entity, roundNum)
    if self.ZombiePrefab and self.ZombiePrefab:IsValid() then
        local transform = self.transform
        local spawnPos = transform.WorldPosition
        
        local zombie = Scene.InstantiatePrefab(self.ZombiePrefab, spawnPos)
        
        if zombie and zombie:IsValid() then
            local zombieScript = zombie:GetScriptInstance()
            if zombieScript and zombieScript.InitializeForRound then
                zombieScript:InitializeForRound(roundNum)
            end
        else
            Log.Error("Failed to spawn zombie from prefab.")
            return
        end
            
        EventManager.Broadcast("OnZombieSpawned", zombie:GetUUID())

        -- Optional: Play a cool dirt particle effect or zombie groan sound right here!
    end
end

return ZombieSpawner