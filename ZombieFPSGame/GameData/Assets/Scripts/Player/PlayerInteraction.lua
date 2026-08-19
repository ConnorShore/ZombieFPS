-- Facilitates interaction: finds the Interactable the player is aiming at, drives the prompt UI
-- from it and forwards the interact key to it. Every interactable owns its own text and behaviour.
local PlayerInteraction = {}

PlayerInteraction.InteractionDistance = 2.0
PlayerInteraction.InteractionUIRef = EntityRef()

function PlayerInteraction:OnCreate(entity)
    self.InteractionUI = Scene.GetEntityByUUID(self.InteractionUIRef)

    self.InteractionTextComponent = nil
    if self.InteractionUI and self.InteractionUI:IsValid() then
        self.InteractionTextComponent = self.InteractionUI:GetComponent("TextComponent")
    else
        Log.Error("PlayerInteraction: InteractionUI entity is not valid!")
    end

    -- Cache our own transform handle (safe for the entity's lifetime; it re-resolves the
    -- live component internally) so OnUpdate doesn't do a string-keyed lookup every frame.
    self.transform = entity:GetComponent("TransformComponent")

    self.AvailableColor = Vector4f.new(1.0, 1.0, 1.0, 1.0)
    self.UnavailableColor = Vector4f.new(1.0, 0.0, 0.0, 1.0)
    self.DisplayedText = nil
    self.WasInteractKeyDown = false
    self.WarnedEntityID = nil
end

function PlayerInteraction:OnUpdate(entity, delta)
    -- Edge-detect the key here so each interactable is triggered once per press rather than
    -- every frame the key is held.
    local interactKeyDown = Input.IsKeyPressed(KeyCode.E)
    local interactKeyJustPressed = interactKeyDown and not self.WasInteractKeyDown
    self.WasInteractKeyDown = interactKeyDown

    if not self.InteractionUI or not self.InteractionUI:IsValid() or not self.InteractionTextComponent then
        Log.Warn("PlayerInteraction: InteractionUI entity or its TextComponent is not valid!")
        return
    end

    local interactable, interactableEntity = self:FindInteractable()
    if not interactable then
        self.InteractionUI:SetActive(false)
        return
    end

    local canInteract = interactable:CanInteract(interactableEntity, entity)

    self.InteractionUI:SetActive(true)
    self:SetPromptText(interactable:GetInteractionText(interactableEntity, entity))
    self.InteractionTextComponent.Color = canInteract and self.AvailableColor or self.UnavailableColor

    if canInteract and interactKeyJustPressed then
        interactable:OnInteract(interactableEntity, entity)
    end
end

-- Returns the Interactable script instance the player is aiming at and the entity it is attached
-- to, or nil when there is nothing interactable in range.
function PlayerInteraction:FindInteractable()
    local transform = self.transform
    local rayStart = transform.WorldPosition
    local rayEnd = rayStart + transform:GetForward() * self.InteractionDistance

    -- Ray visualization for debugging
    -- Debug.DrawLine(rayStart, rayEnd)

    local hitResult = Physics.CastRay(rayStart, rayEnd, CollisionFilter.Interactable)
    if not hitResult.Hit then
        return nil, nil
    end

    -- Resolves through the script's Base chain, so any script inheriting Interactable matches.
    local hitEntity = hitResult.RigidBodyEntity
    local interactable = hitEntity:GetScriptInstance("Interactable")
    if not interactable then
        -- Warn once per offending entity rather than every frame the player looks at it.
        if self.WarnedEntityID ~= hitEntity:GetID() then
            Log.Warn("PlayerInteraction: '" .. hitEntity:GetName() .. "' is on the Interactable filter but has no Interactable script attached!")
            self.WarnedEntityID = hitEntity:GetID()
        end
        return nil, nil
    end

    return interactable, hitEntity
end

-- Only pushes the string when it actually changes, so the text mesh isn't rebuilt every frame.
function PlayerInteraction:SetPromptText(text)
    if text == self.DisplayedText then
        return
    end

    self.InteractionTextComponent.Text = text
    self.DisplayedText = text
end

return PlayerInteraction
