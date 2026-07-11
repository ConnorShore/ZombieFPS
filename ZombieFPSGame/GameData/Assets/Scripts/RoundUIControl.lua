local RoundUIControl = {}

function RoundUIControl:OnCreate(entity)
    self.Entity = entity
    
    -- Subscribe to the global events!
    EventManager.Subscribe("OnRoundStarted", function(roundNumber)
        self:StartRound(roundNumber)
    end)

    EventManager.Subscribe("OnRoundEnded", function(roundNumber)
        self:EndRound()
    end)
    
    Log.Info("HUD UI successfully subscribed to Round events.")
end

function RoundUIControl:StartRound(roundNumber)
    -- Assuming your engine has a TextComponent you can modify
    Log.Info("Updating Round Text to: " .. tostring(roundNumber))
    if self.Entity:ContainsComponent("TextComponent") then
        local textComp = self.Entity:GetComponent("TextComponent")
        textComp.Text = tostring(roundNumber)
        textComp.Color = Vector4f.new(1, 0, 0, 1)
    end

    -- TODO: Play a sound
end

function RoundUIControl:EndRound()
    if self.Entity:ContainsComponent("TextComponent") then
        local textComp = self.Entity:GetComponent("TextComponent")
        textComp.Color = Vector4f.new(1, 1, 1, 1)
    end
end

return RoundUIControl