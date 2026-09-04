local common = YellowOS.common
local computer = rawget(_G, "computer")
if not computer then computer = require("computer") end

local gpu = common.gpu
local updater = YellowOS.updater
local width = common.width
local height = common.height
local history = {}

local function draw(prompt)
    common.header("Terminal")
    gpu.setForeground(0x808080)
    gpu.set(3, 4, "Type 'help'. Ctrl+V paste. END exits.")
    gpu.setForeground(0xFFFFFF)
    local maxLines = height - 8
    local first = math.max(1, #history - maxLines + 1)
    local y = 6
    for i = first, #history do
        gpu.set(3, y, history[i]:sub(1, width - 4))
        y = y + 1
    end
    gpu.setForeground(0xFFFF00)
    gpu.set(3, height - 2, "> " .. prompt:sub(math.max(1, #prompt - width + 6)))
end

local function printLine(text) table.insert(history, tostring(text)) end

local function installUpdate()
    printLine("Checking GitHub...")
    draw("")
    local manifest, reason = updater.check()
    if not manifest then printLine("Update check failed: " .. tostring(reason)); return end
    printLine("Current: " .. YellowOS.version)
    printLine("Latest: " .. manifest.version)
    printLine("Size: " .. common.formatBytes(manifest.size))
    if not manifest.updateAvailable then printLine("Server is already up to date."); return end
    printLine("Installing update...")
    draw("")
    local ok, installReason = updater.install(manifest)
    if not ok then printLine("Update failed: " .. tostring(installReason)); return end
    printLine("Update installed. Rebooting...")
    draw("")
    computer.pullSignal(0.8)
    computer.shutdown(true)
end

local function execute(command)
    command = command:match("^%s*(.-)%s*$")
    if command == "" then return false
    elseif command == "help" then
        printLine("help update version clear reboot shutdown exit")
    elseif command == "update" then installUpdate()
    elseif command == "version" then printLine("YellowOS Server Edition " .. YellowOS.version)
    elseif command == "clear" then history = {}
    elseif command == "reboot" then computer.shutdown(true)
    elseif command == "shutdown" then computer.shutdown(false)
    elseif command == "exit" then return true
    else printLine("Unknown command: " .. command) end
    return false
end

local input = ""
while true do
    draw(input)
    local e = {computer.pullSignal()}
    local signal = e[1]
    if signal == "clipboard" then
        input = input .. tostring(e[3] or ""):gsub("[\r\n]", "")
    elseif signal == "key_down" then
        local char, code = e[3] or 0, e[4] or 0
        if code == common.KEY_END then
            return
        elseif code == common.KEY_ENTER then
            printLine("> " .. input)
            if execute(input) then return end
            input = ""
        elseif code == common.KEY_BACKSPACE then
            input = input:sub(1, -2)
        elseif char >= 32 and char <= 126 then
            input = input .. string.char(char)
        end
    elseif YellowOS.handleSignal then
        YellowOS.handleSignal(table.unpack(e))
    end
end
