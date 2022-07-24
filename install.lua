local rootPath = "https://raw.githubusercontent.com/patryk3211/FactoryController/master/src/"
local files = { "config.lua", "redstone.lua", "main.lua", "utility.lua" }

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
local confFile = io.open(shell.resolve("config/mappings.conf"), "w+")
confFile:write("# This file should contain the mappings for redstone signals in the following format:\n# <Mapping Name> <Peripheral ID>/<Side>:<Bit>\nexample redstoneIntegrator_0/left:0")
confFile:close()

print("Configs generated")

print("Install complete")
