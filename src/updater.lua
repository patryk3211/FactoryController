if not http then
    error("Unable to perform update, HTTP API is disabled")
end

local display = peripheral.find("monitor")
display.setBackgroundColor(colors.lightGray)
display.setTextColor(colors.gray)
local displayWidth, displayHeight = display.getSize()

local function writeText(text, yOffset)
    local textLength = text:len()
    display.setCursorPos(displayWidth / 2 - textLength / 2, displayHeight / 2 + yOffset)
    display.write(text)
end

-- [########      ]
local function writeProgressBar(value, maxValue, width, yOffset)
    local fraction = value / maxValue
    local filledSize = math.floor((width - 2) * fraction)

    local filledText = ""
    local emptyText = ""

    for i = 1, filledSize do
        filledText = filledText.." "
    end

    for i = 1, width - 2 - filledSize do
        emptyText = emptyText.." "
    end

    display.setCursorPos(displayWidth / 2 - width / 2, displayHeight / 2 + yOffset)
    display.write("[")
    display.setBackgroundColor(colors.white)
    display.write(filledText)
    display.setBackgroundColor(colors.lightGray)
    display.write(emptyText)
    display.write("]")
end

local filesToUpdate = { "config.lua", "control.lua", "guis.lua", "main.lua", "recipes.lua", "redstone.lua", "state.lua", "utility.lua", "windows.lua" }
local website = "https://raw.githubusercontent.com/patryk3211/FactoryController/master/"

display.clear()
writeText("Checking version", 0)

local function readRemoteFile(file)
    local response = http.get(website..file)
    if response == nil then
       print("Failed to get file '"..file.."'")
       return nil
    end
    return response.readAll()
end

local remoteVersion = readRemoteFile("version")

local versionFile = io.open("/controller/version", "r")
local localVersion = versionFile:read("a")

versionFile:close()

if localVersion ~= remoteVersion then
    display.clear()
    writeText("Updating to version "..remoteVersion, 0)
    sleep(2)

    for i = 0, 20 do
        writeProgressBar(i, 20, 22, 1)
        sleep(1)
    end

else
    writeText("Up to date!", 0)
    sleep(2)
end
