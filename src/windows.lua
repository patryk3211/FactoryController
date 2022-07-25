local module = {}

local display = nil
local elements = {}

function module.start()
    display = peripheral.find("monitor")

    display.setBackgroundColor(colors.lightGray)
    display.clear()

    display.setCursorPos(1, 1)
    display.setTextColor(colors.black)
    display.write("Loading...")
end

function module.handleTouch(eventData)
    local x, y = eventData[3], eventData[4]
    for name, e in pairs(elements) do
        if e.type == "button" then
            if x >= e.x and y >= e.y and x < e.x + e.width and y < e.y + e.height then
                if e.handler ~= nil then
                    e.handler()
                end
                break
            end
        end
    end
end

function module.addButton(name, x, y, width, height, text, fg, bg, clickHandler)
    elements[name] = { type = "button", x = x, y = y, width = width, height = height, text = text, fg = fg, bg = bg, handler = clickHandler }
end

function module.setGui(elmnt)
    elements = elmnt
    module.redraw()
end

function module.remove(name)
    elements[name] = nil
end

function module.clear()
    elements = {}
end

local function box(x, y, width, height)
    local line = ""
    for i = 0, width-1 do
        line = line.." "
    end
    for i = 0, height-1 do
        display.setCursorPos(x, y+i)
        display.write(line)
    end
end

function module.redraw()
    display.setBackgroundColor(colors.lightGray)
    display.clear()

    for i, id in ipairs(elements.order) do
        local element = elements[id]
        if element.type == "button" then
            display.setTextColor(element.fg)
            display.setBackgroundColor(element.bg)

            box(element.x, element.y, element.width, element.height)

            local textOffset = (element.width - element.text:len()) / 2
            display.setCursorPos(element.x + textOffset, element.y + element.height / 2)
            display.write(element.text)
        elseif element.type == "panel" then
            display.setBackgroundColor(element.color)

            box(element.x, element.y, element.width, element.height)
        elseif element.type == "text" then
            display.setTextColor(element.fg)
            display.setBackgroundColor(element.bg)

            display.setCursorPos(element.x, element.y)
            display.write(element.text)
        end
    end
end

return module
