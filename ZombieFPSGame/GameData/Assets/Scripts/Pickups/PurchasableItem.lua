-- Base class for pickups that cost points to collect. Never attached to an entity directly -
-- PickupItem and PickupWeapon inherit from it via Base = "PurchasableItem".
local PurchasableItem = {}

PurchasableItem.Cost = 0

function PurchasableItem:CanAfford()
    Log.Trace("PurchasableItem:CanAfford - Checking if player can afford item with cost " .. self.Cost)
    if _G.PointManager == nil then
        Log.Warn("PurchasableItem:CanAfford - PointManager is not available in the global scope! Cannot determine if player can afford item.")
        return false
    end

    Log.Trace("PurchasableItem:CanAfford - Player has " .. _G.PointManager.Points .. " points available.")
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
