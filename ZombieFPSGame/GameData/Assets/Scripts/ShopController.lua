local ShopController = {}
ShopController.Base = "Interactable"

ShopController.ShopMenuUI = EntityRef()
ShopController.InteractionPrompt = "Press (E) to open shop"
ShopController.SpawnLocation = EntityRef() -- The entity where purchased items will spawn
ShopController.PurchaseSound = AudioClipRef()

function ShopController:OnCreate(entity)
    self.ShopMenuUIEntity = Scene.GetEntityByUUID(self.ShopMenuUI)
    if not self.ShopMenuUIEntity or not self.ShopMenuUIEntity:IsValid() then
        Log.Error("ShopController: ShopMenuUI entity is not valid!")
        return
    end

    self.SpawnLocationEntity = Scene.GetEntityByUUID(self.SpawnLocation)
    if not self.SpawnLocationEntity or not self.SpawnLocationEntity:IsValid() then
        Log.Error("ShopController: SpawnLocation entity is not valid!")
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
        EventManager.Broadcast("OnLockFreelook")
        EventManager.Broadcast("OnWeaponLocked")
        Input.SetCursorMode(CursorMode.Normal)
        self.ShopMenuUIEntity:SetActive(true)
    end
end

function ShopController:OnClose()
    if self.ShopMenuUIEntity and self.ShopMenuUIEntity:IsValid() then
        EventManager.Broadcast("OnUnlockFreelook")
        EventManager.Broadcast("OnWeaponUnlocked")
        Input.SetCursorMode(CursorMode.Locked)
        self.ShopMenuUIEntity:SetActive(false)
    end
end

function ShopController:OnPurchase(purchaseItem)
    if not purchaseItem or not purchaseItem:IsValid() then
        Log.Error("ShopController: Invalid item prefab received for purchase!")
        return
    end

    if not self.SpawnLocationEntity or not self.SpawnLocationEntity:IsValid() then
        Log.Error("ShopController: SpawnLocation entity is not valid!")
        return
    end

    -- Spawn the prefab item at the shop's item location
    local spawnLocation = self.SpawnLocationEntity:GetComponent("TransformComponent").WorldPosition
    Scene.InstantiatePrefab(purchaseItem, spawnLocation)

    AudioSystem.PlayOneShot(self.PurchaseSound)

    self:OnClose()
end

return ShopController
