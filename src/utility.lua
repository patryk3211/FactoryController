local module = {}

local systemTimer = nil
local timers = {}

function module.scheduleTimer(time, handler, ...)
    local tickTime = math.floor(time * 20)

    if systemTimer == nil then
        systemTimer = os.startTimer(0.05)
    end

    local timeLeft = tickTime
    for i = 1, #timers do
        local timer = timers[i]

        local _timeLeft = timeLeft
        timeLeft = timeLeft - timer.time

        if timeLeft == 0 then
            -- Append handler
            table.insert(timer.handlers, { func = handler, args = {...} })
            return
        elseif timeLeft < 0 then
            -- Insert before this timer
            timer.time = timer.time - _timeLeft
            table.insert(timers, i, { time = _timeLeft, handlers = { { func = handler, args = {...} } } })
            return
        end
    end

    timers[#timers+1] = { time = timeLeft, handlers = { { func = handler, args = {...} } } }
end

function module.handleTimerEvent(eventData)
    if eventData[2] ~= systemTimer then
        return
    end

    local firstTimer = timers[1]
    if firstTimer ~= nil then
        firstTimer.time = firstTimer.time - 1
        if firstTimer.time == 0 then
            for i = 1, #firstTimer.handlers do
                local handler = firstTimer.handlers[i]
                handler.func(table.unpack(handler.args))
            end
            table.remove(timers, 1)
        end
    end

    if timers[1] ~= nil then
        systemTimer = os.startTimer(0.05)
    else
        systemTimer = nil
    end
end

return module
