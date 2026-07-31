local PlayerController = {}

PlayerController.Health = 100
PlayerController.DamageSound = AudioClipRef()

function PlayerController:OnCreate(entity)
end

function PlayerController:OnUpdate(entity, delta)

end

function PlayerController:TakeDamage(amount)
    EventManager.Broadcast("OnPlayerDamaged", amount)
    
    if self.DamageSound and self.DamageSound:IsValid() then
        AudioSystem.PlayOneShot(self.DamageSound)
    end

    self.Health = self.Health - amount
    if self.Health < 0 then
        self.Health = 0
    end
    if self.Health == 0 then
        EventManager.Broadcast("OnPlayerDeath", true)
    end
end

return PlayerController