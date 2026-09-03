local component = rawget(_G, "component")

if not component then
    component = require("component")
end

local computer = rawget(_G, "computer")

if not computer then
    computer = require("computer")
end

local PORT = 24120
local MANIFEST_URL = "https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/user/manifest.txt"

local internetAddress = component.list("internet")()
local modemAddress = component.list("modem")()

if not internetAddress then
    error("Internet Card not found")
end

if not modemAddress then
    error("Wireless Network Card not found")
end

local internet = component.proxy(internetAddress)
local modem = component.proxy(modemAddress)

local function download(url)
    local request, reason = internet.request(url)

    if not request then
        error("Request failed: " .. tostring(reason))
    end

    local data = ""

    while true do
        local chunk, readReason = request.read(2048)

        if chunk then
            data = data .. chunk
        elseif readReason then
            request.close()
            error("Read failed: " .. tostring(readReason))
        else
            break
        end
    end

    request.close()
    return data
end

local cacheKey = tostring(math.floor(computer.uptime() * 1000))
local manifest = download(MANIFEST_URL .. "?t=" .. cacheKey)
local version = manifest:match("version=([^\r\n]+)") or "unknown"
local size = tonumber(manifest:match("size=(%d+)")) or 0

modem.open(PORT)
modem.broadcast(PORT, "YELLOWOS_UPDATE", version, size)

print("YellowOS update notification sent")
print("Version: " .. version)
print("Size: " .. size .. " bytes")
