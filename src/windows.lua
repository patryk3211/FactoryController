local module = {}

local display = nil
local buttons = {}

function module.start()
    display = peripheral.find("monitor")
end

function module.handleTouch(eventData)
    local x, y = eventData[3], eventData[4]
    display.setCursorPos(x, y)
    display.blit(" ", "F", "0")
end

function module.addButton(name, x, y, width, height, text, fg, bg, clickHandler)
    buttons[name] = { x = x, y = y, width = width, height = height, text = text, fg = fg, bg = bg, handelr = clickHandler }
end

function module.removeButton(name)
    buttons[name] = nil
end

local function box(x, y, width, height)
    local line = ""
    for i = 0, width do
        line = line.." "
    end
    for i = 0, height do
        display.setCursorPos(x, y+i)
        display.write(line)
    end
end

function module.redraw()
    display.setBackgroundColor(colors.black)
    display.clear()

    for name, button in pairs(buttons) do
        display.setTextColor(button.fg)
        display.setBackgroundColor(button.bg)

        box(button.x, button.y, button.width, button.height)

        display.setCursorPos(button.x, button.y)
    end
end

return module
