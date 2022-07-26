local module = {}

local recipeMgr = require("recipes")
local windows = require("windows")
local state = require("state")
local control = require("control")

function module.start()
    return {
        order = { "top_bar", "top_bar_text", "button_start", "button_select_recipe", "button_manual" },
        button_start = { type = "button", x = 11, y = 3, width = 19, height = 5, text = "Start", fg = colors.white, bg = colors.gray, handler = nil },
        button_select_recipe = { type = "button", x = 11, y = 9, width = 19, height = 5, text = "Select Recipe", fg = colors.white, bg = colors.gray, handler = function ()
            windows.setGui(module.recipes())
        end},
        button_manual = { type = "button", x = 13, y = 15, width = 15, height = 3, text = "Manual", fg = colors.white, bg = colors.gray, handler = function ()
            windows.setGui(module.manualControl)
        end},
        top_bar = { type = "panel", x = 1, y = 1, height = 1, width = 39, color = colors.blue },
        top_bar_text = { type = "text", x = 1, y = 1, height = 1, width = 39, fg = colors.black, bg = colors.blue, text = "Recipe: "..recipeMgr.recipes()[state.recipe].name }
    }
end

local recipeScreen = nil
function module.recipes()
    if recipeScreen == nil then
        recipeScreen = {}

        local longestName = 12
        for id, recipe in pairs(recipeMgr.recipes()) do
            local nameLen = #recipe.name
            if longestName < nameLen then
                longestName = nameLen
            end
        end

        recipeScreen.order = { "top_bar", "name_text" }
        recipeScreen.top_bar = { type = "panel", x = 1, y = 1, height = 1, width = 39, color = colors.blue }
        recipeScreen.name_text = { type = "text", x = 1, y = 1, fg = colors.black, bg = colors.blue, text = "Recipe Name" }

        local y = 2
        for id, recipe in pairs(recipeMgr.recipes()) do
            local color = colors.lightGray
            if y % 2 == 0 then
                color = colors.white
            end
            recipeScreen[id.."_button"] = { type = "button", x = 1, y = y, height = 1, width = 39, bg = color, text = "", handler = function()
                print("Selected '"..id.."' recipe")
                state.recipe = id;
                windows.setGui(module.start())
            end }
            recipeScreen[id.."_text"] = { type = "text", x = 1, y = y, text = recipe.name, bg = color, fg = colors.black }
            recipeScreen.order[#recipeScreen.order+1] = id.."_button"
            recipeScreen.order[#recipeScreen.order+1] = id.."_text"
            y = y + 1
        end

        while y <= 19 do
            local color = colors.lightGray
            if y % 2 == 0 then
                color = colors.white
            end
            recipeScreen["panel_"..y] = { type = "panel", x = 1, y = y, height = 1, width = 39, color = color }
            recipeScreen.order[#recipeScreen.order+1] = "panel_"..y
            y = y + 1
        end
    end

    return recipeScreen
end

local function selectIngredient(name, window)
    window.item_ingredient_group.visible = false
    control.outputIngredient(name, 8)
end

local function selectFluid(name, window)
    window.fluid_ingredient_group.visible = false
    control.prepareLiquid(name)
end

local function selectOutput(name, window)
    window.output_tank_group.visible = false
    control.setOutputTank(name)
end

module.manualControl = {
    order = { "top_bar", "button_back", "top_bar_text", "button_spin_basin", "button_prepare_ingredient", "item_ingredient_group", "button_prepare_liquid", "fluid_ingredient_group", "button_output_select", "output_tank_group" },
    top_bar = { type = "panel", x = 1, y = 1, height = 1, width = 39, color = colors.blue },
    button_back = { type = "button", x = 39-3, y = 1, height = 1, width = 4, bg = colors.red, fg = colors.white, text = "Back", handler = function ()
        windows.setGui(module.start())
    end},
    top_bar_text = { type = "text", x = 1, y = 1, height = 1, width = 39, bg = colors.blue, fg = colors.black, text = "Manual Control" },
    button_spin_basin = { type = "button", x = 2, y = 3, height = 3, width = 18, fg = colors.white, bg = colors.gray, text = "Spin Basins", handler = function ()
        control.spinBasins()
    end},
    item_ingredient_group = { type = "group", x = 22, y = 4, visible = false, elements = {
        order = { "top_bar", "top_bar_text", "panel", "sugar_button", "beans_button", "powder_button", "butter_button" },
        top_bar = { type = "panel", x = 1, y = 1, width = 15, height = 1, color = colors.blue },
        top_bar_text = { type = "text", x = 1, y = 1, bg = colors.blue, fg = colors.white, text = "Ingredients" },
        panel = { type = "panel", x = 1, y = 2, width = 15, height = 4, color = colors.white },
        sugar_button = { type = "button", x = 1, y = 2, width = 7, height = 1, bg = colors.white, fg = colors.black, text = "Sugar", handler = function (window) selectIngredient("sugar", window) end },
        beans_button = { type = "button", x = 1, y = 3, width = 13, height = 1, bg = colors.white, fg = colors.black, text = "Cocoa Beans", handler = function (window) selectIngredient("cocoa_beans", window) end },
        powder_button = { type = "button", x = 1, y = 4, width = 15, height = 1, bg = colors.white, fg = colors.black, text = "Cocoa Powder", handler = function (window) selectIngredient("cocoa_powder", window) end },
        butter_button = { type = "button", x = 1, y = 5, width = 15, height = 1, bg = colors.white, fg = colors.black, text = "Cocoa Butter", handler = function (window) selectIngredient("cocoa_butter", window) end }
    } },
    button_prepare_ingredient = { type = "button", x = 21, y = 3, height = 3, width = 18, fg = colors.white, bg = colors.gray, text = "Ingredient", handler = function (window)
        window.item_ingredient_group.visible = true
    end},
    fluid_ingredient_group = { type = "group", x = 3, y = 8, visible = false, elements = {
        order = { "top_bar", "top_bar_text", "panel", "water_button", "milk_button" },
        top_bar = { type = "panel", x = 1, y = 1, width = 7, height = 1, color = colors.blue },
        top_bar_text = { type = "text", x = 1, y = 1, bg = colors.blue, fg = colors.white, text = "Fluids" },
        panel = { type = "panel", x = 1, y = 2, width = 7, height = 2, color = colors.white },
        water_button = { type = "button", x = 1, y = 2, width = 7, height = 1, bg = colors.white, fg = colors.black, text = "Water", handler = function (window) selectFluid("water", window) end },
        milk_button = { type = "button", x = 1, y = 3, width = 6, height = 1, bg = colors.white, fg = colors.black, text = "Milk", handler = function (window) selectFluid("milk", window) end }
    } },
    button_prepare_liquid = { type = "button", x = 2, y = 7, height = 3, width = 18, fg = colors.white, bg = colors.gray, text = "Base Fluid", handler = function (window)
        window.fluid_ingredient_group.visible = true
    end},
    output_tank_group = { type = "group", x = 22, y = 8, visible = false, elements = {
        order = { "top_bar", "top_bar_text", "panel", "chocolate_button", "caramel_button", "white_chocolate_button", "dark_chocolate_button", "hot_chocolate_button" },
        top_bar = { type = "panel", x = 1, y = 1, width = 17, height = 1, color = colors.blue },
        top_bar_text = { type = "text", x = 1, y = 1, bg = colors.blue, fg = colors.white, text = "Output Tanks" },
        panel = { type = "panel", x = 1, y = 2, width = 17, height = 5, color = colors.white },
        chocolate_button = { type = "button", x = 1, y = 2, width = 11, height = 1, bg = colors.white, fg = colors.black, text = "Chocolate", handler = function (window) selectOutput("chocolate", window) end },
        caramel_button = { type = "button", x = 1, y = 3, width = 11, height = 1, bg = colors.white, fg = colors.black, text = "Caramel", handler = function (window) selectOutput("caramel", window) end },
        white_chocolate_button = { type = "button", x = 1, y = 4, width = 17, height = 1, bg = colors.white, fg = colors.black, text = "White Chocolate", handler = function (window) selectOutput("white_chocolate", window) end },
        dark_chocolate_button = { type = "button", x = 1, y = 5, width = 16, height = 1, bg = colors.white, fg = colors.black, text = "Dark Chocolate", handler = function (window) selectOutput("dark_chocolate", window) end },
        hot_chocolate_button = { type = "button", x = 1, y = 6, width = 15, height = 1, bg = colors.white, fg = colors.black, text = "Hot Chocolate", handler = function (window) selectOutput("hot_chocolate", window) end }
    } },
    button_output_select = { type = "button", x = 21, y = 7, height = 3, width = 18, fg = colors.white, bg = colors.gray, text = "Output Tank", handler = function (window)
        window.output_tank_group.visible = true
    end}
}

return module
