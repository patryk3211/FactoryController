local rootPath = "https://raw.githubusercontent.com/patryk3211/FactoryController/master/src/"
local files = { "config.lua", "redstone.lua", "main.lua", "utility.lua", "windows.lua", "control.lua" }

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
controlConfFile:write("ingredientTransferRate = 1")
controlConfFile:close()

print("Configs generated")

print("Install complete")
