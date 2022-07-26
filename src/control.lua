local module = {}

local redstoneMgr = require("redstone")
local utility = require("utility")
local config = require("config")
local state = require("state")

local controlConfig = nil
local ingredientTransferRate = 1
local ingredientReaderMap = {}

local activeProcesses = 0

function module.loadConfig()
    controlConfig = config.loadConfig(shell.resolve("config/control.conf"), "values")
    if controlConfig == nil then
        error("Unexpected nil config")
    end

    ingredientTransferRate = controlConfig.ingredientTransferRate

    -- Block readers (blockReader_0:sugar;blockReader_1:cocoa_beans,cocoa_powder;blockReader_2:cocoa_butter)
    local blockReaders = controlConfig.blockReaders
    for readerId, values in string.gmatch(blockReaders, "([%w_]+):([%w_,]+);?") do
        local reader = peripheral.wrap(readerId)
        if reader == nil then
            error("Could not find '"..readerId.."' reader")
        end

        for ingredient in string.gmatch(values, "([%w_]+),?") do
            ingredientReaderMap[ingredient] = reader
            print("Ingredient '"..ingredient.."' read from "..readerId)
        end
    end

    print("Ingredient Transfer Rate = "..ingredientTransferRate)
end

local function checkIngredientArrived(ingredient, amount, timeout)
    local reader = ingredientReaderMap[ingredient]
    if reader == nil then
        error("An unknown ingredient was requested")
        return
    end

    if timeout > 200 then
        state.error = "Failed to prepare "..amount.." "..ingredient..", timed out"
        print("Failed to prepare "..amount.." "..ingredient..", timed out")
        return
    end

    -- This only works for functional storage drawers
    local data = reader.getBlockData()
    local itemCount = data.handler.BigItems["0"].Amount

    -- If the lower code is unreliable then this might fix it
    --if itemCount >= amount - ingredientTransferRate * 2 then
    --    while true do
    --        itemCount = reader.getBlockData().handler.BigItems["0"].Amount
    --        if itemCount >= amount then
    --            redstoneMgr.setOutput(ingredient.."-transfer", false)
    --            redstoneMgr.pulse(ingredient.."-output")
    --            break
    --        end
    --    end
    --else
    --    utility.scheduleTimer(0.05, checkIngredientArrived, ingredient, amount)
    --end

    if itemCount < amount then
        utility.scheduleTimer(0.05, checkIngredientArrived, ingredient, amount, timeout + 1)
    else
        redstoneMgr.setOutput(ingredient.."-transfer", false)
        redstoneMgr.pulse(ingredient.."-output")
        utility.scheduleTimer(2, function ()
            activeProcesses = activeProcesses - 1
            os.queueEvent("control", "ingredient_arrived", ingredient)
        end)
    end
end

function module.outputIngredient(ingredient, amount)
    activeProcesses = activeProcesses + 1
    redstoneMgr.setOutput(ingredient.."-transfer", true)
    utility.scheduleTimer(0.05, checkIngredientArrived, ingredient, amount, 0)
end

function module.spinBasins()
    activeProcesses = activeProcesses + 1
    redstoneMgr.pulse("basin_control")
    utility.scheduleTimer(1.5, function ()
        state.basinPosition = (state.basinPosition + 1) % 4
        if state.basinPosition ~= 0 then
            redstoneMgr.pulse("dispenser_"..state.basinPosition)
            utility.scheduleTimer(1, function ()
                os.queueEvent("control", "basin_ready")
                activeProcesses = activeProcesses - 1
            end)
        else
            os.queueEvent("control", "basin_ready")
            activeProcesses = activeProcesses - 1
        end
    end)
end

function module.setOutputTank(chocolate)
    activeProcesses = activeProcesses + 1
    if state.activeValve ~= nil then
        redstoneMgr.pulse(state.activeValve)
    end
    local newValve = "valve_"..chocolate
    redstoneMgr.pulse(newValve)
    state.activeValve = newValve
    utility.scheduleTimer(1, function ()
        activeProcesses = activeProcesses - 1
        os.queueEvent("control", "valve_switched", newValve)
    end)
end

local function waitForLiquid(name, timeout)
    if redstoneMgr.getInput("liquid_ready") then
        activeProcesses = activeProcesses - 1
        os.queueEvent("control", "liquid_ready")
        redstoneMgr.setOutput("fill_"..name, false)
    else
        if timeout > 100 then
            state.error = "Failed to prepare "..name..", timed out"
            print("Failed to prepare "..name..", timed out")
            return
        end
        utility.scheduleTimer(0.1, waitForLiquid, name, timeout + 1)
    end
end

function module.prepareLiquid(name)
    activeProcesses = activeProcesses + 1
    redstoneMgr.setOutput("fill_"..name, true)
    utility.scheduleTimer(0.1, waitForLiquid, name, 0)
end

local function waitInputTankEmpty()
    if redstoneMgr.getInput("liquid_empty") then
        activeProcesses = activeProcesses - 1
        os.queueEvent("control", "liquid_empty")
    else
        utility.scheduleTimer(0.1, waitInputTankEmpty)
    end
end

function module.emptyInputTank()
    activeProcesses = activeProcesses + 1
    waitInputTankEmpty()
end

local function waitPumpOutEnd()
    if redstoneMgr.getInput("output_tank_empty") then
        activeProcesses = activeProcesses - 1
        os.queueEvent("control", "output_tank_empty")
    else
        utility.scheduleTimer(0.1, waitPumpOutEnd)
    end
end

local function waitPumpOutStart(timeout)
    if timeout >= 100 then
        activeProcesses = activeProcesses - 1
        os.queueEvent("control", "output_tank_empty")
        print("Product pump out timed out trying to start, might have been empty")
    end

    if redstoneMgr.getInput("output_tank_empty") then
        utility.scheduleTimer(0.1, waitPumpOutStart, timeout + 1)
    else
        waitPumpOutEnd()
    end
end

function module.outputProduct()
    activeProcesses = activeProcesses + 1
    waitPumpOutStart(0)
end

function module.isBusy()
    return activeProcesses ~= 0
end

return module
