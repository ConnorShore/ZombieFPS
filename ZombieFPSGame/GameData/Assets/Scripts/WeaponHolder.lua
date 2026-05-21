local WeaponHolder = {}

WeaponHolder.CurrentWeapon = ""
WeaponHolder.EmptyGunSound = ""

function WeaponHolder:OnCreate(entity)

    self.PlayedEmptyGunSound = false
end

function WeaponHolder:OnUpdate(entity, delta)
    if Input.IsMouseButtonPressed(MouseButton.Left) then
        self:OnShoot()
    else
        self.PlayedEmptyGunSound = false
    end

    if Input.IsKeyPressed(KeyCode.R) then
        self:OnReload()
    end
end

function WeaponHolder:EquipWeapon(prefabName)
    -- TODO: For weapon switching, we will want a list of available weapons and their prefabs, 
    -- and then we can spawn the new weapon and destroy the old one.
    -- Or we can have all of them attached and enable/disable them as needed. Depends on how we want to handle ammo, attachments, etc.
end

function WeaponHolder:OnShoot()
    if self.CurrentWeapon == "" then
        Log.Warn("No weapon equipped!")
        return
    end

    local weaponEntity = Scene.GetEntityByName(self.CurrentWeapon)
    if not weaponEntity then
        Log.Warn("Weapon entity '" .. self.CurrentWeapon .. "' not found in scene!")
        return
    end

    local weaponControllerScript = weaponEntity:GetScriptInstance("WeaponController")
    if not weaponControllerScript then
        Log.Warn("Weapon entity '" .. self.CurrentWeapon .. "' does not have a WeaponController script attached!")
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

    local weaponFireScript = weaponFireEntity:GetScriptInstance("WeaponFire")
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

    -- Shoot if can shoot
    weaponFireScript:Fire(weaponEntity)
    weaponControllerScript:OnShoot()
end

function WeaponHolder:OnReload()
    local weaponEntity = Scene.GetEntityByName(self.CurrentWeapon)
    if not weaponEntity then
        Log.Warn("Weapon entity '" .. self.CurrentWeapon .. "' not found in scene!")
        return
    end

    local weaponControllerScript = weaponEntity:GetScriptInstance("WeaponController")
    if not weaponControllerScript then
        Log.Warn("Weapon entity '" .. self.CurrentWeapon .. "' does not have a WeaponController script attached!")
        return
    end

    weaponControllerScript:OnReload()
end

return WeaponHolder