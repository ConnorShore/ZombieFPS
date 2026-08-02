local GameManager = {}

function GameManager:OnCreate(entity)
    EventManager.Subscribe("OnGameOver", function()
        self:OnGameOver()
    end)
end

function GameManager:OnUpdate(entity, delta)

end

function GameManager:OnGameOver()
    Log.Info("Saving game data and transitioning to Game Over scene...")
    SceneManager.LoadScene("GameOver")
end

return GameManager