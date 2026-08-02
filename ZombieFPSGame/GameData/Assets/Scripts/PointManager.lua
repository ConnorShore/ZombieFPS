local PointManager = {}

PointManager.StartingPoints = 100
PointManager.EnemyHitPoints = 10
PointManager.EnemyKillPoints = 50
PointManager.EnemyHeadshotMultiplier = 2.0

function PointManager:OnCreate(entity)
    -- Cached for the whole run; the Game Over scene reads this same file back.
    self.ScoreFile = GameData:Open("CurrentScore")

    self.Points = self.StartingPoints
    self.ScoreFile:SetInt("CurrentPlayerPoints", self.Points)

    EventManager.Subscribe("OnEnemyHit", function()
        self:AwardPointsForHit()
    end)

    EventManager.Subscribe("OnEnemyKilled", function(isHeadshot)
        if isHeadshot then
            self:AwardPointsForHeadshotKill()
        else
            self:AwardPointsForKill()
        end
    end)

    EventManager.Subscribe("OnItemPurchased", function(itemCost)
        self:OnItemPurchased(itemCost)
    end)
end

function PointManager:OnUpdate(entity, delta)

end

function PointManager:AwardPointsForHit()
    self.Points = self.Points + self.EnemyHitPoints
    self:OnPointsChanged(self.Points)
end

function PointManager:AwardPointsForKill()
    self.Points = self.Points + self.EnemyKillPoints
    self:OnPointsChanged(self.Points)
end

function PointManager:AwardPointsForHeadshotKill()
    self.Points = self.Points + math.tointeger(self.EnemyKillPoints * self.EnemyHeadshotMultiplier)
    self:OnPointsChanged(self.Points)
end

function PointManager:OnItemPurchased(itemCost)
    self.Points = self.Points - itemCost
    self:OnPointsChanged(self.Points)
end

function PointManager:OnPointsChanged(newPoints)
    self.ScoreFile:SetInt("CurrentPlayerPoints", newPoints)

    EventManager.Broadcast("OnPointsChanged", newPoints)
end

return PointManager