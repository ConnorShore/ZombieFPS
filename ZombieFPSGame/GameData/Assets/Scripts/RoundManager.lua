local RoundManager = {}

local GameState = {
    Intermission = 1,
    Active = 2,
    GameOver = 3
}

RoundManager.SpawnManagerRef = EntityRef()
RoundManager.IntermissionTime = 10.0

function RoundManager:OnCreate(entity)
    self.CurrentState = GameState.Intermission
    self.CurrentRound = 0
    self.StateTimer = self.IntermissionTime
    
    self.ZombiesRemaining = 0

    EventManager.Subscribe("OnEnemyKilled", function(enemyUUID)
        self:OnZombieKilled()
    end)
    
    Log.Info("RoundManager initialized. Waiting to start Round 1.")
end

function RoundManager:OnUpdate(entity, delta)
    if self.CurrentState == GameState.Intermission then
        self:HandleIntermission(delta)
    elseif self.CurrentState == GameState.Active then
        self:HandleActiveRound(delta)
    end
end

function RoundManager:HandleIntermission(delta)
    self.StateTimer = self.StateTimer - delta
    
    if self.StateTimer <= 0 then
        self:StartNextRound()
    end
end

function RoundManager:StartNextRound()
    self.CurrentRound = self.CurrentRound + 1
    self.CurrentState = GameState.Active
    
    -- TODO: Better algorithm for determining how many zombies to spawn each round?
    local zombiesForRound = 10 + (self.CurrentRound * 5)
    self.ZombiesRemaining = zombiesForRound

    Log.Info("Starting Round " .. tostring(self.CurrentRound))
    
    EventManager.Broadcast("OnRoundStarted", self.CurrentRound)

    local spawnManagerEntity = Scene.GetEntityByUUID(self.SpawnManagerRef)
    Log.Info("Found SpawnManager Entity: " .. tostring(spawnManagerEntity))
    if spawnManagerEntity and spawnManagerEntity:IsValid() then
        spawnManagerEntity:GetScriptInstance():StartWave(zombiesForRound)
    end
end

function RoundManager:HandleActiveRound(delta)
    if self.ZombiesRemaining <= 0 then
        self.CurrentState = GameState.Intermission
        self.StateTimer = self.IntermissionTime
        
        -- Broadcast that the round ended!
        EventManager.Broadcast("OnRoundEnded", self.CurrentRound)
    end
end

-- This should be called by the Zombie script when its health reaches 0
function RoundManager:OnZombieKilled()
    if self.CurrentState == GameState.Active then
        self.ZombiesRemaining = self.ZombiesRemaining - 1
    end
end

return RoundManager