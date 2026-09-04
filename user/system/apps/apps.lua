local common = YellowOS.common
local fs = YellowOS.fs

local function read(path)
    local h = fs.open(path, "r")
    if not h then return nil end
    local data = ""
    while true do
        local chunk = fs.read(h, 2048)
        if not chunk then break end
        data = data .. chunk
    end
    fs.close(h)
    return data
end

if not fs.exists("/apps") then
    common.message("Apps", "No applications installed.\nOpen YellowStore to install some.")
    return
end

while true do
    local apps = {}
    for name in fs.list("/apps") do
        local id = name:gsub("/$", "")
        local main = "/apps/" .. id .. "/main.lua"
        if fs.exists(main) then
            local cfg = read("/apps/" .. id .. "/app.cfg") or ""
            local display = cfg:match("name=([^\r\n]+)") or id
            table.insert(apps, {id=id, name=display, path=main})
        end
    end
    table.sort(apps, function(a,b) return a.name:lower() < b.name:lower() end)

    if #apps == 0 then
        common.message("Apps", "No applications installed.\nOpen YellowStore to install some.")
        return
    end

    local names = {}
    for _, app in ipairs(apps) do table.insert(names, app.name) end
    table.insert(names, "Back")
    local s = common.menu("Apps", "Installed applications", names)
    if not s or s == #names then return end

    local code = read(apps[s].path)
    if not code then
        common.message("Apps", "Cannot read application.")
    else
        local program, reason = load(code, "=" .. apps[s].path, "t", _ENV)
        if not program then
            common.message("App error", tostring(reason))
        else
            local ok, runReason = pcall(program)
            if not ok then common.message("App error", tostring(runReason)) end
        end
    end
end
