local module = {}

local display = nil

function module.start()
    display = peripheral.find("monitor")
end

function module.handleTouch(eventData)
    local x, y = eventData[3], eventData[4]
    display.blit(" ", "0", "F")
end

return module
