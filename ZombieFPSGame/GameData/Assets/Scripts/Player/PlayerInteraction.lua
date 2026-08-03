local PlayerInteraction = {}

PlayerInteraction.InteractionDistance = 2.0
PlayerInteraction.PickupUIRef = EntityRef()
PlayerInteraction.WeaponHolderRef = EntityRef()

function PlayerInteraction:OnCreate(entity)
    self.PickupUI = Scene.GetEntityByUUID(self.PickupUIRef)
    self.WeaponHolder = Scene.GetEntityByUUID(self.WeaponHolderRef)

    self.PickupTextComponent = nil
    if self.PickupUI and self.PickupUI:IsValid() then
        self.PickupTextComponent = self.PickupUI:GetComponent("TextComponent")
    else
        Log.Error("PlayerInteraction: PickupUI entity is not valid!")
    end

    -- Cache our own transform handle (safe for the entity's lifetime; it re-resolves the
    -- live component internally) so OnUpdate doesn't do a string-keyed lookup every frame.
    self.transform = entity:GetComponent("TransformComponent")
end

function PlayerInteraction:OnUpdate(entity, delta)
    if not self.PickupUI or not self.PickupUI:IsValid() then
        Log.Warn("PlayerInteraction: PickupUI entity is not valid!")
        return
    end

    -- Get player position and forward direction
    local interactionTransform = self.transform
    local interactionPos = interactionTransform.WorldPosition
    local interactionForward = interactionTransform:GetForward()

    local rayStart = interactionPos
    local rayEnd = rayStart + interactionForward * self.InteractionDistance

    -- Ray visualization for debugging
    -- Debug.DrawLine(rayStart, rayEnd)

    -- Cast ray to detect interactable objects
    local hitResult = Physics.CastRay(rayStart, rayEnd, CollisionFilter.PickupItem)
    if not hitResult.Hit then
        self.PickupUI:SetActive(false)
        return
    end

    -- Show pickup UI and update text based on the hit entity
    self.PickupUI:SetActive(true)

    -- If player can't afford item, don't allow pickup
    local pickupScript = hitResult.RigidBodyEntity:GetScriptInstance("PurchasableItem")
    if not pickupScript then
        Log.Warn("PlayerInteraction: Hit entity '" .. hitResult.RigidBodyEntity:GetName() .. "' does not have a PurchasableItem script attached!")
        return
    end
    if not pickupScript:CanAfford() then
        self.PickupTextComponent.Color = Vector4f.new(1.0, 0.0, 0.0, 1.0)
        return
    end

    -- Player can afford item, show pickup text in white
    self.PickupTextComponent.Color = Vector4f.new(1.0, 1.0, 1.0, 1.0)

    if Input.IsKeyPressed(KeyCode.E) then
        local pickupItemScript = hitResult.RigidBodyEntity:GetScriptInstance("PickupItem")
        if pickupItemScript then
            self:OnPickupItem(pickupItemScript, hitResult.RigidBodyEntity, entity)
            return
        end

        local pickupWeaponScript = hitResult.RigidBodyEntity:GetScriptInstance("PickupWeapon")
        if pickupWeaponScript then
            self:OnPickupWeapon(pickupWeaponScript, hitResult.RigidBodyEntity, entity)
            return
        end

        Log.Warn("PlayerInteraction: Hit entity does not have a recognized pickup script attached!")
    end
end

function PlayerInteraction:OnPickupItem(pickupScript, pickupEntity, playerEntity)
    Log.Info("PlayerInteraction:OnPickupItem - Attempting to pick up item")
    local weaponHolder = self.WeaponHolder
    if not weaponHolder:IsValid() then
        Log.Error("WeaponHolder entity not found in scene!")
        return
    end

    local weaponHolderScript = weaponHolder:GetScriptInstance("WeaponHolder")
    if not weaponHolderScript then
        Log.Error("WeaponHolder entity does not have a WeaponHolder script attached!")
        return
    end

    -- TODO: Should this logic be in PickupItem script??
    -- Check if the player is actually holding a gun right now
    if weaponHolderScript:GetCurrentWeapon() then
        local weaponController = weaponHolderScript:GetCurrentWeapon():GetScriptInstance("WeaponController")
        local isAttachment = pickupScript and type(pickupScript.GetAttachmentData) == "function"
        if weaponController and isAttachment then
            local data = pickupScript:GetAttachmentData()
            weaponController:EquipAttachment(data.Type, data.PrefabHandle)
        end
    else
        Log.Warn("Cannot equip attachment: Player is not holding a weapon!")
        return
    end
    
    -- Always call OnPickup and remove entity for all pickup types
    pickupScript:OnPickup(pickupEntity, playerEntity)
end

function PlayerInteraction:OnPickupWeapon(pickupScript, pickupEntity, playerEntity)
    Log.Info("PlayerInteraction:OnPickupWeapon - Attempting to pick up weapon")
    pickupScript:OnPickup(pickupEntity, playerEntity)
end

return PlayerInteraction