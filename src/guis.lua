local module = {}

local recipeMgr = require("recipes")
local windows = require("windows")

module.start = {
    order = { "top_bar", "button_start", "button_select_recipe" },
    button_start = { type = "button", x = 11, y = 3, width = 19, height = 5, text = "Start", fg = colors.white, bg = colors.gray, handler = nil },
    button_select_recipe = { type = "button", x = 11, y = 9, width = 19, height = 5, text = "Select Recipe", fg = colors.white, bg = colors.gray, handler = function ()
        windows.setGui(module.recipes())
    end},
    top_bar = { type = "panel", x = 1, y = 1, height = 1, width = 39, color = colors.blue }
}

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
            recipeScreen[id.."_button"] = { type = "button", x = 1, y = y, height = 1, width = 39, fg = colors.black, bg = color, text = "", handler = function()
                print("Selected '"..id.."' recipe")
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

return module
