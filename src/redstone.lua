local module = {}

local config = require("config")
local utility = require("utility")

local mappings = nil
local peripherals = {}

function module.loadMappings()
    mappings = config.loadConfig(shell.resolve("config/mappings.conf"), "mapping")
    for k, v in pairs(mappings) do
        if peripherals[v.dev] == nil then
            local dev = peripheral.wrap(v.dev)
            peripherals[v.dev] = { device = dev, sides = { [v.side] = 0 } }
            dev.setAnalogOutput(v.side, 0)
        else
            peripherals[v.dev].sides[v.side] = 0
            peripherals[v.dev].device.setAnalogOutput(v.side, 0)
        end
    end
end

function module.setOutput(port, value)
    local mapping = mappings[port]
    local peri = peripherals[mapping.dev]
    local currentValue = peri.sides[mapping.side]
    if value then
        currentValue = bit32.bor(currentValue, bit32.lshift(1, mapping.bit))
    else
        currentValue = bit32.band(currentValue, bit32.bnot(bit32.lshift(1, mapping.bit)))
    end
    peri.device.setAnalogOutput(mapping.side, currentValue)
    peri.sides[mapping.side] = currentValue
end

function module.getInput(port)
    local mapping = mappings[port]
    local peri = peripherals[mapping.dev]
    local value = peri.device.getAnalogInput(mapping.side)
    return bit32.band(1, bit32.rshift(value, mapping.bit)) == 1
end

function module.pulse(port)
    module.setOutput(port, true)
    utility.scheduleTimer(0.1, function ()
        module.setOutput(port, false)
    end)
end

return module
