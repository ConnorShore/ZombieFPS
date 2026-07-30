local PlayerController = {}

PlayerController.Health = 100

function PlayerController:OnCreate(entity)
end

function PlayerController:OnUpdate(entity, delta)

end

function PlayerController:TakeDamage(amount)
    self.Health = self.Health - amount
    if self.Health < 0 then
        self.Health = 0
    end
    if self.Health == 0 then
        EventManager.Broadcast("OnPlayerDeath", true)
    end
end

return PlayerController