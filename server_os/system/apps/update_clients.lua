local component = rawget(_G, "component")

if not component then
    component = require("component")
end

local computer = rawget(_G, "computer")

if not computer then
    computer = require("computer")
end

local common = YellowOS.common
local gpu = common.gpu
local PORT = 24120
local MANIFEST_URL = "https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/user/manifest.txt"
local internetAddress = component.list("internet")()
local modemAddress = component.list("modem")()

if not internetAddress then
    common.message("Update Clients", "Internet Card not found")
    return
end

if not modemAddress then
    common.message("Update Clients", "Wireless Network Card not found")
    return
end

local internet = component.proxy(internetAddress)
local modem = component.proxy(modemAddress)

local function download(url)
    local request, reason = internet.request(url)

    if not request then
        return nil, reason
    end

    local data = ""

    while true do
        local chunk, readReason = request.read(2048)

        if chunk then
            data = data .. chunk
        elseif readReason then
            request.close()
            return nil, readReason
        else
            break
        end
    end

    request.close()
    return data
end

common.header("Update Clients")
gpu.setForeground(0xFFFFFF)
gpu.set(3, 6, "Checking latest User Edition...")
local cacheKey = tostring(math.floor(computer.uptime() * 1000))
local manifest, reason = download(MANIFEST_URL .. "?t=" .. cacheKey)

if not manifest then
    common.message("Update Clients", "Failed to check release:\n" .. tostring(reason))
    return
end

local version = manifest:match("version=([^\r\n]+)") or "unknown"
local size = tonumber(manifest:match("size=(%d+)")) or 0
local targetChoice = common.menu("Update Clients", "Version " .. version .. " | " .. common.formatBytes(size), {"YellowPad", "YellowPad Lite", "YellowPad Pro", "All YellowPads", "Cancel"})

if not targetChoice or targetChoice == 5 then
    return
end

local targets = {"YellowPad", "YellowPad Lite", "YellowPad Pro", "ALL"}
local targetDevice = targets[targetChoice]
local confirm = common.menu("Confirm Update", "Target: " .. targetDevice, {"Send update", "Cancel"})

if confirm ~= 1 then
    return
end

modem.open(PORT)
modem.broadcast(PORT, "YELLOWOS_UPDATE", version, size, targetDevice)
common.message("Update Clients", "Update notification sent.\nTarget: " .. targetDevice .. "\nVersion: " .. version .. "\nSize: " .. common.formatBytes(size))
