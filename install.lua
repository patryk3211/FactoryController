local rootPath = "https://raw.githubusercontent.com/patryk3211/FactoryController/master/src/"
local files = { "config.lua", "redstone.lua", "main.lua" }

local installRoot = "/controller/"

fs.delete(installRoot)
fs.makeDir(installRoot)
shell.setDir(installRoot)

for file in files do
    shell.execute("wget", rootPath..file)
end

-- Create config dir
fs.makeDir(shell.resolve("config"))
