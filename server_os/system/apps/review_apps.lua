local common = YellowOS.common
local fs = YellowOS.fs
local http = YellowOS.http
local github = YellowOS.github
local CATALOG_URL = "https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/store/catalog.txt"

local function read(path)
    local h = fs.open(path, "r")
    if not h then return nil end
    local d = ""
    while true do local c = fs.read(h, 2048); if not c then break end; d = d .. c end
    fs.close(h)
    return d
end

local function parseMeta(data)
    local a = {}
    for k,v in tostring(data):gmatch("([%w_]+)=([^\r\n]+)") do a[k]=v end
    return a
end

local function pendingList()
    local list = {}
    if not fs.exists("/store/pending") then return list end
    for name in fs.list("/store/pending") do
        local sid = name:match("^(.-)%.meta$")
        if sid then
            local meta = parseMeta(read("/store/pending/"..sid..".meta") or "")
            meta.sid = sid
            table.insert(list, meta)
        end
    end
    table.sort(list, function(a,b) return (a.name or a.sid) < (b.name or b.sid) end)
    return list
end

local function buildCatalog(old, app)
    local lines = {"# YellowStore catalog", "# id|name|version|author|target|description|path"}
    for line in tostring(old):gmatch("[^\r\n]+") do
        if line ~= "" and line:sub(1,1) ~= "#" then
            local id = line:match("^([^|]+)|")
            if id ~= app.id then table.insert(lines, line) end
        end
    end
    local desc = "Community application"
    local path = "store/apps/"..app.id.."/main.lua"
    table.insert(lines, table.concat({app.id,app.name,app.version,app.author,app.target,desc,path}, "|"))
    return table.concat(lines, "\n") .. "\n"
end

while true do
    local pending = pendingList()
    if #pending == 0 then
        common.message("App Review", "No pending application submissions.")
        return
    end

    local names = {}
    for _,a in ipairs(pending) do table.insert(names, (a.name or a.id or a.sid).."  "..(a.version or "?")) end
    table.insert(names, "Back")
    local s = common.menu("App Review", tostring(#pending).." pending", names)
    if not s or s == #names then return end
    local app = pending[s]
    local choice = common.menu(app.name or app.id, (app.author or "Unknown").." | "..(app.target or "all"), {"Approve + publish to GitHub", "Reject", "Back"})

    if choice == 1 then
        if not github or not github.isConfigured() then
            common.message("App Review", "GitHub token is not configured.\nOpen GitHub Setup first.")
        else
            local code = read("/store/pending/"..app.sid..".lua")
            if not code then
                common.message("App Review", "Submission code is missing.")
            else
                common.header("Publishing App")
                common.gpu.set(3, 6, "Publishing "..(app.name or app.id).." to GitHub...")
                local catalog, reason = http.get(CATALOG_URL .. "?t=" .. tostring(math.floor((rawget(_G,"computer").uptime())*1000)))
                if not catalog then
                    common.message("Publish failed", tostring(reason))
                else
                    local newCatalog = buildCatalog(catalog, app)
                    local ok, result = github.publishApp(app, code, newCatalog)
                    if ok then
                        fs.remove("/store/pending/"..app.sid..".meta")
                        fs.remove("/store/pending/"..app.sid..".lua")
                        common.message("Published", (app.name or app.id).." is now in YellowStore.\nCommit: "..tostring(result):sub(1,12))
                    else
                        common.message("Publish failed", tostring(result))
                    end
                end
            end
        end
    elseif choice == 2 then
        local code = read("/store/pending/"..app.sid..".lua") or ""
        local meta = read("/store/pending/"..app.sid..".meta") or ""
        if not fs.exists("/store/rejected") then fs.makeDirectory("/store/rejected") end
        local h = fs.open("/store/rejected/"..app.sid..".txt", "w")
        if h then fs.write(h, meta.."\n---CODE---\n"..code); fs.close(h) end
        fs.remove("/store/pending/"..app.sid..".meta")
        fs.remove("/store/pending/"..app.sid..".lua")
        common.message("App Review", "Submission rejected.")
    end
end
