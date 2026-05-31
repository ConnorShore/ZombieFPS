local AmmoUI = {}

AmmoUI.AmmoTextRef = EntityRef()

function AmmoUI:OnCreate(entity)
    self.AmmoTextEntity = Scene.GetEntityByUUID(self.AmmoTextRef)
    if not self.AmmoTextEntity:IsValid() then
        Log.Warn("Cannot find AmmoText entity in scene! Ammo count will not be displayed.")
    else
        local textComponent = self.AmmoTextEntity:GetComponent("TextComponent")
        if textComponent then
            textComponent.Text = "0 / 0"
        else
            Log.Warn("AmmoText entity does not have a TextComponent! Ammo count will not be displayed.")
        end
    end
end

function AmmoUI:SetAmmo(currentAmmo, reserveAmmo)
    if self.AmmoTextEntity and self.AmmoTextEntity:IsValid() then
        local textComponent = self.AmmoTextEntity:GetComponent("TextComponent")
        if textComponent then
            textComponent.Text = tostring(currentAmmo) .. " / " .. tostring(reserveAmmo)
        end
    else
        Log.Warn("Cannot update ammo text because AmmoTextEntity is not set!")
    end
end

return AmmoUI