local ItemButton = {}

ItemButton.ItemName = "Item Name"
ItemButton.ItemPrice = 100
ItemButton.ItemPrefab = PrefabRef()

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

    self.CanAfford = self.PointManager.Points >= self.ItemPrice

    -- TODO: Disable the item if the player already owns it / has it equipt

    -- Only touch the component when affordability actually flips.
    if self.TintApplied ~= self.CanAfford then
        self:ApplyTint(entity, self.CanAfford)
    end
end

function ItemButton:OnClick(entity)
    if self.CanAfford then
        Log.Info("ItemButton: Purchasing item '" .. self.ItemName .. "' for " .. tostring(self.ItemPrice) .. " points.")
        EventManager.Broadcast("OnItemPurchased", self.ItemPrice)
        EventManager.Broadcast("OnShopItemPurchased", self.ItemPrefab)
    else
        Log.Warn("ItemButton: Cannot afford item '" .. self.ItemName .. "'. Current Points = " .. tostring(self.PointManager.Points) .. ", Item Price = " .. tostring(self.ItemPrice))
    end
end

function ItemButton:OnHoverEnter(entity)
end

function ItemButton:OnHoverExit(entity)
end

return ItemButton
