local GlobalSystems = {}

-- Event System
if not _G.EventManager then
    _G.EventManager = {
        _listeners = {}
    }

    -- Subscribe to an event
    function _G.EventManager.Subscribe(eventName, callback)
        if not _G.EventManager._listeners[eventName] then
            _G.EventManager._listeners[eventName] = {}
        end
        table.insert(_G.EventManager._listeners[eventName], callback)
    end

    -- Broadcast an event to anyone listening
    function _G.EventManager.Broadcast(eventName, ...)
        local listeners = _G.EventManager._listeners[eventName]
        if listeners then
            for _, callback in ipairs(listeners) do
                callback(...)
            end
        end
    end
end

return GlobalSystems