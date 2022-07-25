local module = {}

-- Line Format: <Entry Name> <Peripheral ID>/<Side>:<Bit>
local function parseMappingConfigLine(line)
    if string.sub(line, 1, 1) == '#' then
        return nil;
    end

    local key, peri, side, bit = string.match(line, "([%w_%-]+) ([%w_]+)/(%a+):(%d)")

    print("New entry ('"..key.."') - side "..side.." of '"..peri.."', bit "..bit)

    return key, { dev = peri, side = side, bit = bit }
end

local function loadMappingConfig(filename)
    local entries = { }

    for line in io.lines(filename) do
        local key, entry = parseMappingConfigLine(line)
        if key ~= nil then
            entries[key] = entry
        end
    end

    return entries
end

local function parseValuesConfigLine(line)
    if string.sub(line, 1, 1) == '#' then
        return nil;
    end

    return string.match(line, "([%w_]+)%s*=%s*([%w_%.]+)")
end

local function loadValuesConfig(filename)
    local entries = { }

    for line in io.lines(filename) do
        local key, value = parseValuesConfigLine(line)
        if key ~= nil then
            entries[key] = value
        end
    end

    return entries
end

function module.loadConfig(filename, type)
    if type == "mapping" then
        return loadMappingConfig(filename)
    elseif type == "values" then
        return loadValuesConfig(filename)
    else
        return nil
    end
end

return module
