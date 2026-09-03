local computer = rawget(_G, "computer")

if not computer then
    computer = require("computer")
end

local fs = YellowOS.fs
local http = YellowOS.http
local common = YellowOS.common
local updater = {}
local BASE_URL = "https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/server_os/"
local MANIFEST_URL = BASE_URL .. "manifest.txt"

local function compareVersions(a, b)
    local av = {}
    local bv = {}

    for n in tostring(a):gmatch("%d+") do
        table.insert(av, tonumber(n))
    end

    for n in tostring(b):gmatch("%d+") do
        table.insert(bv, tonumber(n))
    end

    for i = 1, math.max(#av, #bv) do
        local x = av[i] or 0
        local y = bv[i] or 0

        if x < y then
            return -1
        elseif x > y then
            return 1
        end
    end

    return 0
end

local function parseManifest(data)
    local manifest = {version = "0.0.0", size = 0, files = {}}

    for line in data:gmatch("[^\r\n]+") do
        if line:match("^version=") then
            manifest.version = line:match("^version=(.+)$")
        elseif line:match("^size=") then
            manifest.size = tonumber(line:match("^size=(%d+)$")) or 0
        elseif line ~= "" and line:sub(1, 1) ~= "#" then
            table.insert(manifest.files, line)
        end
    end

    return manifest
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

function updater.check()
    local cacheKey = tostring(math.floor(computer.uptime() * 1000))
    local data, reason = http.get(MANIFEST_URL .. "?t=" .. cacheKey)

    if not data then
        return nil, reason
    end

    local manifest = parseManifest(data)
    manifest.updateAvailable = compareVersions(YellowOS.version, manifest.version) < 0
    return manifest
end

function updater.install(manifest)
    local free = fs.spaceTotal() - fs.spaceUsed()

    if manifest.size > 0 and free < manifest.size then
        return false, "Not enough storage. Need " .. common.formatBytes(manifest.size) .. ", free " .. common.formatBytes(free)
    end

    local cacheKey = tostring(math.floor(computer.uptime() * 1000))

    for i, path in ipairs(manifest.files) do
        common.header("Updating Server")
        common.gpu.setForeground(0xFFFFFF)
        common.gpu.set(3, 6, "Downloading " .. i .. "/" .. #manifest.files)
        common.gpu.set(3, 8, path:sub(1, common.width - 4))
        local data, reason = http.get(BASE_URL .. path .. "?t=" .. cacheKey)

        if not data then
            return false, "Download failed: " .. tostring(reason)
        end

        ensureDirectory("/" .. path)
        local handle, openReason = fs.open("/" .. path, "w")

        if not handle then
            return false, "Write failed: " .. tostring(openReason)
        end

        fs.write(handle, data)
        fs.close(handle)
    end

    return true
end

YellowOS.updater = updater
