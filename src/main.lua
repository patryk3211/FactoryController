-- Load configs

local redstoneMgr = require("redstone")
local utility = require("utility")
local windows = require("windows")
local control = require("control")

redstoneMgr.loadMappings()
control.loadConfig()
windows.start()

print("Initialized successfully")

windows.addButton("button_0", 3, 3, 5, 3, "Hey", colors.white, colors.blue, function ()
    control.outputIngredient("sugar", 8)
end)

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
