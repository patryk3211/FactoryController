local module = {}

-- Line Format: <Entry Name> <Peripheral ID>/<Side>:<Bit>
local function parseConfigLine(line)
    if string.sub(line, 1, 1) == '#' then
        return nil;
    end

    local key, peri, side, bit = string.match(line, "(%a+) ([%w_]+)/(%a+):(%d)")

    print("New entry ('"..key.."') - side "..side.." of '"..peri.."', bit "..bit)

    return key, { dev = peri, side = side, bit = bit }
end

function module.loadConfig(filename)
    local entries = { }

    for line in io.lines(filename) do
        local key, entry = parseConfigLine(line)
        if key ~= nil then
            entries[key] = entry
        end
    end

    return entries
end

return module
