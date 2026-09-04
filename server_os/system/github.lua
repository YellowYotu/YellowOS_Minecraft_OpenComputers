local component = rawget(_G, "component")
local fs = YellowOS.fs
local github = {}

local API = "https://api.github.com/graphql"
local OWNER = "YellowYotu"
local REPO = "YellowOS_Minecraft_OpenComputers"
local BRANCH = "main"
local TOKEN_PATH = "/system/secrets/github_token.cfg"

local function read(path)
    local h = fs.open(path, "r")
    if not h then return nil end
    local d = ""
    while true do local c = fs.read(h, 2048); if not c then break end; d = d .. c end
    fs.close(h)
    return d
end

local function jsonEscape(s)
    return tostring(s):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\r", "\\r"):gsub("\n", "\\n")
end

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function base64(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b64chars:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local function token()
    local t = read(TOKEN_PATH)
    if not t then return nil end
    t = t:gsub("%s+$", "")
    if t == "" then return nil end
    return t
end

local function post(query)
    local internetAddress = component and component.list("internet")()
    if not internetAddress then return nil, "Internet Card not found" end
    local t = token()
    if not t then return nil, "GitHub token is not configured" end
    local internet = component.proxy(internetAddress)
    local body = '{"query":"' .. jsonEscape(query) .. '"}'
    local headers = {
        ["Authorization"] = "bearer " .. t,
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/vnd.github+json",
        ["User-Agent"] = "YellowOS-Server"
    }
    local req, reason = internet.request(API, body, headers)
    if not req then return nil, tostring(reason) end
    local data = ""
    while true do
        local chunk, rr = req.read(4096)
        if chunk then data = data .. chunk elseif rr then req.close(); return nil, tostring(rr) else break end
    end
    req.close()
    if data:find('"errors"%s*:') then return nil, data end
    return data
end

function github.isConfigured()
    return token() ~= nil
end

function github.getHead()
    local q = 'query { repository(owner:"'..OWNER..'", name:"'..REPO..'") { ref(qualifiedName:"refs/heads/'..BRANCH..'") { target { oid } } } }'
    local data, reason = post(q)
    if not data then return nil, reason end
    local oid = data:match('"oid"%s*:%s*"([0-9a-f]+)"')
    if not oid then return nil, "Cannot read branch HEAD" end
    return oid
end

function github.publishApp(app, code, catalog)
    local head, reason = github.getHead()
    if not head then return false, reason end
    local appPath = "store/apps/" .. app.id .. "/main.lua"
    local additions = '{path:"'..jsonEscape(appPath)..'",contents:"'..base64(code)..'"},{path:"store/catalog.txt",contents:"'..base64(catalog)..'"}'
    local q = 'mutation { createCommitOnBranch(input:{branch:{repositoryNameWithOwner:"'..OWNER..'/'..REPO..'",branchName:"'..BRANCH..'"},message:{headline:"Publish YellowStore app '..jsonEscape(app.name)..' '..jsonEscape(app.version)..'"},expectedHeadOid:"'..head..'",fileChanges:{additions:['..additions..']}}) { commit { oid } } }'
    local data, publishReason = post(q)
    if not data then return false, publishReason end
    local oid = data:match('"oid"%s*:%s*"([0-9a-f]+)"')
    return oid ~= nil, oid or "GitHub did not return commit oid"
end

YellowOS.github = github
