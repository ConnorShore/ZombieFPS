local WeaponHolder = {}

WeaponHolder.WeaponSlots = 2
WeaponHolder.EmptyGunSound = ""

function WeaponHolder:OnCreate(entity)
    self.PlayedEmptyGunSound = false
    self.Weapons = {nil, nil} -- Track equipped weapons in each slot
    self.ActiveWeaponSlot = 1
    self.Entity = entity
end

function WeaponHolder:OnUpdate(entity, delta)
    if Input.IsMouseButtonPressed(MouseButton.Left) then
        self:OnShoot()
    else
        self.PlayedEmptyGunSound = false
    end

    if Input.IsKeyPressed(KeyCode.R) and self:GetCurrentWeapon() then
        self:OnReload()
    end
end

function WeaponHolder:EquipWeapon(prefabName)
    -- If the same weapon is already equipped in a slot, do nothing and switch to that slot
    for i = 1, self.WeaponSlots do
        if self.Weapons[i] ~= nil and self.Weapons[i]:GetName() == prefabName then
            Log.Info("Weapon '" .. prefabName .. "' is already equipped in slot " .. tostring(i) .. ". Switching to that slot.")
            self.ActiveWeaponSlot = i
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
        else
            Log.Info("No empty weapon slot available, removing existing weapon in slot " .. tostring(self.ActiveWeaponSlot))
            local existingWeaponEntity = Scene.GetEntityByName(self.Weapons[self.ActiveWeaponSlot]:GetName())
            if existingWeaponEntity then
                Scene.RemoveEntity(existingWeaponEntity)
            end
        end
    end

    Log.Info("Equipping weapon '" .. prefabName .. "' to slot " .. tostring(self.ActiveWeaponSlot))

    -- Equip new weapon
    local newWeaponEntity = Scene.InstantiatePrefab(prefabName, self.Entity)
    local weaponControllerScript = newWeaponEntity and newWeaponEntity:GetScriptInstance()
    if not weaponControllerScript then
        Log.Warn("Equipped weapon prefab '" .. prefabName .. "' does not have a WeaponController script attached! Removing weapon entity.")
        Scene.RemoveEntity(newWeaponEntity)
        return
    end
    
    local transform = newWeaponEntity:GetComponent("TransformComponent")
    transform.Position = weaponControllerScript.EquipPositionOffset
    self.Weapons[self.ActiveWeaponSlot] = newWeaponEntity
end

function WeaponHolder:OnShoot()
    if not self:GetCurrentWeapon() then
        Log.Warn("No weapon equipped!")
        return
    end

    local weaponEntity = Scene.GetEntityByName(self:GetCurrentWeapon():GetName())
    if not weaponEntity then
        Log.Warn("Weapon entity '" .. self:GetCurrentWeapon():GetName() .. "' not found in scene!")
        return
    end

    local weaponControllerScript = weaponEntity:GetScriptInstance()
    if not weaponControllerScript then
        Log.Warn("Weapon entity '" .. self:GetCurrentWeapon():GetName() .. "' does not have a WeaponController script attached!")
        return
    end

    -- Fire the weapon
    -- TODO: Need to have specific weapons ahve fire profiles and the WEaponFire just handles the actual firing logic
    -- based on the current equipped weapon's fire profile. This way we can have different types of weapons (hitscan, projectile, shotgun, etc.) 
    -- and the fire logic can be handled in a modular way.
    local weaponFireEntity = Scene.GetEntityByName("WeaponFire")
    if not weaponFireEntity then
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
        if not self.PlayedEmptyGunSound and self.EmptyGunSound ~= "" then
            AudioSystem.PlaySound(self.EmptyGunSound)
            self.PlayedEmptyGunSound = true
        end
        return
    end

    if (not weaponFireScript.CanShoot) then
        return
    end

    -- Shoot using the WeaponFire proxy so spread is centered on camera/reticle.
    weaponFireScript:Fire(weaponFireEntity)
    weaponControllerScript:OnShoot()
end

function WeaponHolder:OnReload()
    local weaponEntity = Scene.GetEntityByName(self:GetCurrentWeapon():GetName())
    if not weaponEntity then
        Log.Warn("Weapon entity '" .. self:GetCurrentWeapon():GetName() .. "' not found in scene!")
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

return WeaponHolder