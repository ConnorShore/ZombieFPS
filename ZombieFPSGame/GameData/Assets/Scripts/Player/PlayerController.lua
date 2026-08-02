local PlayerController = {}

PlayerController.MaxHealth = 100
PlayerController.HealthRegenerationRate = 10.0 -- Health points regenerated per second
PlayerController.HealthRegenerationDelay = 5.0 -- Delay in seconds before health regeneration starts after taking damage
PlayerController.DamageSound = AudioClipRef()

function PlayerController:OnCreate(entity)
    self.Health = self.MaxHealth
    self.LastDamageTime = 0.0
end

function PlayerController:OnUpdate(entity, delta)
    -- Health regeneration logic
    if self.Health < self.MaxHealth then
        self.LastDamageTime = self.LastDamageTime + delta
        if self.LastDamageTime >= self.HealthRegenerationDelay then
            self.Health = Math.Min(self.Health + self.HealthRegenerationRate * delta, self.MaxHealth)
            EventManager.Broadcast("OnPlayerHealthPercentChanged", self.Health / self.MaxHealth)
        end
    else
        self.LastDamageTime = 0.0
    end
end

function PlayerController:TakeDamage(amount)
    self.LastDamageTime = 0.0 -- Reset the damage timer for health regeneration
    
    if self.DamageSound and self.DamageSound:IsValid() then
        AudioSystem.PlayOneShot(self.DamageSound)
    end

    self.Health = self.Health - amount
    EventManager.Broadcast("OnPlayerHealthPercentChanged", self.Health / self.MaxHealth)
    
    if self.Health < 0 then
        self.Health = 0
    end
    if self.Health == 0 then
        EventManager.Broadcast("OnPlayerDeath", true)
    end
end

return PlayerController