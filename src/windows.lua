local module = {}

function module.start()

end

function module.handleTouch(eventData)
    local x, y = eventData[3], eventData[4]
    print("Touch "..x.." "..y)
end

return module
