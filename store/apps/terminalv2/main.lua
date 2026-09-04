local component = rawget(_G, "component")
local computer = rawget(_G, "computer")
if not component or not computer then return end

local gpuAddress = component.list("gpu")()
local screenAddress = component.list("screen")()
local keyboardAddress = component.list("keyboard")()
if not gpuAddress or not screenAddress then return end

local gpu = component.proxy(gpuAddress)
gpu.bind(screenAddress)
local width, height = gpu.getResolution()

local function clear()
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, width, height, " ")
end

if not keyboardAddress then
  clear()
  gpu.set(2, 2, "TerminalV2 requires a keyboard.")
  computer.pullSignal(2)
  return
end

local bootAddress = computer.getBootAddress()
if not bootAddress then return end

local activeAddress = bootAddress
local activeFs = component.proxy(activeAddress)
local cwd = "/"
local input = ""
local cursor = 1
local output = {}
local commands = {}
local commandPos = 1
local scroll = 0
local running = true
local hostname = "yellowos"

local KEY_ENTER = 28
local KEY_BACKSPACE = 14
local KEY_UP = 200
local KEY_DOWN = 208
local KEY_LEFT = 203
local KEY_RIGHT = 205
local KEY_HOME = 199
local KEY_END = 207
local KEY_DELETE = 211

local function formatBytes(value)
  value = tonumber(value) or 0
  if value >= 1048576 then return string.format("%.2fM", value / 1048576) end
  if value >= 1024 then return string.format("%.1fK", value / 1024) end
  return tostring(value) .. "B"
end

local function normalize(path)
  path = tostring(path or "")
  if path == "" then return cwd end
  local full
  if path:sub(1, 1) == "/" then full = path
  elseif cwd == "/" then full = "/" .. path
  else full = cwd .. "/" .. path end

  local parts = {}
  for part in full:gmatch("[^/]+") do
    if part == ".." then table.remove(parts)
    elseif part ~= "." and part ~= "" then parts[#parts + 1] = part end
  end
  return "/" .. table.concat(parts, "/")
end

local function readAll(path)
  local handle, reason = activeFs.open(path, "r")
  if not handle then return nil, reason end
  local data = ""
  while true do
    local chunk = activeFs.read(handle, 4096)
    if not chunk then break end
    data = data .. chunk
  end
  activeFs.close(handle)
  return data
end

local function writeAll(path, data)
  local handle, reason = activeFs.open(path, "w")
  if not handle then return false, reason end
  activeFs.write(handle, data or "")
  activeFs.close(handle)
  return true
end

local function listIterator(path)
  local result = activeFs.list(path)
  if type(result) == "function" then return result end
  if type(result) == "table" then
    local index = 0
    return function()
      index = index + 1
      return result[index]
    end
  end
  return function() return nil end
end

local function printLine(text)
  text = tostring(text or "")
  for line in (text .. "\n"):gmatch("(.-)\n") do output[#output + 1] = line end
  while #output > 600 do table.remove(output, 1) end
  scroll = 0
end

local function prompt()
  return "root@" .. hostname .. ":" .. cwd .. "# "
end

local function redraw()
  clear()
  local visible = height - 1
  local last = math.max(0, #output - scroll)
  local first = math.max(1, last - visible + 1)
  local y = 1
  for i = first, last do
    gpu.set(1, y, tostring(output[i]):sub(1, width))
    y = y + 1
  end

  local p = prompt()
  local full = p .. input
  local start = math.max(1, #full - width + 1)
  gpu.set(1, height, full:sub(start, start + width - 1))

  local absoluteCursor = #p + cursor - 1
  local cursorX = absoluteCursor - start + 1
  if cursorX >= 1 and cursorX <= width then
    local ch = input:sub(cursor, cursor)
    if ch == "" then ch = " " end
    gpu.setBackground(0xFFFFFF)
    gpu.setForeground(0x000000)
    gpu.set(cursorX, height, ch)
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
  end
end

local function split(line)
  local result = {}
  local current = ""
  local quote = nil
  for i = 1, #line do
    local ch = line:sub(i, i)
    if quote then
      if ch == quote then quote = nil else current = current .. ch end
    elseif ch == "'" or ch == '"' then quote = ch
    elseif ch:match("%s") then
      if current ~= "" then result[#result + 1] = current; current = "" end
    else current = current .. ch end
  end
  if current ~= "" then result[#result + 1] = current end
  return result
end

local function copyFile(source, destination)
  source = normalize(source)
  destination = normalize(destination)
  local data, reason = readAll(source)
  if not data then return false, reason end
  return writeAll(destination, data)
end

local function list(path)
  path = normalize(path or cwd)
  if not activeFs.exists(path) then
    printLine("ls: cannot access '" .. path .. "': No such file or directory")
    return
  end
  if not activeFs.isDirectory(path) then printLine(path); return end

  local entries = {}
  for name in listIterator(path) do entries[#entries + 1] = name end
  table.sort(entries)
  local line = ""
  for _, name in ipairs(entries) do
    if #line + #name + 2 > width then
      printLine(line)
      line = name
    else
      line = line == "" and name or line .. "  " .. name
    end
  end
  if line ~= "" then printLine(line) end
end

local function editor(path)
  path = normalize(path or "new.lua")
  clear()
  gpu.set(1, 1, "TerminalV2 editor: :wq save | :q cancel | END cancel")
  local lines = {}
  while true do
    local line = ""
    while true do
      gpu.setBackground(0x000000); gpu.setForeground(0xFFFFFF)
      gpu.fill(1, height, width, 1, " ")
      gpu.set(1, height, (tostring(#lines + 1) .. "> " .. line):sub(1, width))
      local event = {computer.pullSignal()}
      if event[1] == "clipboard" then
        line = line .. tostring(event[3] or ""):gsub("[\r\n]", "")
      elseif event[1] == "key_down" then
        local char, code = event[3] or 0, event[4] or 0
        if code == KEY_END then printLine("Edit cancelled."); return end
        if code == KEY_ENTER or char == 13 then break end
        if code == KEY_BACKSPACE or char == 8 then line = line:sub(1, -2)
        elseif char >= 32 and char <= 126 then line = line .. string.char(char) end
      end
    end
    if line == ":q" then printLine("Edit cancelled."); return end
    if line == ":wq" then
      local ok, reason = writeAll(path, table.concat(lines, "\n") .. (#lines > 0 and "\n" or ""))
      printLine(ok and ("Saved " .. path) or ("edit: " .. tostring(reason)))
      return
    end
    lines[#lines + 1] = line
  end
end

local function wget(url, path)
  if not url or not path then printLine("Usage: wget <url> <file>"); return end
  local internetAddress = component.list("internet")()
  if not internetAddress then printLine("wget: Internet Card not found"); return end
  local internet = component.proxy(internetAddress)
  local ok, request = pcall(internet.request, url)
  if not ok or not request then printLine("wget: request failed"); return end
  local data = ""
  while true do
    local chunk = request.read and request.read(math.huge) or nil
    if not chunk then break end
    data = data .. chunk
  end
  if request.close then pcall(request.close) end
  local saved, reason = writeAll(normalize(path), data)
  printLine(saved and ("Downloaded " .. tostring(#data) .. " bytes") or ("wget: " .. tostring(reason)))
end

local function execute(line)
  local args = split(line)
  local cmd = (args[1] or ""):lower()
  if cmd == "" then return end

  if cmd == "help" then
    printLine("TerminalV2 OpenOS-style shell commands:")
    printLine("ls cd pwd cat echo clear cp mv rm rmdir mkdir touch edit")
    printLine("df mount label components uptime free wget lua run")
    printLine("reboot shutdown exit help")
  elseif cmd == "ls" or cmd == "dir" then
    list(args[2])
  elseif cmd == "cd" then
    local path = normalize(args[2] or "/")
    if activeFs.exists(path) and activeFs.isDirectory(path) then cwd = path
    else printLine("cd: no such directory: " .. path) end
  elseif cmd == "pwd" then
    printLine(cwd)
  elseif cmd == "cat" or cmd == "type" then
    if not args[2] then printLine("cat: missing operand")
    else local data, reason = readAll(normalize(args[2])); printLine(data or ("cat: " .. tostring(reason))) end
  elseif cmd == "echo" then
    local redirect = line:match(">%s*(%S+)%s*$")
    if redirect then
      local text = line:match("^%S+%s*(.-)%s*>%s*%S+%s*$") or ""
      local ok, reason = writeAll(normalize(redirect), text .. "\n")
      if not ok then printLine("echo: " .. tostring(reason)) end
    else
      printLine(line:match("^%S+%s*(.*)$") or "")
    end
  elseif cmd == "clear" or cmd == "cls" then
    output = {}
  elseif cmd == "cp" then
    if not args[2] or not args[3] then printLine("cp: missing operand")
    else local ok, reason = copyFile(args[2], args[3]); if not ok then printLine("cp: " .. tostring(reason)) end end
  elseif cmd == "mv" then
    if not args[2] or not args[3] then printLine("mv: missing operand")
    else
      local ok, reason = copyFile(args[2], args[3])
      if ok then activeFs.remove(normalize(args[2])) else printLine("mv: " .. tostring(reason)) end
    end
  elseif cmd == "rm" or cmd == "rmdir" then
    if not args[2] then printLine(cmd .. ": missing operand")
    else local ok, reason = activeFs.remove(normalize(args[2])); if not ok then printLine(cmd .. ": " .. tostring(reason)) end end
  elseif cmd == "mkdir" then
    if not args[2] then printLine("mkdir: missing operand")
    else local ok, reason = activeFs.makeDirectory(normalize(args[2])); if not ok then printLine("mkdir: " .. tostring(reason)) end end
  elseif cmd == "touch" then
    if not args[2] then printLine("touch: missing operand")
    elseif not activeFs.exists(normalize(args[2])) then
      local ok, reason = writeAll(normalize(args[2]), "")
      if not ok then printLine("touch: " .. tostring(reason)) end
    end
  elseif cmd == "edit" then
    editor(args[2])
  elseif cmd == "df" then
    local used = activeFs.spaceUsed()
    local total = activeFs.spaceTotal()
    printLine("Filesystem  Used  Free  Total")
    printLine(activeAddress:sub(1, 8) .. "  " .. formatBytes(used) .. "  " .. formatBytes(total - used) .. "  " .. formatBytes(total))
  elseif cmd == "mount" and args[2] then
    local prefix = args[2]
    local found
    for address in component.list("filesystem") do
      if address:sub(1, #prefix) == prefix then found = address; break end
    end
    if found then
      activeAddress = found
      activeFs = component.proxy(found)
      cwd = "/"
      printLine("Mounted " .. found)
    else printLine("mount: filesystem not found") end
  elseif cmd == "mount" then
    for address in component.list("filesystem") do
      local proxy = component.proxy(address)
      printLine(address:sub(1, 8) .. "  " .. tostring(proxy.getLabel() or "") .. "  " .. formatBytes(proxy.spaceUsed()) .. "/" .. formatBytes(proxy.spaceTotal()))
    end
    printLine("mount <address-prefix> switches the active filesystem")
  elseif cmd == "label" then
    if args[2] then
      local ok, reason = pcall(activeFs.setLabel, args[2])
      if not ok then printLine("label: " .. tostring(reason)) end
    else printLine(tostring(activeFs.getLabel() or "")) end
  elseif cmd == "components" then
    for address, kind in component.list() do printLine(kind .. "  " .. address) end
  elseif cmd == "uptime" then
    printLine(string.format("%.1f seconds", computer.uptime()))
  elseif cmd == "free" then
    printLine("Memory: " .. formatBytes(computer.freeMemory()) .. " free / " .. formatBytes(computer.totalMemory()) .. " total")
  elseif cmd == "wget" then
    wget(args[2], args[3])
  elseif cmd == "lua" or cmd == "run" then
    if not args[2] then printLine(cmd .. ": missing file")
    else
      local path = normalize(args[2])
      local data, reason = readAll(path)
      if not data then printLine(cmd .. ": " .. tostring(reason))
      else
        local program, compileReason = load(data, "=" .. path, "t", _ENV)
        if not program then printLine("lua: " .. tostring(compileReason))
        else
          local ok, result = pcall(program)
          if not ok then printLine("lua: " .. tostring(result)) elseif result ~= nil then printLine(tostring(result)) end
        end
      end
    end
  elseif cmd == "reboot" then
    computer.shutdown(true)
  elseif cmd == "shutdown" then
    computer.shutdown(false)
  elseif cmd == "exit" then
    running = false
  else
    printLine(cmd .. ": command not found")
  end
end

printLine("TerminalV2 1.0.0 - OpenOS-style shell")
printLine("Type 'help' for commands. END exits.")

while running do
  redraw()
  local event = {computer.pullSignal()}
  if event[1] == "clipboard" then
    local text = tostring(event[3] or ""):gsub("[\r\n]", "")
    input = input:sub(1, cursor - 1) .. text .. input:sub(cursor)
    cursor = cursor + #text
  elseif event[1] == "scroll" then
    local direction = event[5] or 0
    if direction > 0 then scroll = math.min(#output, scroll + 3) else scroll = math.max(0, scroll - 3) end
  elseif event[1] == "key_down" then
    local char, code = event[3] or 0, event[4] or 0
    if code == KEY_END then
      running = false
    elseif code == KEY_ENTER or char == 13 then
      local line = input
      input = ""
      cursor = 1
      printLine(prompt() .. line)
      if line ~= "" then commands[#commands + 1] = line; commandPos = #commands + 1 end
      execute(line)
    elseif code == KEY_BACKSPACE or char == 8 then
      if cursor > 1 then input = input:sub(1, cursor - 2) .. input:sub(cursor); cursor = cursor - 1 end
    elseif code == KEY_DELETE then
      if cursor <= #input then input = input:sub(1, cursor - 1) .. input:sub(cursor + 1) end
    elseif code == KEY_LEFT then
      cursor = math.max(1, cursor - 1)
    elseif code == KEY_RIGHT then
      cursor = math.min(#input + 1, cursor + 1)
    elseif code == KEY_HOME then
      cursor = 1
    elseif code == KEY_UP then
      if #commands > 0 then commandPos = math.max(1, commandPos - 1); input = commands[commandPos] or ""; cursor = #input + 1 end
    elseif code == KEY_DOWN then
      if #commands > 0 then commandPos = math.min(#commands + 1, commandPos + 1); input = commands[commandPos] or ""; cursor = #input + 1 end
    elseif char >= 32 and char <= 126 then
      input = input:sub(1, cursor - 1) .. string.char(char) .. input:sub(cursor)
      cursor = cursor + 1
    end
  end
end

clear()
