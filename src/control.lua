local module = {}

local redstoneMgr = require("redstone")
local utility = require("utility")
local config = require("config")

local controlConfig = nil
local ingredientTransferRate = 1

function module.loadConfig()
    controlConfig = config.loadConfig(shell.resolve("config/control.conf"), "values")
    if controlConfig == nil then
        error("Unexpected nil config")
    end

    ingredientTransferRate = controlConfig.ingredientTransferRate
end

function module.outputIngredient(ingrediant, amount)
    redstoneMgr.setOutput(ingrediant.."-transfer", true)
    -- Wait for items to transfer
    utility.scheduleTimer(math.ceil(amount / ingredientTransferRate) * 0.05, function ()
        redstoneMgr.setOutput(ingrediant.."-transfer", false)

        -- Activate output funnel
        redstoneMgr.setOutput(ingrediant.."-output", true)
        utility.scheduleTimer(0.1, function ()
            redstoneMgr.setOutput(ingrediant.."-output", false)
        end)
    end)
end

function module.spinBasins()
    redstoneMgr.setOutput("basin_control", true)
    utility.scheduleTimer(0.1, function ()
        redstoneMgr.setOutput("basin_control", false)
    end)
end

return module
