-- Load configs

local redstoneMgr = require("redstone")
local utility = require("utility")
local windows = require("windows")
local control = require("control")
local guis = require("guis")
local recipes = require("recipes")
local state   = require("state")

windows.start()
redstoneMgr.loadMappings()
control.loadConfig()
recipes.load()

print("Initialized successfully")

windows.setGui(guis.start())

-- Program loop
local running = true
local recipeContext = nil
while running do
    local eventData = { os.pullEvent() }
    local event = eventData[1]

    if event == "timer" then
        utility.handleTimerEvent(eventData)
    elseif event == "monitor_touch" then
        windows.handleTouch(eventData)
        windows.redraw()
    elseif event == "start_recipe" then
        recipeContext = recipes.startRecipe(state.recipe)
    elseif event == "stop_recipe" then
        recipeContext.stop = true
    elseif event == "recipe_stopped" then
        recipeContext = nil
        windows.setGui(guis.start())
    elseif event == "control" then
        recipes.handleControlEvent(eventData)
    end
end
