if not http then
    error("Unable to perform update, HTTP API is disabled")
end

local display = peripheral.find("monitor")
display.setBackgroundColor(colors.lightGray)
display.setTextColor(colors.gray)
local displayWidth, displayHeight = display.getSize()

local function writeText(text, yOffset)
    local textLength = text:len()
    display.setCursorPos(1 + displayWidth / 2 - textLength / 2, displayHeight / 2 + yOffset)
    display.write(text)
end

-- [########      ]
local function writeProgressBar(value, maxValue, width, yOffset)
    local fraction = value / maxValue
    local filledSize = math.floor((width - 2) * fraction)

    local text = ""

    for i = 1, filledSize do
        text = text.."#"
    end

    for i = 1, width - 2 - filledSize do
        text = text.." "
    end

    display.setCursorPos(1 + displayWidth / 2 - width / 2, displayHeight / 2 + yOffset)
    display.write("[")
    display.setTextColor(colors.white)
    display.write(text)
    display.setTextColor(colors.gray)
    display.write("]")
end

local filesToUpdate = { "config.lua", "control.lua", "guis.lua", "main.lua", "recipes.lua", "redstone.lua", "state.lua", "utility.lua", "windows.lua" }
local website = "https://raw.githubusercontent.com/patryk3211/FactoryController/master/"

display.clear()
writeText("Checking version", 0)
sleep(1)

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

    local progressMax = #filesToUpdate

    for i = 1, progressMax do
        display.clear()
        writeText("Updating...", -1)
        writeText("Please do not turn off your computer", 0)
        writeProgressBar(i, progressMax, 22, 1)

        local filename = filesToUpdate[i]

        writeText("Downloading "..filename, 2)
        local remote = readRemoteFile("src/"..filename)
        if remote ~= nil then
            local file = io.open("/controller/"..filename, "w+")
            file:write(remote)
            file:close()
        end

        sleep(0.1)
    end
else
    display.clear()
    writeText("Up to date!", 0)
    sleep(2)
end

display.clear()
writeText("Rebooting", 0)
sleep(2)

os.reboot()
