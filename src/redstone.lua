local config = require("config")

local mappings = nil

function load_mappings()
    mappings = config.load_config("config/mappings.conf")
end
