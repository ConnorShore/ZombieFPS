local WeaponController = {}

WeaponController.SightMountName = ""
WeaponController.MuzzleMountName = ""
WeaponController.StockMountName = ""
WeaponController.GripMountName = ""

WeaponController.MaxAmmo = 120
WeaponController.MagazineSize = 30

WeaponController.ReloadTime = 1.0   -- Time (in seconds) it takes to reload
WeaponController.ReloadStartSound = ""
WeaponController.ReloadEndSound = ""

function WeaponController:OnCreate(entity)
    -- 2. Dynamically resolve the mount points based on what you typed in the Editor
    self.MountPoints = {
        [1] = self.SightMountName ~= "" and Scene.GetEntityByName(self.SightMountName) or nil,
        [2] = self.StockMountName ~= "" and Scene.GetEntityByName(self.StockMountName) or nil,
        [3] = self.MuzzleMountName ~= "" and Scene.GetEntityByName(self.MuzzleMountName) or nil,
        [4] = self.GripMountName ~= "" and Scene.GetEntityByName(self.GripMountName) or nil
    }
    
    self.ActiveAttachments = {nil, nil, nil, nil} -- Track active attachments in each slot

    self.CurrentAmmo = self.MagazineSize
    self.ReserveAmmo = self.MaxAmmo - self.MagazineSize
    self.IsReloading = false
    self.ReloadTimer = 0.0
    self.CanShoot = true
end

function WeaponController:OnUpdate(entity, delta)
end

function WeaponController:OnShoot()
    if self.CurrentAmmo > 0 then
        self.CurrentAmmo = self.CurrentAmmo - 1
        Log.Info("Shot fired! Current ammo: " .. self.CurrentAmmo .. "/" .. self.MagazineSize)
    else
        Log.Warn("Out of ammo!")
        self.CanShoot = false
    end
end

function WeaponController:OnReload()
    if not self.IsReloading and self.ReserveAmmo > 0 then
        self.IsReloading = true
        if self.ReloadStartSound ~= "" then
            AudioSystem.PlaySound(self.ReloadStartSound)
        end

        Timer.SetTimeout(function()
            self.CurrentAmmo = self.ReserveAmmo > self.MagazineSize and self.MagazineSize or self.ReserveAmmo
            self.ReserveAmmo = self.ReserveAmmo > self.MagazineSize and self.ReserveAmmo - self.MagazineSize or 0

            if self.ReloadEndSound ~= "" then
                AudioSystem.PlaySound(self.ReloadEndSound)
            end
            
            self.IsReloading = false
            self.CanShoot = true
            Log.Info("Reload complete!")
        end, self.ReloadTime)
        Log.Info("Started reloading...")
    end
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