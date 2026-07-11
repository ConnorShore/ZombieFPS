local RoundManager = {}

local GameState = {
    Intermission = 1,
    Active = 2,
    GameOver = 3
}

RoundManager.SpawnManagerRef = EntityRef()
RoundManager.IntermissionTime = 10.0
RoundManager.BaseZombiesPerRound = 5
RoundManager.ZombieRoundMultiplier = 4

function RoundManager:OnCreate(entity)
    self.CurrentState = GameState.Intermission
    self.CurrentRound = 0
    self.StateTimer = self.IntermissionTime
    
    self.ZombiesRemaining = 0

    EventManager.Subscribe("OnEnemyKilled", function(enemyUUID)
        self:OnZombieKilled()
    end)
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
    
    local zombiesForRound = self:GetZombiesPerRound(self.CurrentRound)
    self.ZombiesRemaining = zombiesForRound

    EventManager.Broadcast("OnRoundStarted", self.CurrentRound)

    local spawnManagerEntity = Scene.GetEntityByUUID(self.SpawnManagerRef)
    if spawnManagerEntity and spawnManagerEntity:IsValid() then
        spawnManagerEntity:GetScriptInstance():StartWave(self.CurrentRound, zombiesForRound)
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

-- TODO: Come up with a better formula for scaling zombies per round
function RoundManager:GetZombiesPerRound(roundNum)
    return self.BaseZombiesPerRound + ((roundNum - 1) * self.ZombieRoundMultiplier)
end

return RoundManager