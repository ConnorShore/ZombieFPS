local WeaponHolder = {}

WeaponHolder.WeaponSlots = 2
WeaponHolder.EmptyGunSound = AudioClipRef()
WeaponHolder.WeaponFireRef = EntityRef()

function WeaponHolder:OnCreate(entity)
    self.PlayedEmptyGunSound = false
    self.ActiveWeaponSlot = 1
    self.WeaponLocked = false
    self.Entity = entity
    self.WeaponFire = Scene.GetEntityByUUID(self.WeaponFireRef)

    -- Weapons based on slots, will be populated when equipping weapons
    self.Weapons = {}
    for i = 1, self.WeaponSlots do
        self.Weapons[i] = nil
    end

    self.WasShootingLastFrame = false

    EventManager.Subscribe("OnWeaponLocked", function()
        self.WeaponLocked = true
    end)
    EventManager.Subscribe("OnWeaponUnlocked", function()
        self.WeaponLocked = false
    end)
end

function WeaponHolder:OnUpdate(entity, delta)
    if self.WeaponLocked then
        return
    end

    if Input.IsMouseButtonPressed(MouseButton.Left) then
        self:OnShoot(self.WasShootingLastFrame)
        self.WasShootingLastFrame = true
    else
        self.PlayedEmptyGunSound = false
        self.WasShootingLastFrame = false
    end

    if Input.IsKeyPressed(KeyCode.R) and self:GetCurrentWeapon() then
        self:OnReload()
    end

    if Input.IsKeyPressed(KeyCode.D1) then
        self.ActiveWeaponSlot = 1
        self:RefreshWeaponVisibility()
    elseif Input.IsKeyPressed(KeyCode.D2) then
        self.ActiveWeaponSlot = 2
        self:RefreshWeaponVisibility()
    end
end

function WeaponHolder:GetWeaponPrefabHandle(weaponEntity)
    if weaponEntity and weaponEntity:IsValid() and weaponEntity:ContainsComponent("PrefabComponent") then
        return weaponEntity:GetComponent("PrefabComponent").PrefabHandle
    end

    return nil
end

function WeaponHolder:RefreshWeaponVisibility()
    for i = 1, self.WeaponSlots do
        if self.Weapons[i] ~= nil and self.Weapons[i]:IsValid() then
            local isActive = (i == self.ActiveWeaponSlot)
            self.Weapons[i]:SetActive(isActive)

            if isActive then
                -- Update ammo UI for newly active weapon
                local weaponControllerScript = self.Weapons[i]:GetScriptInstance()
                if weaponControllerScript then
                    weaponControllerScript:TryBindAmmoUI()
                end
            end
        end
    end
end

function WeaponHolder:EquipWeapon(prefabHandle)
    -- If the same weapon is already equipped in a slot, do nothing and switch to that slot
    for i = 1, self.WeaponSlots do
        if self.Weapons[i] ~= nil and self:GetWeaponPrefabHandle(self.Weapons[i]) == prefabHandle then
            Log.Info("Weapon prefab '" .. tostring(prefabHandle) .. "' is already equipped in slot " .. tostring(i) .. ". Switching to that slot.")
            self.ActiveWeaponSlot = i
            self:RefreshWeaponVisibility()
            return
        end
    end

    -- If existing weapon, but only one weapon slot equip, move it to open slot, otherwise remove it
    if self.Weapons[self.ActiveWeaponSlot] ~= nil then
        local emptySlot = nil
        for i = 1, self.WeaponSlots do
            if self.Weapons[i] == nil then
                emptySlot = i
                break
            end
        end

        if emptySlot then
            Log.Info("Moving existing weapon in slot " .. tostring(self.ActiveWeaponSlot) .. " to empty slot " .. tostring(emptySlot))
            self.Weapons[emptySlot] = self.Weapons[self.ActiveWeaponSlot]
            self.Weapons[self.ActiveWeaponSlot] = nil
        else
            Log.Info("No empty weapon slot available, removing existing weapon in slot " .. tostring(self.ActiveWeaponSlot))
            Scene.RemoveEntity(self.Weapons[self.ActiveWeaponSlot])
            self.Weapons[self.ActiveWeaponSlot] = nil
        end
    end

    Log.Info("Equipping weapon prefab '" .. tostring(prefabHandle) .. "' to slot " .. tostring(self.ActiveWeaponSlot))

    -- Equip new weapon
    local newWeaponEntity = Scene.InstantiatePrefab(prefabHandle, self.Entity)
    local weaponControllerScript = newWeaponEntity:IsValid() and newWeaponEntity:GetScriptInstance() or nil
    if not weaponControllerScript then
        Log.Warn("Equipped weapon prefab '" .. tostring(prefabHandle) .. "' does not have a WeaponController script attached! Removing weapon entity.")
        Scene.RemoveEntity(newWeaponEntity)
        return
    end
    
    local transform = newWeaponEntity:GetComponent("TransformComponent")
    transform.Position = weaponControllerScript.EquipPositionOffset
    self.Weapons[self.ActiveWeaponSlot] = newWeaponEntity
    self:RefreshWeaponVisibility()
end

function WeaponHolder:OnShoot(wasShootingLastFrame)
    local weaponEntity = self:GetCurrentWeapon()
    if not weaponEntity or not weaponEntity:IsValid() then
        Log.Warn("No weapon equipped!")
        return
    end

    local weaponControllerScript = weaponEntity:GetScriptInstance()
    if not weaponControllerScript then
        Log.Warn("Weapon entity '" .. self:GetCurrentWeapon():GetName() .. "' does not have a WeaponController script attached!")
        return
    end

    -- Fire the weapon
    local weaponFireEntity = self.WeaponFire
    if not weaponFireEntity:IsValid() then
        Log.Warn("Cannot find WeaponFire entity in scene!")
        return
    end

    local weaponFireScript = weaponFireEntity:GetScriptInstance()
    if not weaponFireScript then
        Log.Warn("WeaponFire entity does not have a WeaponFire script attached!")
        return
    end

    -- Scheck if weapons can shoot
    if not weaponControllerScript.CanShoot then
        if not self.PlayedEmptyGunSound then
            AudioSystem.PlaySound(self.EmptyGunSound)
            self.PlayedEmptyGunSound = true
        end
        return
    end

    if (not weaponFireScript.CanShoot) then
        return
    end

    -- Shoot using the WeaponFire proxy so spread is centered on camera/reticle.
    local didFire = weaponFireScript:Fire(weaponFireEntity, weaponEntity, wasShootingLastFrame)
    if didFire then
        weaponControllerScript:OnShoot()
    end
end

function WeaponHolder:OnReload()
    local weaponEntity = self:GetCurrentWeapon()
    if not weaponEntity or not weaponEntity:IsValid() then
        Log.Warn("Current weapon entity is not valid!")
        return
    end

    local weaponControllerScript = weaponEntity:GetScriptInstance()
    if not weaponControllerScript then
        Log.Warn("Weapon entity '" .. self:GetCurrentWeapon():GetName() .. "' does not have a WeaponController script attached!")
        return
    end

    weaponControllerScript:OnReload()
end

function WeaponHolder:GetCurrentWeapon()
    return self.Weapons[self.ActiveWeaponSlot]
end

function WeaponHolder:GetCurrentWeaponStatsEntity()
    local weaponEntity = self:GetCurrentWeapon()
    if not weaponEntity or not weaponEntity:IsValid() then
        Log.Warn("Current weapon entity is not valid!")
        return nil
    end

    local weaponControllerScript = weaponEntity:GetScriptInstance()
    if not weaponControllerScript then
        Log.Warn("Weapon entity '" .. self:GetCurrentWeapon():GetName() .. "' does not have a WeaponController script attached!")
        return nil
    end

    local weaponStatsEntity = weaponControllerScript.GetWeaponStats and weaponControllerScript:GetWeaponStats() or nil
    if not weaponStatsEntity or not weaponStatsEntity:IsValid() then
        Log.Warn("Weapon entity '" .. self:GetCurrentWeapon():GetName() .. "' could not resolve a valid WeaponStats entity!")
        return nil
    end

    return weaponStatsEntity
end

function WeaponHolder:GetCurrentWeaponStatsScript()
    local weaponStatsEntity = self:GetCurrentWeaponStatsEntity()
    if not weaponStatsEntity then
        return nil
    end
    
    local weaponStatsScript = weaponStatsEntity:GetScriptInstance("WeaponStats")
    if not weaponStatsScript then
        Log.Warn("WeaponStats entity for weapon '" .. self:GetCurrentWeapon():GetName() .. "' does not have a WeaponStats script attached!")
        return nil
    end

    return weaponStatsScript
end

return WeaponHolder