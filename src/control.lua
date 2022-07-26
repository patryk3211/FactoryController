local module = {}

local redstoneMgr = require("redstone")
local utility = require("utility")
local config = require("config")
local state = require("state")

local controlConfig = nil
local ingredientReaderMap = {}

local activeProcesses = 0
local ingredientCheckList = {}

local mixer = nil

local eventHandler = nil

function module.loadConfig()
    controlConfig = config.loadConfig(shell.resolve("config/control.conf"), "values")
    if controlConfig == nil then
        error("Unexpected nil config")
    end

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

    mixer = peripheral.wrap(controlConfig.mixer)
end

function module.setEventHandler(handler)
    eventHandler = handler
end

local function checkIngredientArrived(timeout)
    local count = nil
    for i = 1, 3 do
        count = 0
        for ingredient, check in pairs(ingredientCheckList) do
            local itemCount = check.reader.getBlockData().handler.BigItems["0"].Amount

            if itemCount >= check.amount then
                redstoneMgr.setOutput(ingredient.."-transfer", false)
                redstoneMgr.pulse(ingredient.."-output")
                ingredientCheckList[ingredient] = nil
                count = count - 1
                utility.scheduleTimer(2, function ()
                    activeProcesses = activeProcesses - 1
                    -- os.queueEvent("control", "ingredient_arrived", ingredient)
                    eventHandler("ingredient_arrived")
                end)
            end

            count = count + 1
        end
    end

    if count > 0 then
        utility.scheduleTimer(0.05, checkIngredientArrived, 0)
    end
end

function module.outputIngredient(ingredient, amount)
    activeProcesses = activeProcesses + 1
    redstoneMgr.setOutput(ingredient.."-transfer", true)
    if #ingredientCheckList == 0 then
        utility.scheduleTimer(0.05, checkIngredientArrived, 0)
    end

    local reader = ingredientReaderMap[ingredient]
    if reader == nil then
        error("An unknown ingredient was requested")
        return
    end
    ingredientCheckList[ingredient] = { reader = reader, amount = amount }
end

function module.spinBasins(dispense)
    if dispense == nil then
        dispense = true
    end

    activeProcesses = activeProcesses + 1
    redstoneMgr.pulse("basin_control")
    utility.scheduleTimer(1.5, function ()
        state.basinPosition = (state.basinPosition + 1) % 4
        if state.basinPosition == 0 then
            activeProcesses = activeProcesses - 1
            -- os.queueEvent("control", "basin_ready")
            eventHandler("basin_ready")
        else
            if dispense then
                redstoneMgr.setOutput("dispenser_"..state.basinPosition, true)
                utility.scheduleTimer(0.3, function ()
                    redstoneMgr.setOutput("dispenser_"..state.basinPosition, false)
                end)
                utility.scheduleTimer(1, function ()
                    activeProcesses = activeProcesses - 1
                    -- os.queueEvent("control", "basin_ready")
                    eventHandler("basin_ready")
                end)
            else
                activeProcesses = activeProcesses - 1
                -- os.queueEvent("control", "basin_ready")
                eventHandler("basin_ready")
            end
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
        -- os.queueEvent("control", "valve_switched", newValve)
        eventHandler("valve_switched")
    end)
end

local function waitForLiquid(name, timeout)
    if redstoneMgr.getInput("liquid_ready") then
        activeProcesses = activeProcesses - 1
        -- os.queueEvent("control", "liquid_ready")
        eventHandler("liquid_ready")
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
        -- os.queueEvent("control", "liquid_empty")
        eventHandler("liquid_empty")
    else
        utility.scheduleTimer(0.1, waitInputTankEmpty)
    end
end

function module.emptyInputTank()
    activeProcesses = activeProcesses + 1
    waitInputTankEmpty()
end

local function waitPumpOutEnd()
    if redstoneMgr.getInput("output_empty") then
        activeProcesses = activeProcesses - 1
        -- os.queueEvent("control", "output_empty")
        eventHandler("output_empty")
    else
        utility.scheduleTimer(0.1, waitPumpOutEnd)
    end
end

local function waitPumpOutStart(timeout)
    if timeout >= 100 then
        activeProcesses = activeProcesses - 1
        -- os.queueEvent("control", "output_empty")
        eventHandler("output_empty")
        print("Product pump out timed out trying to start, might have been empty")
        return
    end

    if redstoneMgr.getInput("output_empty") then
        utility.scheduleTimer(0.1, waitPumpOutStart, timeout + 1)
    else
        waitPumpOutEnd()
    end
end

function module.outputLiquidProduct()
    activeProcesses = activeProcesses + 1
    waitPumpOutStart(0)
end

local function waitItemOutputEnd()
    if redstoneMgr.getInput("output_empty") then
        activeProcesses = activeProcesses - 1
        redstoneMgr.setOutput("output_enable", false)
        -- os.queueEvent("control", "output_empty")
        eventHandler("output_empty")
    else
        utility.scheduleTimer(0.1, waitItemOutputEnd)
    end
end

local function waitItemOutputStart(timeout)
    if timeout >= 100 then
        activeProcesses = activeProcesses - 1
        redstoneMgr.setOutput("output_enable", false)
        -- os.queueEvent("control", "output_empty")
        eventHandler("output_empty")
        print("Product output timed out trying to start, might have been empty")
        return
    end

    if redstoneMgr.getInput("output_empty") then
        utility.scheduleTimer(0.1, waitItemOutputStart, timeout + 1)
    else
        waitItemOutputEnd()
    end
end

function module.outputItemProduct()
    activeProcesses = activeProcesses + 1
    redstoneMgr.setOutput("output_enable", true)
    waitItemOutputStart(0)
end

function module.mixerHasBasin()
    return mixer.hasBasin()
end

local function isMixerMixing()
    return mixer.isRunning()
end

local function waitRecipeEnd()
    if not isMixerMixing() then
        activeProcesses = activeProcesses - 1
        -- os.queueEvent("control", "recipe_finished")
        eventHandler("recipe_finished")
    else
        utility.scheduleTimer(0.1, waitRecipeEnd)
    end
end

function module.recipeStart()
    activeProcesses = activeProcesses + 1
    waitRecipeEnd()
end

function module.isBusy()
    return activeProcesses ~= 0
end

return module
