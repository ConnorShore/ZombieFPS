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
    local rayEnd = interactionPos + interactionForward * self.InteractionDistance

    Debug.DrawLine(rayStart, rayEnd)

    -- Cast ray to detect interactable objects
    local hitResult = Physics.CastRay(rayStart, rayEnd, CollisionFilter.Pickup)
    if hitResult.Hit then
        local hitEntity = hitResult.HitEntity
        Log.Info("Player is looking at an interactable object: " .. hitEntity:GetName())
    end
end

return PlayerInteraction