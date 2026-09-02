local PauseMenuController = {}

PauseMenuController.DefaultSelection = EntityRef()

function PauseMenuController:OnCreate(entity)
    self.Entity = entity
    self.DefaultSelectionEntity = Scene.GetEntityByUUID(self.DefaultSelection)
    if not self.DefaultSelectionEntity or not self.DefaultSelectionEntity:IsValid() then
        Log.Warn("PauseMenuController: DefaultSelection entity is not valid!")
    end

    EventManager.Subscribe("OnPause", function()
        self:OnPause()
    end)
    EventManager.Subscribe("OnResume", function()
        self:OnResume()
    end)

    self.Entity:SetActive(false) -- Start with the pause menu hidden
end

function PauseMenuController:OnPause()
    Log.Info("PauseMenuController: Activating pause menu.")
    self.Entity:SetActive(true)
    
    if Input.GetLastUsedInputDevice() == InputDevice.Gamepad then
        local selectable = self.DefaultSelectionEntity:GetComponent("UISelectableComponent")
        if selectable then
            Log.Trace("PauseMenuController: Selecting default button for gamepad input.")
            selectable:Select()
        else
            Log.Warn("PauseMenuController: DefaultSelection entity does not have a UISelectableComponent!")
        end
    end
end

function PauseMenuController:OnResume()
    Log.Info("PauseMenuController: Deactivating pause menu.")
    self.Entity:SetActive(false)
end

return PauseMenuController