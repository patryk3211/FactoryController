local control = require "control"
local utility = require "utility"
local module = {}

local recipes = {}

local currentContext = nil

local function parseRecipe(file)
    print("Loading recipe '"..file.."'")

    local id = file:match("([%w_]+)%.%a+")
    local recipe = { name = id, init = {}, loop = {} }
    local currentList = nil
    for line in io.lines(shell.resolve("recipes/"..file)) do
        if line:sub(1, 1) ~= "#" then
            local key, value = string.match(line, "([%w_]+)=([%w_]+)")
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
                recipe.actions[#recipe.actions+1] = line
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

    local instruction, arg1, arg2 = line:match("([%w_]+)%s*([%w_]+)?%s*([%w_%.]+)?%s*")

    if instruction == "output" then
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
            context.wait = "idle"
            return "wait"
        elseif arg1 == "event" then
            context.wait = "event"
            context.wait_event = arg2
            return "wait"
        else
            error("Unknown wait parameter '"..arg1.."'")
        end
    elseif instruction == "pump_in" then
        control.emptyInputTank()
    elseif instruction == "pump_out" then
        control.outputProduct()
    else
        error("Unknown instruction '"..instruction.."'")
    end
end

local function interpret(context)
    if context.stop then
        os.queueEvent("recipe_stopped")
        return
    end
    for i = 1, 8 do
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
    end
    utility.scheduleTimer(0.05, interpret, context)
end

function module.handleControlEvent(eventData)
    if currentContext == nil or currentContext.wait == nil then
        return
    end
    local event = eventData[2]

    if currentContext.wait == "idle" then
        if not control.isBusy() then
            currentContext.wait = nil
            interpret(currentContext)
        end
    elseif currentContext.wait == "event" then
        if currentContext.wait_event == event then
            currentContext.wait = nil
            currentContext.wait_event = nil
            interpret(currentContext)
        end
    end
end

function module.startRecipe(recipeId)
    local context = {
        recipe = recipes[recipeId],
        current_list = "init",
        current_line = 1,
        stop = false
    }

    utility.scheduleTimer(0.05, interpret, context)
    currentContext = context;

    return context
end

return module
