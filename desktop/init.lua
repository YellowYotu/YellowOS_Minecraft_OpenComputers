local component = rawget(_G, "component")
local computer = rawget(_G, "computer")

if not component or not computer then
    error("OpenComputers boot environment is missing component/computer globals")
end

local bootAddress = computer.getBootAddress()
if not bootAddress then error("Boot drive not found") end
local fs = component.proxy(bootAddress)

local function readAll(path)
    local handle, reason = fs.open(path, "r")
    if not handle then return nil, reason end
    local data = ""
    while true do
        local chunk = fs.read(handle, 2048)
        if not chunk then break end
        data = data .. chunk
    end
    fs.close(handle)
    return data
end

local function loadFile(path)
    local data, reason = readAll(path)
    if not data then error("Cannot open " .. path .. ": " .. tostring(reason)) end
    local program, loadReason = load(data, "=" .. path, "t", _ENV)
    if not program then error(loadReason) end
    return program()
end

_G.YellowOS = {
    fs = fs,
    bootAddress = bootAddress,
    loadFile = loadFile,
    readAll = readAll,
    version = "0.2.1",
    edition = "Desktop Edition"
}

loadFile("/system/boot.lua")
