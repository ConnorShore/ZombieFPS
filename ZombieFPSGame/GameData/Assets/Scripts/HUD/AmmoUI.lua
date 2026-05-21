local AmmoUI = {}

function AmmoUI:OnCreate(entity)
    self.AmmoTextEntity = Scene.GetEntityByName("AmmoText")
    if not self.AmmoTextEntity then
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
    if self.AmmoTextEntity then
        local textComponent = self.AmmoTextEntity:GetComponent("TextComponent")
        if textComponent then
            textComponent.Text = tostring(currentAmmo) .. " / " .. tostring(reserveAmmo)
        end
    end
end

return AmmoUI