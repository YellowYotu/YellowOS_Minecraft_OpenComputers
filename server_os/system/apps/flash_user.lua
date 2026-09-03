local component = rawget(_G, "component")
local computer = rawget(_G, "computer")

if not component then
    component = require("component")
end

if not computer then
    computer = require("computer")
end

local common = YellowOS.common
local http = YellowOS.http
local BASE_URL = "https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/user/"
local bootAddress = computer.getBootAddress()
local drives = {}
local names = {}

for address in component.list("filesystem") do
    local fs = component.proxy(address)

    if address ~= bootAddress and not fs.isReadOnly() then
        local label = fs.getLabel() or address:sub(1, 8)
        table.insert(drives, {address = address, fs = fs})
        table.insert(names, label .. " | " .. address:sub(1, 8) .. " | " .. common.formatBytes(fs.spaceTotal()))
    end
end

if #drives == 0 then
    common.message("Flash User HDD", "No writable target HDD found")
    return
end

local selected = common.menu("Flash User HDD", "Select target drive", names)

if not selected then
    return
end

local target = drives[selected]
local modelChoice = common.menu("Device Model", "Select YellowPad model", {"YellowPad Lite", "YellowPad", "YellowPad Pro", "Cancel"})

if not modelChoice or modelChoice == 4 then
    return
end

local models = {"YellowPad Lite", "YellowPad", "YellowPad Pro"}
local model = models[modelChoice]
local confirm = common.menu("WARNING", "ALL DATA ON " .. target.address:sub(1, 8) .. " WILL BE REPLACED", {"Flash " .. model, "Cancel"})

if confirm ~= 1 then
    return
end

local cacheKey = tostring(math.floor(computer.uptime() * 1000))
local manifest, reason = http.get(BASE_URL .. "manifest.txt?t=" .. cacheKey)

if not manifest then
    common.message("Flash User HDD", "Manifest download failed:\n" .. tostring(reason))
    return
end

local version = manifest:match("version=([^\r\n]+)") or "unknown"
local size = tonumber(manifest:match("size=(%d+)")) or 0
local free = target.fs.spaceTotal() - target.fs.spaceUsed()

if size > 0 and free < size then
    common.message("Flash User HDD", "Not enough storage.\nNeed: " .. common.formatBytes(size) .. "\nFree: " .. common.formatBytes(free))
    return
end

local function ensureDirectory(path)
    local directory = path:match("^(.*)/[^/]+$")

    if not directory or directory == "" then
        return
    end

    local current = ""

    for part in directory:gmatch("[^/]+") do
        current = current .. "/" .. part

        if not target.fs.exists(current) then
            target.fs.makeDirectory(current)
        end
    end
end

for line in manifest:gmatch("[^\r\n]+") do
    if not line:match("^[%w_]+=") and line ~= "" and line:sub(1, 1) ~= "#" then
        common.header("Flashing " .. model)
        common.gpu.set(3, 6, "Installing " .. line)
        local data, downloadReason = http.get(BASE_URL .. line .. "?t=" .. cacheKey)

        if not data then
            common.message("Flash failed", tostring(downloadReason))
            return
        end

        local path = "/" .. line
        ensureDirectory(path)
        local handle, openReason = target.fs.open(path, "w")

        if not handle then
            common.message("Flash failed", tostring(openReason))
            return
        end

        target.fs.write(handle, data)
        target.fs.close(handle)
    end
end

local profileHandle, profileReason = target.fs.open("/system/device.cfg", "w")

if not profileHandle then
    common.message("Flash failed", "Cannot write device profile:\n" .. tostring(profileReason))
    return
end

target.fs.write(profileHandle, "device=" .. model .. "\n")
target.fs.close(profileHandle)
target.fs.setLabel(model:gsub(" ", "_"))
common.message("Flash User HDD", "Flash complete.\n" .. model .. "\nUser Edition " .. version)
