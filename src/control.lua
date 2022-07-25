local module = {}

local redstoneMgr = require("redstone")
local utility = require("utility")
local config = require("config")

local controlConfig = nil
local ingredientTransferRate = 1
local ingredientReaderMap = {}

function module.loadConfig()
    controlConfig = config.loadConfig(shell.resolve("config/control.conf"), "values")
    if controlConfig == nil then
        error("Unexpected nil config")
    end

    ingredientTransferRate = controlConfig.ingredientTransferRate

    -- Block readers (blockReader_0:sugar;blockReader_1:cocoa_beans,cocoa_powder;blockReader_2:cocoa_butter)
    local blockReaders = controlConfig.blockReaders
    for readerId, values in string.gmatch(blockReaders, "([%w_]+):(.-);?") do
        local reader = peripheral.wrap(readerId)
        if reader == nil then
            error("Could not find '"..readerId.."' reader")
        end

        for ingredient in string.gmatch(values, "([%w_]-),?") do
            ingredientReaderMap[ingredient] = reader
            print("Ingredient '"..ingredient.."' read from "..readerId)
        end
    end

    print("Ingredient Transfer Rate = "..ingredientTransferRate)
end

local function checkIngredientArrived(ingredient, amount)
    local reader = ingredientReaderMap[ingredient]
    if reader == nil then
        error("An unknown ingredient was requested")
        return
    end

    -- This only works for functional storage drawers
    local data = reader.getBlockData()
    local itemCount = data.handler.BigItems["0"].Amount

    if itemCount < amount then
        utility.scheduleTimer(0.05, checkIngredientArrived, ingredient, amount)
    else
        redstoneMgr.setOutput(ingredient.."-transfer", false)
        redstoneMgr.pulse(ingredient.."-output")
    end
end

function module.outputIngredient(ingredient, amount)
    redstoneMgr.setOutput(ingredient.."-transfer", true)
    utility.scheduleTimer(0.05, checkIngredientArrived, ingredient, amount)
end

function module.spinBasins()
    redstoneMgr.pulse("basin_control")
end

return module
