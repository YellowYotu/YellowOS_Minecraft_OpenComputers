local component = component
local common = YellowOS.common
local gpu = common.gpu

local function listEntries(fs, path)
    local entries = {}

    for name in fs.list(path) do
        table.insert(entries, name)
    end

    table.sort(entries)
    return entries
end

local function showFile(fs, path)
    local handle = fs.open(path, "r")

    if not handle then
        common.message("Files", "Cannot open file")
        return
    end

    local data = ""

    while #data < 12000 do
        local chunk = fs.read(handle, 2048)

        if not chunk then
            break
        end

        data = data .. chunk
    end

    fs.close(handle)
    common.header(path)
    gpu.setForeground(0xFFFFFF)
    local y = 5

    for line in (data .. "\n"):gmatch("(.-)\n") do
        gpu.set(2, y, line:sub(1, common.width - 3))
        y = y + 1

        if y >= common.height - 2 then
            break
        end
    end

    gpu.setForeground(0x808080)
    gpu.set(2, common.height - 1, "Tap anywhere or BACKSPACE")

    while true do
        local signal, _, _, code = computer.pullSignal()

        if signal == "touch" or (signal == "key_down" and code == common.KEY_BACKSPACE) then
            return
        end
    end
end

local drives = {}

for address in component.list("filesystem") do
    local fs = component.proxy(address)
    local label = fs.getLabel() or address:sub(1, 8)
    table.insert(drives, {label = label, fs = fs})
end

local driveNames = {}

for _, drive in ipairs(drives) do
    table.insert(driveNames, drive.label .. "  " .. common.formatBytes(drive.fs.spaceUsed()) .. "/" .. common.formatBytes(drive.fs.spaceTotal()))
end

local driveIndex = common.menu("Files", "Storage devices", driveNames)

if not driveIndex then
    return
end

local fs = drives[driveIndex].fs
local path = "/"

while true do
    local entries = listEntries(fs, path)
    local items = {"[..]"}

    for _, name in ipairs(entries) do
        local full = path == "/" and "/" .. name or path .. "/" .. name
        table.insert(items, (fs.isDirectory(full) and "[DIR] " or "") .. name)
    end

    local selected = common.menu("Files", path, items)

    if not selected then
        return
    elseif selected == 1 then
        if path == "/" then
            return
        end

        path = path:match("^(.*)/[^/]+/?$") or "/"

        if path == "" then
            path = "/"
        end
    else
        local name = entries[selected - 1]
        local full = path == "/" and "/" .. name or path .. "/" .. name

        if fs.isDirectory(full) then
            path = full:gsub("/$", "")
        else
            showFile(fs, full)
        end
    end
end
