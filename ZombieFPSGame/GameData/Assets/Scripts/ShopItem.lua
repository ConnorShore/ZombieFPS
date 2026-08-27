local ShopItem = {}

ShopItem.ItemName = "Item Name"
ShopItem.ItemPrice = 100
ShopItem.ItemPrefab = PrefabRef()

function ShopItem:OnCreate(entity)
    local button = entity:GetChild("ItemButton")
    if not button:IsValid() then
        Log.Warn("ShopItem: could not find 'ItemButton' child entity!")
        return
    end

    local label = button:GetChild("Label")
    if label:IsValid() then
        label:GetComponent("TextComponent").Text = self.ItemName
    else
        Log.Warn("ShopItem: could not find 'Label' child entity!")
    end

    local price = button:GetChild("Price")
    if price:IsValid() then
        price:GetComponent("TextComponent").Text = tostring(self.ItemPrice)
    else
        Log.Warn("ShopItem: could not find 'Price' child entity!")
    end
end

return ShopItem
