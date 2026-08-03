local PointManager = {}

PointManager.StartingPoints = 100
PointManager.EnemyHitPoints = 10
PointManager.EnemyKillPoints = 50
PointManager.EnemyHeadshotMultiplier = 2.0

function PointManager:OnCreate(entity)
    -- Published so PurchasableItem (and anything else) can read the live point total without
    -- needing an EntityRef back to whichever entity carries this script.
    _G.PointManager = self

    -- Cached for the whole run; the Game Over scene reads this same file back.
    self.ScoreFile = GameData:Open("CurrentScore")

    self.TotalPointsEarned = self.StartingPoints
    self.Points = self.StartingPoints
    self.ScoreFile:SetInt("CurrentPlayerPoints", self.TotalPointsEarned)

    EventManager.Subscribe("OnEnemyHit", function()
        self:AwardPointsForHit()
    end)

    EventManager.Subscribe("OnEnemyKilled", function(enemyUUID)
        self:AwardPointsForKill()
    end)

    EventManager.Subscribe("OnEnemyHeadshotKill", function(enemyUUID)
        self:AwardPointsForHeadshotKill()
    end)

    EventManager.Subscribe("OnItemPurchased", function(itemCost)
        self:OnItemPurchased(itemCost)
    end)

    EventManager.Subscribe("OnGameOver", function()
        self.ScoreFile:SetInt("CurrentPlayerPoints", self.TotalPointsEarned)
        self.ScoreFile:Save()
    end)
end

function PointManager:OnUpdate(entity, delta)

end

function PointManager:AwardPointsForHit()
    self.Points = self.Points + self.EnemyHitPoints
    self.TotalPointsEarned = self.TotalPointsEarned + self.EnemyHitPoints
    self:OnPointsChanged(self.Points)
end

function PointManager:AwardPointsForKill()
    self.Points = self.Points + self.EnemyKillPoints
    self.TotalPointsEarned = self.TotalPointsEarned + self.EnemyKillPoints
    self:OnPointsChanged(self.Points)
end

function PointManager:AwardPointsForHeadshotKill()
    local pointsAwarded = math.tointeger(self.EnemyKillPoints * self.EnemyHeadshotMultiplier)
    self.Points = self.Points + pointsAwarded
    self.TotalPointsEarned = self.TotalPointsEarned + pointsAwarded
    self:OnPointsChanged(self.Points)
end

function PointManager:OnItemPurchased(itemCost)
    self.Points = self.Points - itemCost
    self:OnPointsChanged(self.Points)
end

function PointManager:OnPointsChanged(newPoints)
    EventManager.Broadcast("OnPointsChanged", newPoints)
end

return PointManager