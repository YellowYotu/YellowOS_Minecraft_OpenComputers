local targetPrefix = ...
local component = component

if not targetPrefix or targetPrefix == "" then
    error("Usage: lua flash_user.lua <target HDD address prefix>")
end

local BASE_URL = "https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/user/"
local internetAddress = component.list("internet")()

if not internetAddress then
    error("Internet Card not found")
end

local internet = component.proxy(internetAddress)
local targetAddress = component.get(targetPrefix, "filesystem")

if not targetAddress then
    error("Target HDD not found: " .. targetPrefix)
end

local fs = component.proxy(targetAddress)

if fs.isReadOnly() then
    error("Target HDD is read-only")
end

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
    local directory = path:match("^(.*)/[^/]+$")

    if not directory or directory == "" then
        return
    end

    local current = ""

    for part in directory:gmatch("[^/]+") do
        current = current .. "/" .. part

        if not fs.exists(current) then
            fs.makeDirectory(current)
        end
    end
end

local manifest = download(BASE_URL .. "manifest.txt")
local version = manifest:match("version=([^\r\n]+)") or "unknown"
local size = tonumber(manifest:match("size=(%d+)")) or 0
local free = fs.spaceTotal() - fs.spaceUsed()

print("Target: " .. targetAddress)
print("YellowOS User Edition: " .. version)
print("Download size: " .. size .. " bytes")
print("Free space: " .. free .. " bytes")

if size > 0 and free < size then
    error("Not enough free space")
end

for line in manifest:gmatch("[^\r\n]+") do
    if not line:match("^[%w_]+=") and line:sub(1, 1) ~= "#" and line ~= "" then
        print("Installing " .. line)
        local data = download(BASE_URL .. line)
        local path = "/" .. line
        ensureDirectory(path)
        local handle, reason = fs.open(path, "w")

        if not handle then
            error("Cannot write " .. path .. ": " .. tostring(reason))
        end

        fs.write(handle, data)
        fs.close(handle)
    end
end

fs.setLabel("YellowOS_User")
print("Flash complete. Version " .. version)
