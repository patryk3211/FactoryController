local module = {}

local timerScheduled = {}
local timers = {}
local systemTimer = 0
local timerStartTime = 0

function module.scheduleTimer(time, handler, ...)
    print("Scheduling for "..(time * 20).." ticks")
    if timers[1] == nil then
        timers[1] = {
            time = time * 20,
            handlers = { { func = handler, args = {...} } }
        }
        systemTimer = os.startTimer(time)
        timerStartTime = os.clock() * 20
        return
    else
        local clock = os.clock() * 20
        local timerRunTime = math.floor(clock - timerStartTime)
        timers[1].time = timers[1].time - timerRunTime
        if timers[1].time < 0 then
            timers[1].time = 0
        end
        timerStartTime = clock
        print("Timer changed by "..timerRunTime.." new time "..timers[1].time)
    end

    local timeLeft = time * 20
    for i = 1, #timers do
        local timer = timers[i]

        local saveTime = timeLeft
        timeLeft = timeLeft - timer.time
        if timeLeft == 0 then
            -- Append to handler list
            timer.handlers[#timer.handlers+1] = { func = handler, args = {...} }
            return
        elseif timeLeft < 0 then
            timer.time = timer.time - saveTime

            -- Insert an event
            local newTimer = {
                time = saveTime,
                handlers = { { func = handler, args = {...} } }
            }
            table.insert(timers, i, newTimer)
            if i == 1 then
                os.cancelTimer(systemTimer)
                systemTimer = os.startTimer(time)
            end
            return
        end
    end
    timers[#timers+1] = {
        time = time * 20,
        handlers = { { func = handler, args = {...} } }
    }
end

function module.handleTimerEvent(eventData)
    if eventData[2] ~= systemTimer then
        return
    end
    local timer = table.remove(timers, 1)
    print("Firing after "..timer.time.." ticks")
    for i = 1, #timer.handlers do
        local handler = timer.handlers[i]
        handler.func(table.unpack(handler.args))
    end
    if timers[1] ~= nil then
        systemTimer = os.startTimer(timers[1].time / 20)
        timerStartTime = os.clock() * 20
    end
end

return module
