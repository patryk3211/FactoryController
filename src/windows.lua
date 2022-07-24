local module = {}

local display = nil

function module.start()
    display = peripheral.find("monitor")
end

function module.handleTouch(eventData)
    local x, y = eventData[3], eventData[4]
    display.setCursorPos(x, y)
    display.blit(" ", "F", "0")
end

return module
