local RoundUIControl = {}

function RoundUIControl:OnCreate(entity)
    self.Entity = entity

    -- Component handles are safe to cache for the entity's lifetime (they re-resolve the
    -- live component internally), so fetch it once here instead of on every round event.
    if entity:ContainsComponent("TextComponent") then
        self.textComp = entity:GetComponent("TextComponent")
    end

    EventManager.Subscribe("OnRoundStarted", function(roundNumber)
        self:StartRound(roundNumber)
    end)

    EventManager.Subscribe("OnRoundEnded", function(roundNumber)
        self:EndRound()
    end)
end

function RoundUIControl:StartRound(roundNumber)
    if self.textComp then
        local textComp = self.textComp
        textComp.Text = tostring(roundNumber)
        textComp.Color = Vector4f.new(1, 0, 0, 1)
    end

    -- TODO: Play a sound
end

function RoundUIControl:EndRound()
    -- TODO: Animate the round number fading out or something fancy like that instead of just changing the text and color back to white
    if self.textComp then
        local textComp = self.textComp
        textComp.Color = Vector4f.new(1, 1, 1, 1)
    end

    -- TODO: Play a sound
end

return RoundUIControl