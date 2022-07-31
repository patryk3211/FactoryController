local rootPath = "https://raw.githubusercontent.com/patryk3211/FactoryController/master/"
local files = { "config.lua", "redstone.lua", "main.lua", "utility.lua", "windows.lua", "control.lua", "guis.lua", "state.lua", "recipes.lua", "updater.lua" }
local recipes = { "chocolate.rec" }

local installRoot = "/controller/"

local function downloadFile(file)
    shell.execute("wget", rootPath..file)
end

fs.delete(installRoot)
fs.makeDir(installRoot)
shell.setDir(installRoot)

for i, file in ipairs(files) do
    downloadFile("src/"..file)
end

print("Files downloaded successfully")

-- Create config dir
fs.makeDir(installRoot.."config")

-- Download configs
shell.setDir(installRoot.."config")
downloadFile("mappings.conf")

local controlConfFile = io.open(installRoot.."config/control.conf", "w+")
controlConfFile:write("blockReaders = blockReader_0:sugar;blockReader_1:cocoa_beans,cocoa_powder;blockReader_2:cocoa_butter")
controlConfFile:write("mixer = mechanicalMixer_0")
controlConfFile:close()

print("Configs ready")

fs.makeDir(installRoot.."recipes")
shell.setDir(installRoot.."recipes")
for i, file in ipairs(recipes) do
    downloadFile("src/recipes/"..file)
end

print("Recipes downloaded")

shell.setDir(installRoot)
downloadFile("version")

local monitor = io.open(installRoot.."monitor", "w+")
monitor:write("monitor_0")
monitor:close()

print("Adding to startup")
fs.makeDir("/startup")
local starterFile = io.open("/startup/controllerStart.lua", "w+")
starterFile:write("shell.setDir(\"/controller\")\nshell.execute(\"main\")")
starterFile:close()

print("Install complete")
