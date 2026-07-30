local RoundAudioManager = {}

RoundAudioManager.RoundStartSound = AudioClipRef()
RoundAudioManager.RoundEndSound = AudioClipRef()
RoundAudioManager.PlayerDeathSound = AudioClipRef()

function RoundAudioManager:OnCreate(entity)
    self.Entity = entity
    
    EventManager.Subscribe("OnRoundStarted", function(roundNumber)
        self:PlayStartRoundSound()
    end)

    EventManager.Subscribe("OnRoundEnded", function(roundNumber)
        self:PlayEndRoundSound()
    end)

    EventManager.Subscribe("OnPlayerDeath", function(isDead)
        if isDead then
            self:PlayPlayerDeathSound()
        end
    end)
end

function RoundAudioManager:PlayStartRoundSound()
    if self.RoundStartSound and self.RoundStartSound:IsValid() then
        AudioSystem.PlayOneShot(self.RoundStartSound)
    end
end

function RoundAudioManager:PlayEndRoundSound()
    if self.RoundEndSound and self.RoundEndSound:IsValid() then
        AudioSystem.PlayOneShot(self.RoundEndSound)
    end
end

function RoundAudioManager:PlayPlayerDeathSound()
    if self.PlayerDeathSound and self.PlayerDeathSound:IsValid() then
        AudioSystem.PlayOneShot(self.PlayerDeathSound)
    end
end

return RoundAudioManager