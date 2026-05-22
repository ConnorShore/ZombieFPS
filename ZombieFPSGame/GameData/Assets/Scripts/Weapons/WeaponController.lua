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

WeaponController.MagOutEventName = "MagOut"
WeaponController.MagInEventName = "MagIn"
WeaponController.RefillAmmoEventName = "RefillAmmo"
WeaponController.ReloadCompleteEventName = "ReloadComplete"
WeaponController.ReloadAnimationName = "Reload"

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

    self.AnimatorComp = entity:GetComponent("AnimatorComponent")
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
    Log.Info("Reload key pressed. Attempting to reload...")
    if not self.IsReloading and self.ReserveAmmo > 0 then
        self.IsReloading = true

        if not self.AnimatorComp then
            Log.Error("WeaponController:OnReload - No AnimatorComponent found on entity " .. self.Entity:GetName())
            return
        end
        
        self.AnimatorComp:Play(self.ReloadAnimationName, 1.0, 0.1)
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

function WeaponController:OnAnimationEvent(eventName)
    if not self.IsReloading then return end

    if eventName == self.MagOutEventName then
        AudioSystem.PlaySound(self.ReloadStartSound)
    elseif eventName == self.MagInEventName then
        AudioSystem.PlaySound(self.ReloadEndSound)
    elseif eventName == self.RefillAmmoEventName then
        local remainingAmmoInMag = self.CurrentAmmo
        self.CurrentAmmo = self.ReserveAmmo > self.MagazineSize and self.MagazineSize or self.ReserveAmmo
        self.ReserveAmmo = self.ReserveAmmo > self.MagazineSize and (self.ReserveAmmo - self.MagazineSize) + remainingAmmoInMag or 0
        self.AmmoScript:SetAmmo(self.CurrentAmmo, self.ReserveAmmo)
    elseif eventName == self.ReloadCompleteEventName then
        Log.Info("Reload complete!")
        self.IsReloading = false
    end
end

return WeaponController