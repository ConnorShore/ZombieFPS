local PlayerInteraction = {}

PlayerInteraction.InteractionDistance = 2.0
PlayerInteraction.PickupUIRef = EntityRef()
PlayerInteraction.WeaponHolderRef = EntityRef()

function PlayerInteraction:OnCreate(entity)
    self.PickupUI = Scene.GetEntityByUUID(self.PickupUIRef)
    self.WeaponHolder = Scene.GetEntityByUUID(self.WeaponHolderRef)
end

function PlayerInteraction:OnUpdate(entity, delta)
    -- Get player position and forward direction
    local interactionTransform = entity:GetComponent("TransformComponent")
    local interactionPos = interactionTransform.WorldPosition
    local interactionForward = interactionTransform:GetForward()

    local rayStart = interactionPos
    local rayEnd = rayStart + interactionForward * self.InteractionDistance

    -- Ray visualization for debugging
    -- Debug.DrawLine(rayStart, rayEnd)

    -- Cast ray to detect interactable objects
    local hitResult = Physics.CastRay(rayStart, rayEnd, CollisionFilter.PickupItem)
    if hitResult.Hit then
        if self.PickupUI:IsValid() then
            self.PickupUI:SetActive(true)
        end

        if Input.IsKeyPressed(KeyCode.E) then
            Log.Info("PlayerInteraction: Detected interactable object hit by raycast: " .. hitResult.Entity:GetName())
            local pickupItemScript = hitResult.Entity:GetScriptInstance("PickupItem")
            if pickupItemScript then
                Log.Info("PlayerInteraction: Found PickupItem script on hit entity, attempting to pick up item")
                self:OnPickupItem(pickupItemScript, hitResult.Entity, entity)
                return
            end

            local pickupWeaponScript = hitResult.Entity:GetScriptInstance("PickupWeapon")
            if pickupWeaponScript then
                Log.Info("PlayerInteraction: Found PickupWeapon script on hit entity, attempting to pick up weapon")
                self:OnPickupWeapon(pickupWeaponScript, hitResult.Entity, entity)
                return
            end

            Log.Warn("PlayerInteraction: Hit entity does not have a recognized pickup script attached!")
        end
    else
        if self.PickupUI:IsValid() then
            self.PickupUI:SetActive(false)
        end
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