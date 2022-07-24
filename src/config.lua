local module = {}

-- Line Format: <Entry Name> <Peripheral ID>/<Side>:<Bit>
local function parse_config_line(line)
    if line[1] == '#' then
        return;
    end

    local key, peri, side, bit = string.match(line, "(%a+) (%w+)/(%a+):(%d)")

    print("New entry ('"..key.."') - side "..side.." of '"..peri.."', bit "..bit)

    return key, { dev = peri, side = side, bit = bit }
end

function module.load_config(filename)
    local entries = { }

    for line in io.lines(filename) do
        local key, entry = parse_config_line(line)
        entries[key] = entry
    end

    return entries
end

return module
