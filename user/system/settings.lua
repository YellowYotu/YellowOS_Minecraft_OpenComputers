local fs = YellowOS.fs
local settings = {
    autoUpdates = true,
    updateChannel = "stable",
    browserHome = "https://example.com",
    serverPort = 24120
}

local function load()
    if not fs.exists("/system/settings.cfg") then
        return
    end

    local handle = fs.open("/system/settings.cfg", "r")

    if not handle then
        return
    end

    local data = ""

    while true do
        local chunk = fs.read(handle, 1024)

        if not chunk then
            break
        end

        data = data .. chunk
    end

    fs.close(handle)

    for line in data:gmatch("[^\r\n]+") do
        local key, value = line:match("^([^=]+)=(.*)$")

        if key == "autoUpdates" then
            settings.autoUpdates = value == "true"
        elseif key == "updateChannel" then
            settings.updateChannel = value
        elseif key == "browserHome" then
            settings.browserHome = value
        elseif key == "serverPort" then
            settings.serverPort = tonumber(value) or 24120
        end
    end
end

function settings.save()
    local handle = fs.open("/system/settings.cfg", "w")

    if not handle then
        return false
    end

    fs.write(handle, "autoUpdates=" .. tostring(settings.autoUpdates) .. "\n")
    fs.write(handle, "updateChannel=" .. settings.updateChannel .. "\n")
    fs.write(handle, "browserHome=" .. settings.browserHome .. "\n")
    fs.write(handle, "serverPort=" .. tostring(settings.serverPort) .. "\n")
    fs.close(handle)
    return true
end

load()
YellowOS.settings = settings
