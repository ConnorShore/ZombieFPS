local WeaponController = {}

WeaponController.SightMountRef = EntityRef()
WeaponController.MuzzleMountRef = EntityRef()
WeaponController.StockMountRef = EntityRef()
WeaponController.GripMountRef = EntityRef()
WeaponController.BarrelTipRef = EntityRef()
WeaponController.MuzzleFlashRef = EntityRef()
WeaponController.AmmoUIRef = EntityRef()

WeaponController.MaxAmmo = 120
WeaponController.MagazineSize = 30

WeaponController.ReloadTime = 1.0   -- Time (in seconds) it takes to reload
WeaponController.ReloadStartSound = AudioClipRef()
WeaponController.ReloadEndSound = AudioClipRef()

WeaponController.MagOutEventName = "MagOut"
WeaponController.MagInEventName = "MagIn"
WeaponController.RefillAmmoEventName = "RefillAmmo"
WeaponController.ReloadCompleteEventName = "ReloadComplete"
WeaponController.ReloadStateName = "Reload"
WeaponController.ReloadTriggerParam = "ReloadRequested"

WeaponController.EquipPositionOffset = Vector3f.new(0, 0, 0)

function WeaponController:OnCreate(entity)
    self.Entity = entity
    self.MountPoints = {
        [1] = self:ResolveEntityRef(self.SightMountRef),
        [2] = self:ResolveEntityRef(self.StockMountRef),
        [3] = self:ResolveEntityRef(self.MuzzleMountRef),
        [4] = self:ResolveEntityRef(self.GripMountRef)
    }
    self.BarrelTipEntity = self:ResolveEntityRef(self.BarrelTipRef)
    self.MuzzleFlashEntity = self:ResolveEntityRef(self.MuzzleFlashRef)
    
    self.ActiveAttachments = {nil, nil, nil, nil} -- Track active attachments in each slot

    self.CurrentAmmo = self.MagazineSize
    self.ReserveAmmo = self.MaxAmmo - self.MagazineSize
    self.IsReloading = false
    self.ReloadTimer = 0.0
    self.CanShoot = true

    self.AnimatorComp = entity:GetComponent("AnimatorComponent")
    if self.AnimatorComp then
        self.AnimatorComp:SetBool(self.ReloadTriggerParam, false)
    end

    self.AmmoEntity = nil
    self.AmmoScript = nil
    if not self:TryBindAmmoUI() then
        Log.Info("AmmoUI script not ready during WeaponController:OnCreate. Will retry on update.")
    end
end

function WeaponController:ResolveEntityRef(entityRef)
    local resolved = Scene.GetEntityByUUID(entityRef)
    if resolved:IsValid() then
        return resolved
    end

    return nil
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

    local ammoEntity = Scene.GetEntityByUUID(self.AmmoUIRef)
    if not ammoEntity:IsValid() then
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
    if not self.IsReloading and self.ReserveAmmo > 0 then
        self.IsReloading = true

        if not self.AnimatorComp then
            Log.Error("WeaponController:OnReload - No AnimatorComponent found on entity " .. self.Entity:GetName())
            self.IsReloading = false
            return
        end

        self.AnimatorComp:SetBool(self.ReloadTriggerParam, true)
    end
end

function WeaponController:EquipAttachment(attachmentType, prefabHandle)
    local mountPointEntity = self.MountPoints[attachmentType]
    Log.Info("Attempting to equip attachment of type " .. tostring(attachmentType) .. " with prefab " .. tostring(prefabHandle))
    
    if not mountPointEntity or not mountPointEntity:IsValid() then
        Log.Warn("This weapon does not support attachment type: " .. tostring(attachmentType))
        return
    end
    
    -- Remove existing attachment in this slot if there is one
    if self.ActiveAttachments[attachmentType] ~= nil then
        Scene.RemoveEntity(self.ActiveAttachments[attachmentType])
        self.ActiveAttachments[attachmentType] = nil
    end
    
    -- Spawn the new attachment as a child of the specific mount point entity
    local newAttachment = Scene.InstantiatePrefab(prefabHandle, mountPointEntity)
    
    -- Track it
    self.ActiveAttachments[attachmentType] = newAttachment
end

function WeaponController:GetBarrelTipEntity()
    return self.BarrelTipEntity
end

function WeaponController:GetMuzzleFlashEntity()
    return self.MuzzleFlashEntity
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
        if self.AmmoScript or self:TryBindAmmoUI() then
            self.AmmoScript:SetAmmo(self.CurrentAmmo, self.ReserveAmmo)
        end
        if self.ReserveAmmo <= 0 then
            self.CanShoot = self.CurrentAmmo > 0
        else
            self.CanShoot = true
        end
    elseif eventName == self.ReloadCompleteEventName then
        Log.Info("Reload complete!")
        self.IsReloading = false
        if self.AnimatorComp then
            self.AnimatorComp:SetBool(self.ReloadTriggerParam, false)
        end
    end
end

function WeaponController:AddAmmo(amount)
    self.ReserveAmmo = self.ReserveAmmo + amount
    if self.ReserveAmmo > self.MaxAmmo then
        self.ReserveAmmo = self.MaxAmmo
    end

    if self.AmmoScript or self:TryBindAmmoUI() then
        self.AmmoScript:SetAmmo(self.CurrentAmmo, self.ReserveAmmo)
    end
end

return WeaponController