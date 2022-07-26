local control = require "control"
local utility = require "utility"
local redstone= require "redstone"
local state   = require "state"
local module = {}

local recipes = {}

local events = {}

local currentContext = nil

local function parseRecipe(file)
    print("Loading recipe '"..file.."'")

    local id = file:match("([%w_]+)%.%a+")
    local recipe = { name = id, init = {}, loop = {} }
    local currentList = nil
    for line in io.lines(shell.resolve("recipes/"..file)) do
        if line:sub(1, 1) ~= "#" then
            local key, value = string.match(line, "([%w_]+)=([%w_%s]+)")
            if key ~= nil then
                -- Special entry
                recipe[key] = value
            else
                local listName = string.match(line, "([%w_]+):")
                if listName == nil then
                    if currentList == nil then
                        print("Error! Missing list definition")
                        return
                    end
                    recipe[currentList][#recipe[currentList]+1] = line
                else
                    currentList = listName
                end
            end
        end
    end

    recipes[id] = recipe
end

function module.load()
    local files = fs.list(shell.resolve("recipes"))
    for i, file in ipairs(files) do
        parseRecipe(file)
    end
end

function module.recipes()
    return recipes
end


local function interpretLine(context)
    local list = context.recipe[context.current_list]
    local line = list[context.current_line]
    if line == nil then
        context.current_line = 1
        if context.current_list == "init" then
            context.current_list = "loop"
            list = context.recipe[context.current_list]
        end
        line = list[context.current_line]
    end

    print("Interpreting: '"..line.."'")

    local instruction = line:match("([%w_]+)%s*");
    local arg1 = line:match("[%w_]+%s*([%w_]+)%s*");
    local arg2 = line:match("[%w_]+%s*[%w_]+%s*([%w_%.]+)%s*");

    if instruction == "output_liquid" then
        control.setOutputTank(arg1)
    elseif instruction == "base_fluid" then
        control.prepareLiquid(arg1)
    elseif instruction == "ingredient" then
        control.outputIngredient(arg1, tonumber(arg2))
    elseif instruction == "spin_basin" then
        control.spinBasins()
    elseif instruction == "wait" then
        if arg1 == "time" then
            return "sleep", tonumber(arg2)
        elseif arg1 == "idle" then
            if not control.isBusy() then
                -- Not busy, discard all unprocessed events and continue execution
                events = {}
                return
            end
            context.wait = "idle"
            return "wait"
        elseif arg1 == "event" then
            for i = 1, #events do
                -- Check for any unhandled events
                local event = events[i]
                if event == arg2 then
                    table.remove(events, i)
                    return
                end
            end
            context.wait = "event"
            context.wait_event = arg2
            return "wait"
        else
            error("Unknown wait parameter '"..arg1.."'")
        end
    elseif instruction == "pump_in" then
        control.emptyInputTank()
    elseif instruction == "pump_out" then
        control.outputLiquidProduct()
    elseif instruction == "status_text" then
        state.statusText = line:match("[%w_]+%s*(.*)")
        os.queueEvent("update_running")
    elseif instruction == "start_recipe" then
        control.recipeStart()
    elseif instruction == "item_out" then
        control.outputItemProduct()
    else
        if instruction ~= nil then
            error("Unknown instruction '"..instruction.."'")
        end
    end
end

local function interpret(context)
    if context.stop then
        os.queueEvent("recipe_stopped")
        return
    end
    --for i = 1, 8 do
        local result = { interpretLine(context) }
        context.current_line = context.current_line + 1

        if result[1] == "sleep" then
            utility.scheduleTimer(result[2], interpret, context)
            return
        elseif result[1] == "end" then
            os.queueEvent("recipe_finished")
            return
        elseif result[1] == "wait" then
            return
        end
    --end
    utility.scheduleTimer(0.05, interpret, context)
end

function module.handleControlEvent(event)
    if currentContext == nil then
        return
    end

    print("Event: "..event)

    if currentContext.wait == "idle" then
        if not control.isBusy() then
            currentContext.wait = nil
            events = {}
            utility.scheduleTimer(0.05, interpret, currentContext)
        end
    elseif currentContext.wait == "event" then
        if currentContext.wait_event == event then
            currentContext.wait = nil
            currentContext.wait_event = nil
            utility.scheduleTimer(0.05, interpret, currentContext)
        else
            table.insert(events, event)
        end
    else
        table.insert(events, event)
    end
end

local function homeBasins()
    if control.mixerHasBasin() then
        state.basinPosition = 0
        utility.scheduleTimer(0.05, interpret, currentContext)
    else
        control.spinBasins(false)
        utility.scheduleTimer(1.5, homeBasins)
    end
end

function module.startRecipe(recipeId)
    local context = {
        recipe = recipes[recipeId],
        current_list = "init",
        current_line = 1,
        stop = false
    }

    currentContext = context;
    homeBasins()

    return context
end

return module
