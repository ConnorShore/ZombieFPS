local GameManager = {}

function GameManager:OnCreate(entity)
    EventManager.Subscribe("OnGameOver", function()
        self:OnGameOver()
    end)
end

function GameManager:OnUpdate(entity, delta)

end

function GameManager:OnGameOver()
    SceneManager.LoadScene("GameOver")
end

return GameManager