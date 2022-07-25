local module = {}

local timerScheduled = {}

function module.scheduleTimer(time, handler, ...)
    local timer = os.startTimer(time)
    timerScheduled[timer] = { handler = handler, args = {...} }
end

function module.handleTimerEvent(eventData)
    local handler = timerScheduled[eventData[2]]
    timerScheduled[eventData[2]] = nil
    handler.handler(table.unpack(handler.args))
end

return module
