local ResumeButton = {}

function ResumeButton:OnClick(entity)
    EventManager.Broadcast("OnResume") 
end

return ResumeButton