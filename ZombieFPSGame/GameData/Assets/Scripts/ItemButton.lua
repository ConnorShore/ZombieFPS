local ItemButton = {}

local AffordableTint = {
    Normal      = Vector4f.new(0.0, 1.0, 0.0, 0.75),
    Highlighted = Vector4f.new(0.35, 1.0, 0.35, 0.9),
    Pressed     = Vector4f.new(0.0, 0.7, 0.0, 1.0)
}

local UnaffordableTint = {
    Normal      = Vector4f.new(1.0, 0.0, 0.0, 0.75),
    Highlighted = Vector4f.new(1.0, 0.35, 0.35, 0.9),
    Pressed     = Vector4f.new(0.7, 0.0, 0.0, 1.0)
}

function ItemButton:OnCreate(entity)
    self.PointManager = _G.PointManager
    self.CanAfford = false
    self.TintApplied = nil  -- nil rather than false so the first update always pushes a palette
end

-- Item data (name/price/prefab) lives on the parent entity's ShopItem script.
function ItemButton:GetShopItem(entity)
    local shopItem = entity:GetParent():GetScriptInstance("ShopItem")
    if not shopItem then
        Log.Warn("ItemButton: parent entity does not have a ShopItem script instance!")
    end
    return shopItem
end

-- Pushes one palette onto the selectable; UIInputSystem drives the hover/press tinting from there.
function ItemButton:ApplyTint(entity, canAfford)
    local selectable = entity:GetComponent("UISelectableComponent")
    if not selectable then
        Log.Warn("ItemButton: UISelectableComponent is not available on the entity!")
        return
    end

    local tint = canAfford and AffordableTint or UnaffordableTint
    selectable.NormalColor = tint.Normal
    selectable.HighlightedColor = tint.Highlighted
    selectable.PressedColor = tint.Pressed
    selectable.SelectedColor = tint.Highlighted
    selectable.DisabledColor = tint.Normal

    -- An unaffordable button stays interactable so it still hovers red; OnClick rejects the buy.
    selectable.Interactable = true

    self.TintApplied = canAfford
end

function ItemButton:OnUpdate(entity, delta)
    if not self.PointManager then
        Log.Warn("ItemButton: PointManager is not available!")
        return
    end

    local shopItem = self:GetShopItem(entity)
    if not shopItem then
        return
    end

    self.CanAfford = self.PointManager.Points >= shopItem.ItemPrice

    -- TODO: Disable the item if the player already owns it / has it equipt

    -- Only touch the component when affordability actually flips.
    if self.TintApplied ~= self.CanAfford then
        self:ApplyTint(entity, self.CanAfford)
    end
end

function ItemButton:OnClick(entity)
    local shopItem = self:GetShopItem(entity)
    if not shopItem then
        return
    end

    if self.CanAfford then
        Log.Info("ItemButton: Purchasing item '" .. shopItem.ItemName .. "' for " .. tostring(shopItem.ItemPrice) .. " points.")
        EventManager.Broadcast("OnItemPurchased", shopItem.ItemPrice)
        EventManager.Broadcast("OnShopItemPurchased", shopItem.ItemPrefab)
    else
        Log.Warn("ItemButton: Cannot afford item '" .. shopItem.ItemName .. "'. Current Points = " .. tostring(self.PointManager.Points) .. ", Item Price = " .. tostring(shopItem.ItemPrice))
    end
end

function ItemButton:OnHoverEnter(entity)
end

function ItemButton:OnHoverExit(entity)
end

return ItemButton
