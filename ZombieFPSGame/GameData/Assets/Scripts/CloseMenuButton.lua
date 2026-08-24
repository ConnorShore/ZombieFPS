local CloseMenuButton = {}

-- Expose properties to the editor by adding them to this table. For Example:
-- CloseMenuButton.MyExampleVar = 10

function CloseMenuButton:OnClick(entity)
    EventManager.Broadcast("OnCloseShop")
end

function CloseMenuButton:OnHoverEnter(entity)

end

function CloseMenuButton:OnHoverExit(entity)

end

return CloseMenuButton