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
end

module.manualControl = {
    order = { "top_bar", "button_back", "top_bar_text", "button_spin_basin", "item_ingredient_group" },
    top_bar = { type = "panel", x = 1, y = 1, height = 1, width = 39, color = colors.blue },
    button_back = { type = "button", x = 39-3, y = 1, height = 1, width = 4, bg = colors.red, fg = colors.white, text = "Back", handler = function ()
        windows.setGui(module.start())
    end},
    top_bar_text = { type = "text", x = 1, y = 1, height = 1, width = 39, bg = colors.blue, text = "Manual Control" },
    button_spin_basin = { type = "button", x = 2, y = 3, height = 3, width = 18, fg = colors.white, bg = colors.gray, text = "Spin Basins", handler = function ()
        control.spinBasins()
    end},
    item_ingredient_group = { type = "group", x = 20, y = 4, visible = false, elements = {
        order = { "top_bar", "top_bar_text" },
        top_bar = { type = "panel", x = 1, y = 1, width = 13, height = 1, color = colors.blue },
        top_bar_text = { type = "text", x = 1, y = 1, bg = colors.blue, fg = colors.white, text = "Ingredients" },
        panel = { type = "panel", x = 1, y = 2, width = 13, height = 4, color = colors.white },
        sugar_button = { type = "button", x = 1, y = 3, width = 5, height = 1, bg = colors.white, fg = colors.black, text = "Sugar", handler = function (window) selectIngredient("sugar", window) end },
        beans_button = { type = "button", x = 1, y = 4, width = 11, height = 1, bg = colors.white, fg = colors.black, text = "Cocoa Beans", handler = function (window) selectIngredient("cocoa_beans", window) end },
        powder_button = { type = "button", x = 1, y = 5, width = 12, height = 1, bg = colors.white, fg = colors.black, text = "Cocoa Powder", handler = function (window) selectIngredient("cocoa_powder", window) end },
        butter_button = { type = "button", x = 1, y = 6, width = 12, height = 1, bg = colors.white, fg = colors.black, text = "Cocoa Butter", handler = function (window) selectIngredient("cocoa_butter", window) end }
    } },
    button_prepare_ingredient = { type = "button", x = 19, y = 3, height = 3, width = 18, fg = colors.white, bg = colors.gray, text = "Ingredient", handler = function (window)
        window.item_ingredient_group.visible = true
    end}
}

return module
