local ShopController = {}

ShopController.ShopMenuUI = EntityRef()

function ShopController:OnCreate(entity)
    self.ShopMenuUIEntity = Scene.GetEntityByUUID(self.ShopMenuUI)
    if not self.ShopMenuUIEntity or not self.ShopMenuUIEntity:IsValid() then
        Log.Error("ShopController: ShopMenuUI entity is not valid!")
    end
    self.ShopMenuUIEntity:SetActive(false)
end

function ShopController:OnUpdate(entity, delta)

end

function ShopController:OnApproach()
    if self.ShopMenuUIEntity and self.ShopMenuUIEntity:IsValid() then
        self.ShopMenuUIEntity:SetActive(true)
    end
end

function ShopController:OnOpen()
    if self.ShopMenuUIEntity and self.ShopMenuUIEntity:IsValid() then
        self.ShopMenuUIEntity:SetActive(true)
    end
end

function ShopController:OnPurchase(purchaseItem, price)

end

return ShopController