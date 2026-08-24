-- Base class for interactables that cost points. Never attached to an entity directly -
-- PickupItem and PickupWeapon inherit from it via Base = "PurchasableItem".
local PurchasableItem = {}
PurchasableItem.Base = "Interactable"

PurchasableItem.Cost = 0

function PurchasableItem:GetInteractionText(entity, playerEntity)
    return self:GetPurchasePrompt()
end

-- Appends the price to whatever prompt the concrete pickup declares. Split out from
-- GetInteractionText so a pickup can override the text yet still fall back to the priced prompt.
function PurchasableItem:GetPurchasePrompt()
    return self.InteractionPrompt .. " [" .. tostring(self.Cost) .. "]"
end

function PurchasableItem:CanInteract(entity, playerEntity)
    return self:CanAfford()
end

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
