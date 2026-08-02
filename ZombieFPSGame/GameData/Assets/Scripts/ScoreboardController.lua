local ScoreboardController = {}

ScoreboardController.CurrentRoundRef = EntityRef()
ScoreboardController.CurrentScoreRef = EntityRef()

ScoreboardController.TopRoundRef = EntityRef()
ScoreboardController.TopScoreRef = EntityRef()

ScoreboardController.NewHighscoreRef = EntityRef()

function ScoreboardController:OnCreate(entity)
    self.CurrentRoundEntity = Scene.GetEntityByUUID(self.CurrentRoundRef)
    self.CurrentScoreEntity = Scene.GetEntityByUUID(self.CurrentScoreRef)

    self.TopRoundEntity = Scene.GetEntityByUUID(self.TopRoundRef)
    self.TopScoreEntity = Scene.GetEntityByUUID(self.TopScoreRef)

    self.NewHighscoreEntity = Scene.GetEntityByUUID(self.NewHighscoreRef)

    if not self.CurrentRoundEntity:IsValid() then
        Log.Warn("Cannot find CurrentRound entity in scene! Current round will not be displayed.")
    end

    if not self.CurrentScoreEntity:IsValid() then
        Log.Warn("Cannot find CurrentScore entity in scene! Current score will not be displayed.")
    end

    if not self.TopRoundEntity:IsValid() then
        Log.Warn("Cannot find TopRound entity in scene! Top round will not be displayed.")
    end

    if not self.TopScoreEntity:IsValid() then
        Log.Warn("Cannot find TopScore entity in scene! Top score will not be displayed.")
    end

    if not self.NewHighscoreEntity:IsValid() then
        Log.Warn("Cannot find NewHighscore entity in scene! New highscore notification will not be displayed.")
    end

    -- The run's score and the all-time best live in separate files so both can be open at once.
    local runFile = GameData:Open("CurrentScore")
    local bestFile = GameData:Open("TopScore")

    local currentRound = runFile:GetInt("CurrentRound", 0)
    local currentScore = runFile:GetInt("CurrentPlayerPoints", 0)
    local topRound = bestFile:GetInt("TopRound", 0)
    local topScore = bestFile:GetInt("TopPlayerPoints", 0)

    -- Update the scoreboard display
    local newHighscore = false
    if currentRound > topRound then
        topRound = currentRound
        newHighscore = true
    end
    if currentScore > topScore then
        topScore = currentScore
        newHighscore = true
    end

    -- The new best used to be worked out and then dropped - nothing wrote TopScore, so the top row
    -- came back as 0 on every launch.
    if newHighscore then
        bestFile:SetInt("TopRound", topRound)
        bestFile:SetInt("TopPlayerPoints", topScore)
        bestFile:Save()
    end

    self:ShowNewHighscore(newHighscore)
    self:UpdateScoreboard(currentRound, currentScore, topRound, topScore)
end

function ScoreboardController:OnUpdate(entity, delta)

end

function ScoreboardController:UpdateScoreboard(currentRound, currentScore, topRound, topScore)
    if self.CurrentRoundEntity and self.CurrentRoundEntity:IsValid() then
        local textComponent = self.CurrentRoundEntity:GetComponent("TextComponent")
        if textComponent then
            textComponent.Text = "Round: " .. tostring(currentRound)
        end
    end

    if self.CurrentScoreEntity and self.CurrentScoreEntity:IsValid() then
        local textComponent = self.CurrentScoreEntity:GetComponent("TextComponent")
        if textComponent then
            textComponent.Text = "Score: " .. tostring(currentScore)
        end
    end

    if self.TopRoundEntity and self.TopRoundEntity:IsValid() then
        local textComponent = self.TopRoundEntity:GetComponent("TextComponent")
        if textComponent then
            textComponent.Text = "Top Round: " .. tostring(topRound)
        end
    end

    if self.TopScoreEntity and self.TopScoreEntity:IsValid() then
        local textComponent = self.TopScoreEntity:GetComponent("TextComponent")
        if textComponent then
            textComponent.Text = "Top Score: " .. tostring(topScore)
        end
    end
end

function ScoreboardController:ShowNewHighscore(showHighscore)
    if self.NewHighscoreEntity and self.NewHighscoreEntity:IsValid() then
        -- Enable the NewHighscore entity to show the notification
        if showHighscore then
            self.NewHighscoreEntity:SetActive(true)
        else
            self.NewHighscoreEntity:SetActive(false)
        end
    end
end

return ScoreboardController