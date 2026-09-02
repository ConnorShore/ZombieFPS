local ExitToDesktopButton = {}

function ExitToDesktopButton:OnClick(entity)
    GameData:SaveAll()
    Application.Quit()
end

return ExitToDesktopButton