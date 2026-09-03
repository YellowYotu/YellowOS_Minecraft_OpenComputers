local component = require("component")
local filesystem = require("filesystem")
local computer = require("computer")
local target = ... or "/mnt/d6e"
local BASE_URL = "https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/server_os/"
local internetAddress = component.list("internet")()

if not internetAddress then
    error("Internet Card not found")
end

if not filesystem.exists(target) then
    error("Target path not found: " .. target)
end

local internet = component.proxy(internetAddress)

local function download(url)
    local request, reason = internet.request(url)

    if not request then
        error("Request failed: " .. tostring(reason))
    end

    local data = ""

    while true do
        local chunk, readReason = request.read(4096)

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

local function ensureDirectory(path)
    local directory = filesystem.path(path)

    if directory and directory ~= "" and not filesystem.exists(directory) then
        filesystem.makeDirectory(directory)
    end
end

local cacheKey = tostring(math.floor(computer.uptime() * 1000))
local manifest = download(BASE_URL .. "manifest.txt?t=" .. cacheKey)
local version = manifest:match("version=([^\r\n]+)") or "unknown"
local size = tonumber(manifest:match("size=(%d+)")) or 0

print("YellowOS Server Edition " .. version)
print("Target: " .. target)
print("Download size: " .. size .. " bytes")

for line in manifest:gmatch("[^\r\n]+") do
    if not line:match("^[%w_]+=") and line ~= "" and line:sub(1, 1) ~= "#" then
        local destination = target .. "/" .. line
        print("Installing " .. line)
        local data = download(BASE_URL .. line .. "?t=" .. cacheKey)
        ensureDirectory(destination)
        local file, reason = io.open(destination, "w")

        if not file then
            error("Cannot write " .. destination .. ": " .. tostring(reason))
        end

        file:write(data)
        file:close()
    end
end

print("Server update complete. Version " .. version)
print("Reboot to start the new version.")
