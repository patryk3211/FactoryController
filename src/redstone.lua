local module = {}

local config = require("config")

local mappings = nil

function module.load_mappings()
    mappings = config.load_config("/config/mappings.conf")
end

return module
