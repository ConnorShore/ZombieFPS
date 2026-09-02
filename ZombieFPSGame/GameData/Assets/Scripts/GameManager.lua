local GameManager = {}

local PlayState = {
    Running = 1,
    Paused = 2,
}

function GameManager:OnCreate(entity)
    self.CurrentPlayState = PlayState.Running

    EventManager.Subscribe("OnGameOver", function()
        self:OnGameOver()
    end)
    EventManager.Subscribe("OnPause", function()
        self:OnPause()
    end)
    EventManager.Subscribe("OnResume", function()
        self:OnResume()
    end)
end

function GameManager:OnUpdate(entity, delta)
    -- See if pause button was pressed
    if Input.IsActionPressed("Pause") then
        if self.CurrentPlayState == PlayState.Running then
            EventManager.Broadcast("OnPause")
        elseif self.CurrentPlayState == PlayState.Paused then
            EventManager.Broadcast("OnResume")
        end
        Input.ConsumeAction("Pause")
    end

    if self.CurrentPlayState == PlayState.Paused then
        -- Check if exit button was pressed while paused and resume
        if Input.IsActionPressed("NavBack") then
            EventManager.Broadcast("OnResume")
            Input.ConsumeAction("NavBack")
        end
    end
end

function GameManager:OnPause()
    Log.Info("GameManager: Game paused.")
    self.CurrentPlayState = PlayState.Paused
    Scene.SetPaused(true)
    Input.SetCursorMode(CursorMode.Normal)
end

function GameManager:OnResume()
    Log.Info("GameManager: Game resumed.")
    self.CurrentPlayState = PlayState.Running
    Scene.SetPaused(false)
    Input.SetCursorMode(CursorMode.Locked)
end

function GameManager:OnGameOver()
    Log.Info("Saving game data and transitioning to Game Over scene...")
    SceneManager.LoadScene("GameOver")
end

return GameManager