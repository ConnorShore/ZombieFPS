local RoundUIControl = {}

function RoundUIControl:OnCreate(entity)
    self.Entity = entity
    
    EventManager.Subscribe("OnRoundStarted", function(roundNumber)
        self:StartRound(roundNumber)
    end)

    EventManager.Subscribe("OnRoundEnded", function(roundNumber)
        self:EndRound()
    end)
end

function RoundUIControl:StartRound(roundNumber)
    if self.Entity:ContainsComponent("TextComponent") then
        local textComp = self.Entity:GetComponent("TextComponent")
        textComp.Text = tostring(roundNumber)
        textComp.Color = Vector4f.new(1, 0, 0, 1)
    end

    -- TODO: Play a sound
end

function RoundUIControl:EndRound()
    -- TODO: Animate the round number fading out or something fancy like that instead of just changing the text and color back to white
    if self.Entity:ContainsComponent("TextComponent") then
        local textComp = self.Entity:GetComponent("TextComponent")
        textComp.Color = Vector4f.new(1, 1, 1, 1)
    end

    -- TODO: Play a sound
end

return RoundUIControl