local component = rawget(_G, "component")
local computer = rawget(_G, "computer")
local c = YellowOS.common
local gpu = c.gpu

local activeFs = YellowOS.fs
local activeAddress = YellowOS.bootAddress
local cwd = "/home"
if not activeFs.exists(cwd) then cwd = "/" end

local screenLines = {}
local commandHistory = {}
local historyIndex = 0
local input = ""
local scrollOffset = 0

local function normalize(path)
    if not path or path == "" then return cwd end
    local full = path:sub(1, 1) == "/" and path or (cwd == "/" and "/" .. path or cwd .. "/" .. path)
    local parts = {}
    for p in full:gmatch("[^/]+") do
        if p == ".." then
            if #parts > 0 then table.remove(parts) end
        elseif p ~= "." and p ~= "" then
            table.insert(parts, p)
        end
    end
    return "/" .. table.concat(parts, "/")
end

local function readFile(fs, path)
    local h, reason = fs.open(path, "r")
    if not h then return nil, reason end
    local data = ""
    while true do
        local chunk = fs.read(h, 4096)
        if not chunk then break end
        data = data .. chunk
    end
    fs.close(h)
    return data
end

local function writeFile(fs, path, data)
    local h, reason = fs.open(path, "w")
    if not h then return false, reason end
    fs.write(h, data)
    fs.close(h)
    return true
end

local function pushLine(text)
    text = tostring(text or "")
    local hadLine = false
    for line in (text .. "\n"):gmatch("(.-)\n") do
        table.insert(screenLines, line)
        hadLine = true
    end
    if not hadLine then table.insert(screenLines, "") end
    while #screenLines > 500 do table.remove(screenLines, 1) end
    scrollOffset = 0
end

local function prompt()
    local label = activeFs.getLabel and activeFs.getLabel() or nil
    label = (label and label ~= "") and label or activeAddress:sub(1, 3)
    return tostring(label) .. ":" .. cwd .. " $ "
end

local function draw()
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, c.width, c.height, " ")

    local visible = c.height - 2
    local last = math.max(0, #screenLines - scrollOffset)
    local first = math.max(1, last - visible + 1)
    local y = 1

    for i = first, last do
        gpu.setForeground(0xCFCFCF)
        gpu.set(1, y, screenLines[i]:sub(1, c.width))
        y = y + 1
    end

    local p = prompt()
    gpu.setBackground(0x000000)
    gpu.setForeground(0x55FF55)
    gpu.set(1, c.height, p:sub(1, c.width))

    local available = math.max(1, c.width - #p)
    local shown = input
    if #shown > available then shown = shown:sub(#shown - available + 1) end
    gpu.setForeground(0xFFFFFF)
    gpu.set(math.min(c.width, #p + 1), c.height, shown)
end

local function listDir(path)
    path = normalize(path)
    if not activeFs.exists(path) then return nil, "No such file or directory: " .. path end
    if not activeFs.isDirectory(path) then return path end

    local names = {}
    local result = activeFs.list(path)
    if type(result) == "table" then
        for _, name in ipairs(result) do table.insert(names, name) end
    elseif type(result) == "function" then
        for name in result do table.insert(names, name) end
    end
    table.sort(names)
    return table.concat(names, "  ")
end

local function split(line)
    local out = {}
    for token in tostring(line):gmatch("%S+") do table.insert(out, token) end
    return out
end

local function copyFile(src, dst)
    src, dst = normalize(src), normalize(dst)
    local data, reason = readFile(activeFs, src)
    if not data then return false, reason end
    return writeFile(activeFs, dst, data)
end

local function runLua(path)
    path = normalize(path)
    local data, reason = readFile(activeFs, path)
    if not data then pushLine("lua: " .. tostring(reason)); return end
    local program, loadReason = load(data, "=" .. path, "t", _ENV)
    if not program then pushLine("lua: " .. tostring(loadReason)); return end
    local ok, result = pcall(program)
    if not ok then pushLine("lua: " .. tostring(result))
    elseif result ~= nil then pushLine(tostring(result)) end
end

local function showDrives()
    for address in component.list("filesystem") do
        local fs = component.proxy(address)
        local label = fs.getLabel and fs.getLabel() or ""
        local used = fs.spaceUsed and fs.spaceUsed() or 0
        local total = fs.spaceTotal and fs.spaceTotal() or 0
        local marker = address == activeAddress and "*" or " "
        pushLine(string.format("%s %s  %-18s %d/%d", marker, address:sub(1, 8), tostring(label or ""), used, total))
    end
end

local function execute(line)
    local args = split(line)
    local cmd = (args[1] or ""):lower()
    if cmd == "" then return end

    if cmd == "help" then
        pushLine("Available commands:")
        pushLine("ls [path]           list files")
        pushLine("cd [path]           change directory")
        pushLine("pwd                 print working directory")
        pushLine("cat <file>          print file")
        pushLine("echo <text>         print text")
        pushLine("echo <text> > file  write text to file")
        pushLine("mkdir <path>        create directory")
        pushLine("rm <path>           remove file/directory")
        pushLine("cp <src> <dst>      copy file")
        pushLine("mv <src> <dst>      move file")
        pushLine("df                  show disk usage")
        pushLine("mount               list filesystem components")
        pushLine("use <address>       switch active disk")
        pushLine("components          list components")
        pushLine("wget <url> <file>   download file")
        pushLine("lua <file>           run Lua file")
        pushLine("wiki                open YellowOS wiki")
        pushLine("submit              submit app to YellowStore")
        pushLine("clear               clear terminal")
        pushLine("reboot | shutdown   power controls")
        pushLine("END                 leave terminal")
    elseif cmd == "pwd" then
        pushLine(cwd)
    elseif cmd == "ls" or cmd == "dir" then
        local result, reason = listDir(args[2])
        pushLine(result or reason)
    elseif cmd == "cd" then
        local path = normalize(args[2] or "/")
        if activeFs.exists(path) and activeFs.isDirectory(path) then cwd = path
        else pushLine("cd: no such directory: " .. path) end
    elseif cmd == "cat" or cmd == "type" then
        if not args[2] then pushLine("Usage: cat <file>")
        else
            local data, reason = readFile(activeFs, normalize(args[2]))
            pushLine(data or ("cat: " .. tostring(reason)))
        end
    elseif cmd == "echo" then
        local redirect = line:match("^%s*echo%s+(.+)%s+>%s+(%S+)%s*$")
        if redirect then
            local text, file = line:match("^%s*echo%s+(.+)%s+>%s+(%S+)%s*$")
            local ok, reason = writeFile(activeFs, normalize(file), text .. "\n")
            if not ok then pushLine("echo: " .. tostring(reason)) end
        else
            pushLine(line:match("^%s*echo%s*(.*)$") or "")
        end
    elseif cmd == "mkdir" then
        if not args[2] then pushLine("Usage: mkdir <path>")
        else
            local ok, reason = activeFs.makeDirectory(normalize(args[2]))
            if not ok then pushLine("mkdir: " .. tostring(reason)) end
        end
    elseif cmd == "rm" or cmd == "del" then
        if not args[2] then pushLine("Usage: rm <path>")
        else
            local ok, reason = activeFs.remove(normalize(args[2]))
            if not ok then pushLine("rm: " .. tostring(reason)) end
        end
    elseif cmd == "cp" then
        if not args[2] or not args[3] then pushLine("Usage: cp <src> <dst>")
        else
            local ok, reason = copyFile(args[2], args[3])
            if not ok then pushLine("cp: " .. tostring(reason)) end
        end
    elseif cmd == "mv" then
        if not args[2] or not args[3] then pushLine("Usage: mv <src> <dst>")
        else
            local src = normalize(args[2])
            local ok, reason = copyFile(args[2], args[3])
            if ok then activeFs.remove(src) else pushLine("mv: " .. tostring(reason)) end
        end
    elseif cmd == "df" then
        pushLine(string.format("Filesystem %s", activeAddress))
        pushLine(string.format("Used: %d bytes", activeFs.spaceUsed()))
        pushLine(string.format("Total: %d bytes", activeFs.spaceTotal()))
        pushLine(string.format("Free: %d bytes", activeFs.spaceTotal() - activeFs.spaceUsed()))
    elseif cmd == "mount" or cmd == "drives" then
        showDrives()
    elseif cmd == "use" then
        local prefix = args[2] or ""
        local found
        for address in component.list("filesystem") do
            if address:sub(1, #prefix) == prefix then found = address; break end
        end
        if found then
            activeAddress = found
            activeFs = component.proxy(found)
            cwd = "/"
        else
            pushLine("use: drive not found")
        end
    elseif cmd == "components" then
        for address, kind in component.list() do pushLine(kind .. "  " .. address) end
    elseif cmd == "wget" then
        if not args[2] or not args[3] then pushLine("Usage: wget <url> <file>")
        else
            pushLine("Connecting...")
            draw()
            local data, reason = YellowOS.http.get(args[2])
            if not data then pushLine("wget: " .. tostring(reason))
            else
                local ok, writeReason = writeFile(activeFs, normalize(args[3]), data)
                if ok then pushLine("Saved " .. tostring(#data) .. " bytes")
                else pushLine("wget: " .. tostring(writeReason)) end
            end
        end
    elseif cmd == "lua" or cmd == "run" then
        if not args[2] then pushLine("Usage: lua <file>") else runLua(args[2]) end
    elseif cmd == "wiki" then
        YellowOS.loadFile("/system/apps/wiki.lua")
    elseif cmd == "submit" then
        YellowOS.loadFile("/system/apps/submit.lua")
    elseif cmd == "clear" or cmd == "cls" then
        screenLines = {}
    elseif cmd == "reboot" then
        computer.shutdown(true)
    elseif cmd == "shutdown" then
        computer.shutdown(false)
    elseif cmd == "exit" then
        return "exit"
    else
        pushLine(cmd .. ": command not found")
    end
end

pushLine("YellowOS Development Edition 0.1.2")
pushLine("OpenOS-style shell. Type 'help' for commands. END exits.")

while true do
    draw()
    local e = {computer.pullSignal()}

    if e[1] == "clipboard" then
        input = input .. tostring(e[3] or ""):gsub("[\r\n]", "")
    elseif e[1] == "scroll" then
        local direction = e[5] or 0
        if direction > 0 then scrollOffset = math.min(#screenLines, scrollOffset + 3)
        elseif direction < 0 then scrollOffset = math.max(0, scrollOffset - 3) end
    elseif e[1] == "key_down" then
        local ch = e[3] or 0
        local code = e[4] or 0

        if code == c.KEY_END then
            return
        elseif code == c.KEY_ENTER or ch == 13 then
            local line = input
            if line ~= "" then
                table.insert(commandHistory, line)
                historyIndex = #commandHistory + 1
            end
            pushLine(prompt() .. line)
            input = ""
            if execute(line) == "exit" then return end
        elseif code == c.KEY_BACKSPACE or ch == 8 then
            input = input:sub(1, -2)
        elseif code == c.KEY_UP then
            if #commandHistory > 0 then
                historyIndex = math.max(1, historyIndex - 1)
                input = commandHistory[historyIndex] or ""
            end
        elseif code == c.KEY_DOWN then
            if #commandHistory > 0 then
                historyIndex = math.min(#commandHistory + 1, historyIndex + 1)
                input = commandHistory[historyIndex] or ""
            end
        elseif ch >= 32 and ch <= 126 then
            input = input .. string.char(ch)
        end
    end
end
