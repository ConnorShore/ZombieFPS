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
            -- TODO: Activate the entitie's pickup behavior (i.e give ammo, points, etc)
            Scene.RemoveEntity(hitResult.Entity)
        end
    else
        pickupUI:SetActive(false)
    end
end

return PlayerInteraction