local component = component
local computer = computer

local bootAddress = computer.getBootAddress()

if not bootAddress then
    error("Boot drive not found")
end

local fs = component.proxy(bootAddress)

local function readAll(path)
    local handle = fs.open(path, "r")

    if not handle then
        return nil
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
    return data
end

local function loadFile(path)
    local data = readAll(path)

    if not data then
        error("Cannot open " .. path)
    end

    local program, loadReason = load(data, "=" .. path, "t", _ENV)

    if not program then
        error(loadReason)
    end

    return program()
end

local device = "YellowPad Lite"
local profile = readAll("/system/device.cfg")

if profile then
    local configuredDevice = profile:match("device=([^\r\n]+)")

    if configuredDevice and configuredDevice ~= "" then
        device = configuredDevice
    end
end

_G.YellowOS = {
    fs = fs,
    loadFile = loadFile,
    version = "0.2.2",
    edition = "User Edition",
    device = device
}

loadFile("/system/boot.lua")
