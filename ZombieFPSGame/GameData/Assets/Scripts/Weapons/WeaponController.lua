local WeaponController = {}

WeaponController.SightMountName = ""
WeaponController.MuzzleMountName = ""
WeaponController.StockMountName = ""
WeaponController.GripMountName = ""

function WeaponController:OnCreate(entity)
    -- 2. Dynamically resolve the mount points based on what you typed in the Editor
    self.MountPoints = {
        [1] = self.SightMountName ~= "" and Scene.GetEntityByName(self.SightMountName) or nil,
        [2] = self.StockMountName ~= "" and Scene.GetEntityByName(self.StockMountName) or nil,
        [3] = self.MuzzleMountName ~= "" and Scene.GetEntityByName(self.MuzzleMountName) or nil,
        [4] = self.GripMountName ~= "" and Scene.GetEntityByName(self.GripMountName) or nil
    }
    
    self.ActiveAttachments = {nil, nil, nil, nil} -- Track active attachments in each slot
end

function WeaponController:EquipAttachment(attachmentType, prefabName)
    Log.Info("EquipAttachment called with type: " .. tostring(attachmentType) .. " and prefab: " .. tostring(prefabName))

    local mountPointEntity = self.MountPoints[attachmentType]
    Log.Info("Attempting to equip attachment of type " .. tostring(attachmentType) .. " with prefab " .. tostring(prefabName))
    
    if not mountPointEntity then
        Log.Warn("This weapon does not support attachment type: " .. tostring(attachmentType))
        return
    end
    
    -- Remove existing attachment in this slot if there is one
    if self.ActiveAttachments[attachmentType] ~= nil then
        Scene.RemoveEntity(self.ActiveAttachments[attachmentType])
        self.ActiveAttachments[attachmentType] = nil
        Log.Info("Removed existing attachment in slot type: " .. tostring(attachmentType))
    end
    
    -- Spawn the new attachment as a child of the specific mount point entity
    local newAttachment = Scene.InstantiatePrefab(prefabName, mountPointEntity)
    Log.Info("Instantiated new attachment prefab: " .. tostring(newAttachment and newAttachment:GetName() or "NIL") .. " on mount point: " .. mountPointEntity:GetName())
    
    -- Track it
    self.ActiveAttachments[attachmentType] = newAttachment
    Log.Info("Successfully equipped " .. prefabName .. " to weapon!")
end

return WeaponController