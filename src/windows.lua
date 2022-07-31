local module = {}

local display = nil
local currentWindow = {}

function module.start()
    display = peripheral.wrap(io.lines(shell.resolve("monitor"), "l"))

    display.setBackgroundColor(colors.lightGray)
    display.clear()

    display.setCursorPos(1, 1)
    display.setTextColor(colors.black)
    display.write("Loading...")
end

function module.shutdown()
    display.setBackgroundColor(colors.black)
    display.clear()
end

local function handleElementsTouch(x, y, elements)
    local i = #elements.order
    while i >= 1 do
        -- Check elements from the "top"
        local e = elements[elements.order[i]]
        if e.type == "button" and (e.visible == nil or e.visible == true) and (e.enabled == nil or e.enabled == true) then
            if x >= e.x and y >= e.y and x < e.x + e.width and y < e.y + e.height then
                if e.handler ~= nil then
                    e.handler(currentWindow)
                end
                return true
            end
        elseif e.type == "group" and (e.visible == nil or e.visible == true) then
            if handleElementsTouch(x - e.x + 1, y - e.y + 1, e.elements) then
                return true
            end
        end
        i = i - 1
    end
    return false
end

function module.handleTouch(eventData)
    local x, y = eventData[3], eventData[4]
    handleElementsTouch(x, y, currentWindow)
end

function module.setGui(window)
    currentWindow = window
    module.redraw()
end

function module.remove(name)
    currentWindow[name] = nil
end

function module.clear()
    currentWindow = {}
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

local function drawElements(x, y, elements)
    for i, id in ipairs(elements.order) do
        local element = elements[id]
        if element.visible == nil or element.visible == true then
            if element.type == "button" then
                if element.fg ~= nil then
                    display.setTextColor(element.fg)
                end
                display.setBackgroundColor(element.bg)

                box(x + element.x, y + element.y, element.width, element.height)

                local textOffset = (element.width - element.text:len()) / 2
                display.setCursorPos(x + element.x + textOffset, y + element.y + element.height / 2)
                display.write(element.text)
            elseif element.type == "panel" then
                display.setBackgroundColor(element.color)

                box(x + element.x, y + element.y, element.width, element.height)
            elseif element.type == "text" then
                display.setTextColor(element.fg)
                display.setBackgroundColor(element.bg)

                display.setCursorPos(x + element.x, y + element.y)
                display.write(element.text)
            elseif element.type == "group" then
                drawElements(x + element.x - 1, y + element.y - 1, element.elements)
            end
        end
    end
end

function module.redraw()
    display.setBackgroundColor(colors.lightGray)
    display.clear()

    drawElements(0, 0, currentWindow)
end

return module
