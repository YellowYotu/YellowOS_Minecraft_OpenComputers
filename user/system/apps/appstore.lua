local common = YellowOS.common
local http = YellowOS.http
local fs = YellowOS.fs
local computer = rawget(_G, "computer")

local CATALOG_URL = "https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/store/catalog.txt"
local BASE_URL = "https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/"

local function ensureDir(path)
    if not fs.exists(path) then
        local ok, reason = fs.makeDirectory(path)
        if not ok then return false, reason end
    end
    return true
end

local function writeFile(path, data)
    local handle, reason = fs.open(path, "w")
    if not handle then return false, reason end
    fs.write(handle, data)
    fs.close(handle)
    return true
end

local function parseCatalog(data)
    local apps = {}
    for line in data:gmatch("[^\r\n]+") do
        if line ~= "" and line:sub(1, 1) ~= "#" then
            local id, name, version, author, target, description, path = line:match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.+)$")
            if id and (target == "mobile" or target == "all" or target == "both") then
                table.insert(apps, {id=id, name=name, version=version, author=author, target=target, description=description, path=path})
            end
        end
    end
    return apps
end

common.header("YellowStore")
common.gpu.set(3, 6, "Loading catalog...")
local cacheKey = tostring(math.floor((computer and computer.uptime() or 0) * 1000))
local data, reason = http.get(CATALOG_URL .. "?t=" .. cacheKey)
if not data then
    common.message("YellowStore", "Cannot load catalog:\n" .. tostring(reason))
    return
end

local apps = parseCatalog(data)
if #apps == 0 then
    common.message("YellowStore", "No mobile applications are published yet.")
    return
end

while true do
    local names = {}
    for _, app in ipairs(apps) do
        table.insert(names, app.name .. "  " .. app.version)
    end
    table.insert(names, "Back")

    local selected = common.menu("YellowStore", "Applications for " .. YellowOS.device, names)
    if not selected or selected == #names then return end

    local app = apps[selected]
    local choice = common.menu(app.name, "by " .. app.author .. " | " .. app.version, {app.description, "Install", "Back"})
    if choice == 2 then
        common.header("YellowStore")
        common.gpu.set(3, 6, "Downloading " .. app.name .. "...")
        local code, downloadReason = http.get(BASE_URL .. app.path .. "?v=" .. app.version .. "&t=" .. cacheKey)
        if not code then
            common.message("Install failed", tostring(downloadReason))
        else
            local root = "/apps"
            local appDir = root .. "/" .. app.id
            local ok, dirReason = ensureDir(root)
            if ok then ok, dirReason = ensureDir(appDir) end
            if not ok then
                common.message("Install failed", tostring(dirReason))
            else
                local wrote, writeReason = writeFile(appDir .. "/main.lua", code)
                if wrote then
                    writeFile(appDir .. "/app.cfg", "id="..app.id.."\nname="..app.name.."\nversion="..app.version.."\nauthor="..app.author.."\n")
                    common.message("YellowStore", app.name .. " installed.")
                else
                    common.message("Install failed", tostring(writeReason))
                end
            end
        end
    end
end
