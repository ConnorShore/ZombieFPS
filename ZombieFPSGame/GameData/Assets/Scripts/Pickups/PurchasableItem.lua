-- Base class for pickups that cost points to collect. Never attached to an entity directly -
-- PickupItem and PickupWeapon inherit from it via Base = "PurchasableItem".
local PurchasableItem = {}

PurchasableItem.Cost = 0

function PurchasableItem:CanAfford()
    if _G.PointManager == nil then
        return false
    end

    return _G.PointManager ~= nil and _G.PointManager.Points >= self.Cost
end

-- Deducts Cost and broadcasts OnItemPurchased (which PointManager already listens for) if the
-- player can afford it. Returns false without side effects if they can't.
function PurchasableItem:TryPurchase()
    if not self:CanAfford() then
        return false
    end

    EventManager.Broadcast("OnItemPurchased", self.Cost)
    return true
end

return PurchasableItem
