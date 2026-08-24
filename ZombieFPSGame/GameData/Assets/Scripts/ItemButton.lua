local ItemButton = {}

ItemButton.ItemName = "Item Name"
ItemButton.ItemPrice = 100

function ItemButton:OnCreate(entity)
    self.PointManager = _G.PointManager
    self.CanAfford = false
end

function ItemButton:OnUpdate(entity, delta)
    if not self.PointManager then
        Log.Warn("ItemButton: PointManager is not available!")
        return
    end

    Log.Info("ItemButton: Current Points = " .. tostring(self.PointManager.Points) .. ", Item Price = " .. tostring(self.ItemPrice))

    -- Update the button's state based on the player's current points
    self.CanAfford = self.PointManager.Points >= self.ItemPrice

    -- Enable/Disable selectable component based on affordability
    local selectableComponent = entity:GetComponent("UISelectableComponent")
    if selectableComponent then
        selectableComponent.Interactable = self.CanAfford
    else
        Log.Warn("ItemButton: UISelectableComponent is not available on the entity!")
    end

    -- If affordable, change color to green, else red
    local spriteComponent = entity:GetComponent("SpriteComponent")
    if spriteComponent then
        if self.CanAfford then
            spriteComponent.Color = Vector4f.new(0.0, 1.0, 0.0, 0.75) -- Green
        else
            spriteComponent.Color = Vector4f.new(1.0, 0.0, 0.0, 0.75) -- Red
        end
    else
        Log.Warn("ItemButton: SpriteComponent is not available on the entity!")
    end
end

function ItemButton:OnClick(entity)
    if self.CanAfford then
        Log.Info("ItemButton: Purchasing item '" .. self.ItemName .. "' for " .. tostring(self.ItemPrice) .. " points.")
        EventManager.Broadcast("OnItemPurchased", self.ItemPrice)
    else
        Log.Warn("ItemButton: Cannot afford item '" .. self.ItemName .. "'. Current Points = " .. tostring(self.PointManager.Points) .. ", Item Price = " .. tostring(self.ItemPrice))
    end
end

function ItemButton:OnHoverEnter(entity)

end

function ItemButton:OnHoverExit(entity)

end

return ItemButton