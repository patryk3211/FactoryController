local rootPath = "https://raw.githubusercontent.com/patryk3211/FactoryController/master/src/"
local files = { "config.lua", "redstone.lua", "main.lua", "utility.lua", "windows.lua", "control.lua", "guis.lua", "state.lua" }

local installRoot = "/controller/"

fs.delete(installRoot)
fs.makeDir(installRoot)
shell.setDir(installRoot)

for i, file in ipairs(files) do
    shell.execute("wget", rootPath..file)
end

print("Files downloaded successfully")

-- Create config dir
fs.makeDir(shell.resolve("config"))

-- Make example config
local mapFile = io.open(shell.resolve("config/mappings.conf"), "w+")
mapFile:write("# This file should contain the mappings for redstone signals in the following format:\n# <Mapping Name> <Peripheral ID>/<Side>:<Bit>\n")
mapFile:write("sugar-transfer\nsugar-output\nbasin_control\n");
mapFile:close()

local controlConfFile = io.open(shell.resolve("config/control.conf"), "w+")
controlConfFile:write("ingredientTransferRate = 1\n")
controlConfFile:write("blockReaders = blockReader_0:sugar;blockReader_1:cocoa_beans,cocoa_powder;blockReader_2:cocoa_butter")
controlConfFile:close()

print("Configs generated")

fs.makeDir(shell.resolve("recipes"))

local chocolateRecipe = io.open(shell.resolve("recipes/chocolate.rec"), "w+")
chocolateRecipe:write("name=Chocolate\noutput=chocolate\nactions:\n")
chocolateRecipe:close()

print("Recipes generated")

print("Install complete")
