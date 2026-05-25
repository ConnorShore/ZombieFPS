local PlayerInteraction = {}

PlayerInteraction.InteractionDistance = 2.0

function PlayerInteraction:OnCreate(entity)

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
    local pickupUI = Scene.GetEntityByName("PickupItemUI")
    local hitResult = Physics.CastRay(rayStart, rayEnd, CollisionFilter.PickupItem)
    if hitResult.Hit then
        pickupUI:SetActive(true)

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
        pickupUI:SetActive(false)
    end
end

function PlayerInteraction:OnPickupItem(pickupScript, pickupEntity, playerEntity)
    Log.Info("PlayerInteraction:OnPickupItem - Attempting to pick up item")
    local weaponHolder = Scene.GetEntityByName("WeaponHolder")
    if not weaponHolder then
        Log.Error("WeaponHolder entity not found in scene!")
        return
    end

    local weaponHolderScript = weaponHolder:GetScriptInstance("WeaponHolder")

    -- TODO: Should this logic be in PickupItem script??
    -- Check if the player is actually holding a gun right now
    if weaponHolderScript:GetCurrentWeapon() then
        local weaponController = weaponHolderScript:GetCurrentWeapon():GetScriptInstance("WeaponController")
        local isAttachment = pickupScript and type(pickupScript.GetAttachmentData) == "function"
        if weaponController and isAttachment then
            local data = pickupScript:GetAttachmentData()
            weaponController:EquipAttachment(data.Type, data.PrefabName)
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