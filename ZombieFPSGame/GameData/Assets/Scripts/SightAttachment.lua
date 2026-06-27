local SightAttachment = {}

-- Expose this to the editor so you can drag the scope's local ADS_Node here
SightAttachment.SightAimNodeRef = EntityRef()

function SightAttachment:OnCreate(entity)
    self.Entity = entity
end

function SightAttachment:GetAimNode()
    local node = Scene.GetEntityByUUID(self.SightAimNodeRef)
    if node and node:IsValid() then
        return node
    end
    return nil
end

return SightAttachment