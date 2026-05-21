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

function WeaponController:TryBindAmmoUI()
    if self.AmmoScript then
        return true
    end

    local ammoEntity = Scene.GetEntityByName("AmmoUI")
    if not ammoEntity then
        return false
    end

    local ammoScript = ammoEntity:GetScriptInstance()
    if not ammoScript then
        return false
    end

    self.AmmoEntity = ammoEntity
    self.AmmoScript = ammoScript
    self.AmmoScript:SetAmmo(self.CurrentAmmo, self.ReserveAmmo)
    return true
end

function WeaponController:OnCreate(entity)
    -- Dynamically resolve the mount points based on what you typed in the Editor
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

    self.AmmoEntity = nil
    self.AmmoScript = nil
    if not self:TryBindAmmoUI() then
        Log.Info("AmmoUI script not ready during WeaponController:OnCreate. Will retry on update.")
    end
end

function WeaponController:OnUpdate(entity, delta)
    if not self.AmmoScript then
        self:TryBindAmmoUI()
    end
end

function WeaponController:OnShoot()
    if self.CurrentAmmo > 0 then
        self.CurrentAmmo = self.CurrentAmmo - 1

        if self.AmmoScript or self:TryBindAmmoUI() then
            self.AmmoScript:SetAmmo(self.CurrentAmmo, self.ReserveAmmo)
        end
    else
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
            if self.AmmoScript or self:TryBindAmmoUI() then
                self.AmmoScript:SetAmmo(self.CurrentAmmo, self.ReserveAmmo)
            end
        end, self.ReloadTime)
        Log.Info("Started reloading...")
    end
end

function WeaponController:EquipAttachment(attachmentType, prefabName)
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
    end
    
    -- Spawn the new attachment as a child of the specific mount point entity
    local newAttachment = Scene.InstantiatePrefab(prefabName, mountPointEntity)
    
    -- Track it
    self.ActiveAttachments[attachmentType] = newAttachment
end

return WeaponController