-- Base class for anything the player can look at and interact with. Never attached to an entity
-- directly - pickups, weapons and shops inherit from it via Base = "Interactable" and override
-- these three methods; PlayerInteraction finds them through the Interactable collision filter.
local Interactable = {}

-- Prompt shown while the player is looking at this object. Override GetInteractionText instead
-- when the prompt needs runtime state (a price, a weapon name, ...) mixed in.
Interactable.InteractionPrompt = "Press (E) to interact"

function Interactable:GetInteractionText(entity, playerEntity)
    return self.InteractionPrompt
end

-- Whether the interaction is available right now; false draws the prompt in red and blocks OnInteract.
function Interactable:CanInteract(entity, playerEntity)
    return true
end

-- Runs the interaction, called once per interact key press and only when CanInteract passed.
function Interactable:OnInteract(entity, playerEntity)
    Log.Warn("Interactable: '" .. entity:GetName() .. "' does not implement OnInteract!")
end

return Interactable
