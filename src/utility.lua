local module = {}

local timerScheduled = {}
local timers = {}
local systemTimer = 0
local timerStartTime = 0

function module.scheduleTimer(time, handler, ...)
    if timers[1] == nil then
        timers[1] = {
            time = time,
            handlers = {
                { func = handler, args = {...} }
            }
        }
        systemTimer = os.startTimer(time)
        timerStartTime = os.clock()
        return
    else
        local timerRunTime = os.clock() - timerStartTime
        timers[1].time = timers[1].time - timerRunTime
        timerStartTime = os.clock()
    end

    local timeLeft = time
    for i = 1, #timers do
        local timer = timers[i]

        local saveTime = timeLeft
        timeLeft = timeLeft - timer.time
        if timeLeft == 0 then
            -- Append to handler list
            timer.handlers[#timer.handlers+1] = {
                func = handler,
                args = {...}
            }
        elseif timeLeft < 0 then
            timer.time = timer.time - saveTime

            -- Insert an event
            local newTimer = {
                time = saveTime,
                handlers = {
                    { func = handler, args = {...} }
                }
            }
            table.insert(timers, i, newTimer)
            if i == 1 then
                os.cancelTimer(systemTimer)
                systemTimer = os.startTimer(time)
            end
        end
    end
end

function module.handleTimerEvent(eventData)
    if eventData[2] ~= systemTimer then
        return
    end
    local timer = table.remove(timers, 1)
    for i = 1, #timer.handlers do
        local handler = timer.handlers[i]
        handler.func(table.unpack(handler.args))
    end
    if timers[1] ~= nil then
        systemTimer = os.startTimer(timers[1].time)
        timerStartTime = os.clock()
    end
end

return module
