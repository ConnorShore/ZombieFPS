local RoundManager = {}

function RoundManager:OnCreate(entity)
    self.CurrentRound = 1
    self.StateTimer = 0.0 -- Time until the next round starts, for testing
    self.RoundActive = false
end

function RoundManager:OnUpdate(entity, delta)
    -- For testing, start and end round every 3 seconds
    self.StateTimer = self.StateTimer + delta
    if self.RoundActive and self.StateTimer >= 3.0 then
        self:EndCurrentRound(delta)
        self.RoundActive = false
        self.StateTimer = 0.0
    elseif not self.RoundActive and self.StateTimer >= 3.0 then
        self:StartNextRound()
        self.RoundActive = true
        self.StateTimer = 0.0
        self.CurrentRound = self.CurrentRound + 1
    end
end

function RoundManager:StartNextRound()
    Log.Info("Starting Round " .. tostring(self.CurrentRound))
    
    -- 1. Broadcast that the intermission is over and the round is active
    EventManager.Broadcast("OnRoundStarted", self.CurrentRound)
end

function RoundManager:EndCurrentRound(delta)
    Log.Info("Ending Round " .. tostring(self.CurrentRound))
    EventManager.Broadcast("OnRoundEnded", self.CurrentRound)
end

return RoundManager