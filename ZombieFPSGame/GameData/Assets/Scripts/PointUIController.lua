local PointUIController = {}

function PointUIController:OnCreate(entity)
    self.textComponent = entity:GetComponent("TextComponent")

    EventManager.Subscribe("OnPointsChanged", function(newPoints)
        self:UpdatePointsDisplay(newPoints)
    end)
end

function PointUIController:OnUpdate(entity, delta)

end

function PointUIController:UpdatePointsDisplay(newPoints)
    if not self.textComponent then
        Log.Warn("TextComponent not found on PointUIController entity! Cannot update points display.")
        return
    end

    self.textComponent.Text = tostring(newPoints)
end

return PointUIController