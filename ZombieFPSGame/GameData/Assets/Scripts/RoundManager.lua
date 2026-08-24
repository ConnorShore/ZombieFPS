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
    self.ScoreFile = GameData:Open("CurrentScore")

    self.SpawnManagerEntity = Scene.GetEntityByUUID(self.SpawnManagerRef)

    self.CurrentState = GameState.Intermission
    self.CurrentRound = 0
    self.StateTimer = self.IntermissionTime

    self.ActiveZombies = {}
    self.ZombiesRemaining = 0

    -- The file is read back from disk on open, so clear last run's round before the first one starts.
    self.ScoreFile:SetInt("CurrentRound", 0)

    EventManager.Subscribe("OnZombieSpawned", function(enemyUUID)
        self:OnZombieSpawned(enemyUUID)
    end)
    EventManager.Subscribe("OnEnemyKilled", function(enemyUUID)
        self:OnZombieKilled(enemyUUID)
    end)
    EventManager.Subscribe("OnNukePickup", function()
        self:OnNukePickup()
    end)
    EventManager.Subscribe("OnPlayerDeath", function()
        self:OnPlayerDeath()
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

    self.ScoreFile:SetInt("CurrentRound", self.CurrentRound)
    EventManager.Broadcast("OnRoundStarted", self.CurrentRound)

    if self.SpawnManagerEntity and self.SpawnManagerEntity:IsValid() then
        self.SpawnManagerEntity:GetScriptInstance():StartWave(self.CurrentRound, zombiesForRound)
    end
end

function RoundManager:HandleActiveRound(delta)
    Log.Info("[RoundManager] Handling active round. Zombies remaining: " .. tostring(self.ZombiesRemaining))
    if self.ZombiesRemaining <= 0 then
        self.CurrentState = GameState.Intermission
        self.StateTimer = self.IntermissionTime
        
        -- Broadcast that the round ended!
        EventManager.Broadcast("OnRoundEnded", self.CurrentRound)
    end
end


function RoundManager:OnZombieSpawned(enemyUUID)
    table.insert(self.ActiveZombies, enemyUUID)
    Log.Trace("[RoundManager] Zombie added to active list. ID: " .. tostring(enemyUUID))
end

-- This should be called by the Zombie script when its health reaches 0
function RoundManager:OnZombieKilled(enemyUUID)
    if self.CurrentState == GameState.Active then
        self.ZombiesRemaining = self.ZombiesRemaining - 1
        Log.Trace("[RoundManager] Zombie killed. Remaining zombies: " .. tostring(self.ZombiesRemaining))
    end

    for i, uuid in ipairs(self.ActiveZombies) do
        if uuid == enemyUUID then
            table.remove(self.ActiveZombies, i)
            break
        end
    end
end

function RoundManager:OnNukePickup()
    Log.Trace("[RoundManager] Nuke pickup detected. Removing all active zombies. Active zombies count: " .. tostring(#self.ActiveZombies))
    local numActiveZombies = #self.ActiveZombies
    for _, zombieUUID in ipairs(self.ActiveZombies) do
        Log.Trace("[RoundManager] Removing zombie with ID: " .. tostring(zombieUUID))
        local zombieEntity = Scene.GetEntityByUUID(zombieUUID)
        if zombieEntity and zombieEntity:IsValid() then
            Scene.RemoveEntity(zombieEntity)
        end
    end
    -- Clear the list of active zombies since they are all removed.
    self.ActiveZombies = {}
    self.ZombiesRemaining = self.ZombiesRemaining - numActiveZombies

    -- Pause spawning for 5 seconds
    -- TODO: Need to find better place for this (maybe a pause wave event the round manager can consume so anythinng that needs to pause can do so,
    -- like the spawn manager and the zombie spawners)
    if self.ZombiesRemaining > 0 then
        local spawnManagerEntity = self.SpawnManagerEntity
        if spawnManagerEntity and spawnManagerEntity:IsValid() then
            spawnManagerEntity:GetScriptInstance():PauseWave(5.0)
        end
    end
end

-- TODO: Come up with a better formula for scaling zombies per round
function RoundManager:GetZombiesPerRound(roundNum)
    return self.BaseZombiesPerRound + ((roundNum - 1) * self.ZombieRoundMultiplier)
end

function RoundManager:OnPlayerDeath()
    self.CurrentState = GameState.GameOver
    EventManager.Broadcast("OnGameOver")
end

return RoundManager