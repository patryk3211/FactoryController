local rootPath = "https://raw.githubusercontent.com/patryk3211/FactoryController/master/src/"
local files = { "config.lua", "redstone.lua", "main.lua" }

for file in files do
    os.run({}, "/rom/programs/http/wget", rootPath..file)
end
