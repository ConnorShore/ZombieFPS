-- Facilitates interaction: finds the Interactable the player is aiming at, drives the prompt UI
-- from it and forwards the interact key to it. Every interactable owns its own text and behaviour.
local PlayerInteraction = {}

PlayerInteraction.InteractionDistance = 2.0
PlayerInteraction.InteractionUIRef = EntityRef()

-- Queried in order, first match wins. A pickup spawned inside the shop kiosk's volume has to beat
-- the kiosk, and a single closest-hit ray can't do that: it returns the kiosk's outer surface
-- because the ray enters that before ever reaching the pickup nested within it.
local InteractionFilterNames = { "Pickup", "Interactable" }

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
    self.WarnedEntityIDs = {}

    self.InteractionFilters = self:ResolveInteractionFilters()

    EventManager.Subscribe("OnLockInteraction", function()
        self.LockInteraction = true
    end)

    EventManager.Subscribe("OnUnlockInteraction", function()
        self.LockInteraction = false
    end)
end

-- Resolves the filter names to their project bitmasks once, since the slots can't change at runtime.
function PlayerInteraction:ResolveInteractionFilters()
    local filters = {}

    for _, name in ipairs(InteractionFilterNames) do
        local filter = CollisionFilter[name]
        if filter then
            table.insert(filters, filter)
        else
            -- Skipped rather than passed through: CastRay reads a nil filter as "every filter", so
            -- an unregistered slot would quietly match world geometry instead of matching nothing.
            Log.Error("PlayerInteraction: collision filter '" .. name .. "' is not defined in the project settings; interaction will ignore it!")
        end
    end

    return filters
end

function PlayerInteraction:OnUpdate(entity, delta)
    -- A menu owns the interact button while it is up, so the prompt and the ray go with it.
    if self.LockInteraction then
        if self.InteractionUI and self.InteractionUI:IsValid() then
            self.InteractionUI:SetActive(false)
        end

        return
    end

    -- The action reports the press edge, so each interactable is triggered once per press
    -- rather than every frame the key is held.
    local interactJustPressed = Input.IsActionPressed("Interact")

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

    if canInteract and interactJustPressed then
        interactable:OnInteract(interactableEntity, entity)

        -- Interact shares a gamepad button with NavBack, so without this whatever the interaction
        -- just opened would read the same press as a close later in this frame.
        Input.ConsumeAction("Interact")
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

    for _, filter in ipairs(self.InteractionFilters) do
        local interactable, hitEntity = self:QueryInteractable(rayStart, rayEnd, filter)
        if interactable then
            return interactable, hitEntity
        end
    end

    return nil, nil
end

-- One closest-hit cast against a single filter; nil means nothing usable on that filter.
function PlayerInteraction:QueryInteractable(rayStart, rayEnd, filter)
    local hitResult = Physics.CastRay(rayStart, rayEnd, filter)
    if not hitResult.Hit then
        return nil, nil
    end

    local hitEntity = hitResult.RigidBodyEntity
    if not hitEntity or not hitEntity:IsValid() then
        return nil, nil
    end

    -- Resolves through the script's Base chain, so any script inheriting Interactable matches.
    local interactable = hitEntity:GetScriptInstance("Interactable")
    if not interactable then
        -- Warn once per offending entity rather than every frame the player looks at it.
        local hitID = hitEntity:GetID()
        if not self.WarnedEntityIDs[hitID] then
            Log.Warn("PlayerInteraction: '" .. hitEntity:GetName() .. "' is on an interaction filter but has no Interactable script attached!")
            self.WarnedEntityIDs[hitID] = true
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
