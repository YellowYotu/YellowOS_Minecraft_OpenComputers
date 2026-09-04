local component = require("component")
local computer = require("computer")

local installerAddress = computer.getBootAddress()
local gpuAddress = component.list("gpu")()
local screenAddress = component.list("screen")()
local internetAddress = component.list("internet")()

if not gpuAddress or not screenAddress then
    error("GPU and screen are required")
end

local gpu = component.proxy(gpuAddress)
gpu.bind(screenAddress)
local maxWidth, maxHeight = gpu.maxResolution()
gpu.setResolution(maxWidth, maxHeight)
local width, height = gpu.getResolution()

local BASE_URL = "https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/desktop/"
local MANIFEST_URL = BASE_URL .. "manifest.txt"

local KEY_UP = 200
local KEY_DOWN = 208
local KEY_ENTER = 28
local KEY_BACKSPACE = 14

local function clear()
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, width, height, " ")
end

local function header(title)
    clear()
    gpu.setBackground(0x303030)
    gpu.fill(1, 1, width, 3, " ")
    gpu.setForeground(0xFFD23F)
    gpu.set(2, 2, "YellowOS")
    gpu.setForeground(0xFFFFFF)
    gpu.set(12, 2, title)
    gpu.setBackground(0x000000)
end

local function center(y, text, color)
    text = tostring(text)
    gpu.setForeground(color or 0xFFFFFF)
    gpu.set(math.max(1, math.floor((width - #text) / 2) + 1), y, text)
end

local function formatBytes(bytes)
    if bytes >= 1048576 then
        return string.format("%.2f MB", bytes / 1048576)
    elseif bytes >= 1024 then
        return string.format("%.1f KB", bytes / 1024)
    end
    return tostring(bytes) .. " B"
end

local function waitBack()
    center(height - 2, "Tap anywhere or BACKSPACE", 0x808080)
    while true do
        local event = {computer.pullSignal()}
        if event[1] == "touch" then
            return
        elseif event[1] == "key_down" and (event[4] == KEY_BACKSPACE or event[3] == 8) then
            return
        end
    end
end

local function message(title, text)
    header(title)
    local y = 6
    for line in (tostring(text) .. "\n"):gmatch("(.-)\n") do
        center(y, line)
        y = y + 2
    end
    waitBack()
end

local function menu(title, subtitle, items)
    local selected = 1
    local firstRow = 7

    while true do
        header(title)
        center(5, subtitle or "", 0x6EA8FF)

        for i, item in ipairs(items) do
            local y = firstRow + (i - 1) * 2
            if i == selected then
                gpu.setBackground(0xFFD23F)
                gpu.setForeground(0x000000)
            else
                gpu.setBackground(0x303030)
                gpu.setForeground(0xFFFFFF)
            end
            gpu.fill(4, y, width - 7, 1, " ")
            gpu.set(6, y, tostring(item):sub(1, width - 11))
        end

        gpu.setBackground(0x000000)
        center(height - 2, "UP/DOWN + ENTER   or tap   BACKSPACE = cancel", 0x808080)

        local event = {computer.pullSignal()}
        if event[1] == "key_down" then
            local char = event[3] or 0
            local code = event[4] or 0
            if code == KEY_UP then
                selected = selected - 1
                if selected < 1 then selected = #items end
            elseif code == KEY_DOWN then
                selected = selected + 1
                if selected > #items then selected = 1 end
            elseif code == KEY_ENTER or char == 13 then
                return selected
            elseif code == KEY_BACKSPACE or char == 8 then
                return nil
            end
        elseif event[1] == "touch" then
            local x, y = event[3], event[4]
            for i = 1, #items do
                local row = firstRow + (i - 1) * 2
                if y == row and x >= 4 and x <= width - 4 then
                    return i
                end
            end
        end
    end
end

local function httpGet(url)
    if not internetAddress then
        return nil, "Internet Card not found"
    end

    local internet = component.proxy(internetAddress)
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

local function parseManifest(data)
    local manifest = {version = "unknown", size = 0, files = {}}
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

local function ensureDirectory(fs, path)
    local directory = path:match("^(.*)/[^/]+$")
    if not directory or directory == "" then return true end

    local current = ""
    for part in directory:gmatch("[^/]+") do
        current = current .. "/" .. part
        if not fs.exists(current) then
            local ok, reason = fs.makeDirectory(current)
            if not ok then return false, reason end
        end
    end
    return true
end

header("Desktop Installer")
center(7, "Loading installer...", 0xFFFFFF)

local cacheKey = tostring(math.floor(computer.uptime() * 1000))
local manifestData, manifestReason = httpGet(MANIFEST_URL .. "?t=" .. cacheKey)
if not manifestData then
    message("Installer Error", "Cannot download manifest:\n" .. tostring(manifestReason))
    return
end

local manifest = parseManifest(manifestData)
local drives = {}
local driveNames = {}

for address in component.list("filesystem") do
    if address ~= installerAddress then
        local fs = component.proxy(address)
        if not fs.isReadOnly() then
            local free = fs.spaceTotal() - fs.spaceUsed()
            local label = fs.getLabel() or address:sub(1, 8)
            table.insert(drives, {address = address, fs = fs, label = label, free = free})
            table.insert(driveNames, label .. "   " .. formatBytes(free) .. " free")
        end
    end
end

table.insert(driveNames, "Cancel")

if #drives == 0 then
    message("Desktop Installer", "No writable target disk found.")
    return
end

local selected = menu("Desktop Installer", "YellowOS Desktop " .. manifest.version .. " | " .. formatBytes(manifest.size), driveNames)
if not selected or selected == #driveNames then
    header("Desktop Installer")
    center(math.floor(height / 2), "Installation cancelled.", 0x808080)
    computer.pullSignal(1)
    return
end

local target = drives[selected]
if target.free < manifest.size then
    message("Not Enough Space", "Need " .. formatBytes(manifest.size) .. "\nFree " .. formatBytes(target.free))
    return
end

local confirm = menu("Confirm Installation", target.label .. " | " .. target.address:sub(1, 8), {"Install YellowOS Desktop", "Cancel"})
if confirm ~= 1 then
    header("Desktop Installer")
    center(math.floor(height / 2), "Installation cancelled.", 0x808080)
    computer.pullSignal(1)
    return
end

for i, path in ipairs(manifest.files) do
    header("Installing Desktop")
    center(5, "YellowOS Desktop " .. manifest.version, 0x6EA8FF)
    center(8, "Downloading " .. i .. "/" .. #manifest.files, 0xFFFFFF)
    center(10, path, 0x808080)

    local data, reason = httpGet(BASE_URL .. path .. "?v=" .. manifest.version .. "&t=" .. cacheKey)
    if not data then
        message("Installation Failed", path .. "\n" .. tostring(reason))
        return
    end

    local ok, dirReason = ensureDirectory(target.fs, "/" .. path)
    if not ok then
        message("Installation Failed", tostring(dirReason))
        return
    end

    local handle, openReason = target.fs.open("/" .. path, "w")
    if not handle then
        message("Installation Failed", tostring(openReason))
        return
    end
    target.fs.write(handle, data)
    target.fs.close(handle)
end

target.fs.setLabel("YellowOS_Desktop")
header("Installation Complete")
center(7, "YellowOS Desktop " .. manifest.version .. " installed", 0x55FF55)
center(10, "Target: " .. target.address:sub(1, 8), 0xFFFFFF)
center(13, "Remove installer floppy and reboot.", 0xFFD23F)
waitBack()
