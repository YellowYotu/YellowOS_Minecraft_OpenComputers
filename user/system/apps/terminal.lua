local computer = rawget(_G, "computer")

if not computer then
    computer = require("computer")
end

local common = YellowOS.common
local gpu = common.gpu
local fs = YellowOS.fs
local updater = YellowOS.updater

if not common.hasKeyboard then
    common.message("Terminal", "Keyboard component is required.")
    return
end

local lines = {}
local input = ""
local running = true
local maxLines = math.max(4, common.height - 9)

local function push(text)
    for line in tostring(text):gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    while #lines > maxLines do
        table.remove(lines, 1)
    end
end

local function draw()
    common.header("Terminal", "Protected system disk")
    common.panel(2, 6, common.width - 2, common.height - 7, common.colors.terminal)
    gpu.setBackground(common.colors.terminal)
    gpu.setForeground(common.colors.text)

    local y = 7
    for _, line in ipairs(lines) do
        gpu.set(3, y, line:sub(1, math.max(1, common.width - 5)))
        y = y + 1
    end

    gpu.setForeground(common.colors.accent)
    gpu.set(3, common.height - 1, "> " .. input:sub(1, math.max(1, common.width - 5)))
end

local function normalizePath(path)
    path = path or "/"
    if path:sub(1, 1) ~= "/" then
        path = "/" .. path
    end
    return path
end

local function list(path)
    path = normalizePath(path)
    if not fs.exists(path) or not fs.isDirectory(path) then
        push("Not a directory: " .. path)
        return
    end

    local names = {}
    for name in fs.list(path) do
        table.insert(names, name)
    end
    table.sort(names)
    push(#names == 0 and "(empty)" or table.concat(names, "  "))
end

local function cat(path)
    path = normalizePath(path)
    if not fs.exists(path) or fs.isDirectory(path) then
        push("Not a file: " .. path)
        return
    end

    local handle = fs.open(path, "r")
    if not handle then
        push("Cannot open file")
        return
    end

    local data = ""
    while #data < 4096 do
        local chunk = fs.read(handle, 1024)
        if not chunk then
            break
        end
        data = data .. chunk
    end
    fs.close(handle)
    push(data == "" and "(empty)" or data)
end

local function doUpdate()
    push("Checking for updates...")
    draw()
    local manifest, reason = updater.check()
    if not manifest then
        push("Check failed: " .. tostring(reason))
        return
    end
    if not manifest.updateAvailable then
        push("Already up to date: " .. YellowOS.version)
        return
    end

    push("Installing " .. manifest.version .. "...")
    draw()
    local ok, installReason = updater.install(manifest)
    if not ok then
        push("Update failed: " .. tostring(installReason))
        return
    end
    push("Update complete. Rebooting...")
    draw()
    computer.pullSignal(1)
    computer.shutdown(true)
end

local blocked = {
    rm = true, del = true, delete = true, edit = true, write = true,
    mv = true, move = true, cp = true, copy = true, mkdir = true,
    touch = true, wget = true, lua = true
}

local function execute(commandLine)
    local command, args = commandLine:match("^(%S+)%s*(.-)%s*$")
    command = (command or ""):lower()

    if command == "" then
        return
    elseif command == "help" then
        push("help  version  device  ls [path]  cat <file>")
        push("update  clear  reboot  shutdown  exit")
        push("System disk is read-only to terminal users.")
    elseif command == "version" then
        push("YellowOS " .. YellowOS.version .. " - " .. YellowOS.edition)
    elseif command == "device" then
        push(YellowOS.device)
    elseif command == "ls" then
        list(args ~= "" and args or "/")
    elseif command == "cat" then
        if args == "" then
            push("Usage: cat <file>")
        else
            cat(args)
        end
    elseif command == "update" then
        doUpdate()
    elseif command == "clear" then
        lines = {}
    elseif command == "reboot" then
        computer.shutdown(true)
    elseif command == "shutdown" then
        computer.shutdown(false)
    elseif command == "exit" then
        running = false
    elseif blocked[command] then
        push("Denied: device system disk is protected.")
    else
        push("Unknown command: " .. command)
    end
end

push("YellowOS Terminal")
push("Protected mode. Type 'help'.")

while running do
    draw()
    local event = {computer.pullSignal()}
    local signal = event[1]

    if signal == "key_down" then
        local char = event[3] or 0
        local code = event[4] or 0

        if common.isBack(char, code) then
            if #input > 0 then
                input = input:sub(1, -2)
            else
                running = false
            end
        elseif common.isEnter(char, code) then
            local commandLine = input
            input = ""
            push("> " .. commandLine)
            execute(commandLine)
        elseif char >= 32 and char <= 126 then
            input = input .. string.char(char)
        end
    elseif signal == "touch" then
        local x, y = event[3], event[4]
        if y <= 3 and x <= 12 then
            running = false
        end
    else
        common.dispatchSystemEvent(event)
    end
end
