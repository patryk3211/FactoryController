-- Load configs

local redstoneMgr = require("redstone")
redstoneMgr.loadMappings()

local utility = require("utility")

print("Initialized successfully")

local function timerHandler()
    print("1 Second")
    utility.scheduleTimer(1, timerHandler)
end

utility.scheduleTimer(1, timerHandler)

-- Program loop
local running = true
while running do
    local eventData = {os.pullEvent()}
    local event = eventData[1]

    if event == "timer" then
        utility.handleTimerEvent(eventData)
    end
end
