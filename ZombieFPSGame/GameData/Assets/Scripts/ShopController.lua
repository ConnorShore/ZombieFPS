local ShopController = {}
ShopController.Base = "Interactable"

ShopController.ShopMenuUI = EntityRef()
ShopController.InteractionPrompt = "Press (E) to open shop"

function ShopController:OnCreate(entity)
    self.ShopMenuUIEntity = Scene.GetEntityByUUID(self.ShopMenuUI)
    if not self.ShopMenuUIEntity or not self.ShopMenuUIEntity:IsValid() then
        Log.Error("ShopController: ShopMenuUI entity is not valid!")
        return
    end

    EventManager.Subscribe("OnCloseShop", function()
        self:OnClose()
    end)

    EventManager.Subscribe("OnShopItemPurchased", function(itemPrefab)
        self:OnPurchase(itemPrefab)
    end)

    self.ShopMenuUIEntity:SetActive(false)
end

function ShopController:OnInteract(entity, playerEntity)
    self:OnOpen()
end

function ShopController:OnOpen()
    if self.ShopMenuUIEntity and self.ShopMenuUIEntity:IsValid() then
        Input.SetCursorMode(CursorMode.Normal)
        self.ShopMenuUIEntity:SetActive(true)
    end
end

function ShopController:OnClose()
    if self.ShopMenuUIEntity and self.ShopMenuUIEntity:IsValid() then
        Input.SetCursorMode(CursorMode.Locked)
        self.ShopMenuUIEntity:SetActive(false)
    end
end

function ShopController:OnPurchase(purchaseItem)
    -- Spawn the prefab item at the shop's item location
end

return ShopController
