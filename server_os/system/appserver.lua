local component = rawget(_G, "component")
local computer = rawget(_G, "computer")
local fs = YellowOS.fs
local appserver = {port = 24121, pending = {}, modem = nil}

local modemAddress = component and component.list("modem")()
if modemAddress then
    appserver.modem = component.proxy(modemAddress)
    appserver.modem.open(appserver.port)
end

local function ensureDir(path)
    if not fs.exists(path) then fs.makeDirectory(path) end
end

local function read(path)
    local h = fs.open(path, "r")
    if not h then return nil end
    local d = ""
    while true do
        local c = fs.read(h, 4096)
        if not c then break end
        d = d .. c
    end
    fs.close(h)
    return d
end

local function write(path, data)
    local h = fs.open(path, "w")
    if not h then return false end
    fs.write(h, data)
    fs.close(h)
    return true
end

ensureDir("/store")
ensureDir("/store/pending")
ensureDir("/store/rejected")

-- Official one-time review seed. The marker prevents the app from reappearing
-- after it has been approved or rejected.
local seedMarker = "/store/.terminalv2_seeded"
if not fs.exists(seedMarker) then
    local seedCode = read("/system/seeds/terminalv2.lua")
    local seedMeta = read("/system/seeds/terminalv2.meta")
    if seedCode and seedMeta then
        seedMeta = seedMeta:gsub("bytes=%d+", "bytes=" .. tostring(#seedCode))
        write("/store/pending/terminalv2-official.lua", seedCode)
        write("/store/pending/terminalv2-official.meta", seedMeta)
        write(seedMarker, "1\n")
    end
end

function appserver.processSignal(signal, receiver, sender, port, distance, kind, ...)
    if signal ~= "modem_message" or port ~= appserver.port then return false end
    local args = {...}

    if kind == "YELLOWSTORE_SUBMIT_BEGIN" then
        local sid, id, name, version, author, target, totalChunks, totalBytes = table.unpack(args)
        if not sid or not id then return true end
        appserver.pending[sid] = {
            sender = sender,
            id = tostring(id), name = tostring(name or id), version = tostring(version or "1.0.0"),
            author = tostring(author or "Unknown"), target = tostring(target or "all"),
            totalChunks = tonumber(totalChunks) or 0, totalBytes = tonumber(totalBytes) or 0, chunks = {}
        }
        return true
    elseif kind == "YELLOWSTORE_SUBMIT_CHUNK" then
        local sid, index, data = table.unpack(args)
        local p = sid and appserver.pending[sid]
        if p then p.chunks[tonumber(index) or 0] = tostring(data or "") end
        return true
    elseif kind == "YELLOWSTORE_SUBMIT_END" then
        local sid = args[1]
        local p = sid and appserver.pending[sid]
        if not p then return true end
        local parts = {}
        for i = 1, p.totalChunks do
            if not p.chunks[i] then
                if appserver.modem then appserver.modem.send(sender, appserver.port, "YELLOWSTORE_SUBMIT_RESULT", sid, false, "Missing chunk " .. i) end
                appserver.pending[sid] = nil
                return true
            end
            parts[#parts + 1] = p.chunks[i]
        end
        local code = table.concat(parts)
        local meta = table.concat({
            "sid=" .. sid,
            "id=" .. p.id,
            "name=" .. p.name,
            "version=" .. p.version,
            "author=" .. p.author,
            "target=" .. p.target,
            "sender=" .. tostring(p.sender),
            "bytes=" .. tostring(#code)
        }, "\n") .. "\n"
        write("/store/pending/" .. sid .. ".meta", meta)
        write("/store/pending/" .. sid .. ".lua", code)
        if appserver.modem then appserver.modem.send(sender, appserver.port, "YELLOWSTORE_SUBMIT_RESULT", sid, true, "Submitted for review") end
        appserver.pending[sid] = nil
        return true
    end
    return false
end

YellowOS.appserver = appserver
