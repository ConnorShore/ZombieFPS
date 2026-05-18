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
    local hitResult = Physics.CastRay(rayStart, rayEnd, CollisionFilter.Pickup)
    if hitResult.Hit then
        pickupUI:SetActive(true)

        if Input.IsKeyPressed(KeyCode.E) then
            local pickupScript = hitResult.Entity:GetScriptInstance("PickUpItem")
            if pickupScript then
                local playerController = Scene.GetEntityByName("PlayerController")
                if not playerController then
                    Log.Error("PlayerController entity not found in scene!")
                    return
                end

                local playerControllerScript = playerController:GetScriptInstance("PlayerController")

                -- Check if the player is actually holding a gun right now
                if playerControllerScript.ActiveWeaponEntity then
                    local weaponController = playerControllerScript.ActiveWeapon:GetScriptInstance("WeaponController")
                    local isAttachment = pickupScript and type(pickupScript.GetAttachmentData) == "function"
                    if weaponController and isAttachment then
                        local data = pickupScript:GetAttachmentData()
                        weaponController:EquipAttachment(data.Type, data.PrefabName)
                    end
                    
                else
                    Log.Warn("Cannot equip attachment: Player is not holding a weapon!")
                end
                
                -- Always call OnPickup and remove entity for all pickup types
                pickupScript:OnPickup(hitResult.Entity, entity)
            end
        end
    else
        pickupUI:SetActive(false)
    end
end

return PlayerInteraction