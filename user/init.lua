local component = component
local computer = computer

local bootAddress = computer.getBootAddress()

if not bootAddress then
    error("Boot drive not found")
end

local fs = component.proxy(bootAddress)

local function loadFile(path)
    local handle, reason = fs.open(path, "r")

    if not handle then
        error("Cannot open " .. path .. ": " .. tostring(reason))
    end

    local data = ""

    while true do
        local chunk = fs.read(handle, 2048)

        if not chunk then
            break
        end

        data = data .. chunk
    end

    fs.close(handle)

    local program, loadReason = load(data, "=" .. path, "t", _ENV)

    if not program then
        error(loadReason)
    end

    return program()
end

_G.YellowOS = {
    fs = fs,
    loadFile = loadFile,
    version = "0.2.0",
    edition = "User Edition",
    device = "YellowPad Lite"
}

loadFile("/system/boot.lua")
