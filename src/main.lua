-- Load configs

local redstoneMgr = require("redstone")
local utility = require("utility")
local windows = require("windows")

redstoneMgr.loadMappings()
windows.start()

print("Initialized successfully")

-- Program loop
local running = true
while running do
    local eventData = {os.pullEvent()}
    local event = eventData[1]

    if event == "timer" then
        utility.handleTimerEvent(eventData)
    elseif event == "monitor_touch" then
        windows.handleTouch(eventData)
        windows.redraw()
    end
end
