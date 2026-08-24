local PointManager = {}

PointManager.StartingPoints = 100
PointManager.EnemyHitPoints = 10
PointManager.EnemyKillPoints = 50
PointManager.EnemyHeadshotMultiplier = 2.0

PointManager.NukePickupPoints = 300

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
        self:AwardPoints(self.EnemyHitPoints)
    end)

    EventManager.Subscribe("OnEnemyKilled", function(enemyUUID)
        self:AwardPoints(self.EnemyKillPoints)
    end)

    EventManager.Subscribe("OnNukePickup", function()
        self:AwardPoints(self.NukePickupPoints)
    end)

    EventManager.Subscribe("OnEnemyHeadshotKill", function(enemyUUID)
        self:AwardPoints(math.tointeger(self.EnemyKillPoints * self.EnemyHeadshotMultiplier))
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

function PointManager:AwardPoints(points)
    self.Points = self.Points + points
    self.TotalPointsEarned = self.TotalPointsEarned + points
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