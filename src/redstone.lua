local module = {}

local config = require("config")

local mappings = nil
local peripherals = {}

function module.load_mappings()
    mappings = config.load_config(shell.resolve("config/mappings.conf"))
    for k, v in pairs(mappings) do
        if peripherals[v.dev] == nil then
            peripherals[v.dev] = { device = peripherals.wrap(v.dev), sides = { [v.side] = 0 } }
        else
            peripherals[v.dev].sides[v.side] = 0
        end
    end
end

function module.set_output(port, value)
    local mapping = mappings[port]
    local peri = peripherals[mapping.dev]
    local currentValue = peri.sides[mapping.side]
    if value then
        currentValue = bit32.bor(currentValue, bit32.lshift(1, mapping.bit))
    else
        currentValue = bit32.band(currentValue, bit32.bnot(bit32.lshift(1, mapping.bit)))
    end
end

return module
