local component = rawget(_G, "component")
local computer = rawget(_G, "computer")
if not component or not computer then return end

local gpuAddr = component.list("gpu")()
local screenAddr = component.list("screen")()
local keyboardAddr = component.list("keyboard")()
if not gpuAddr or not screenAddr then return end
local gpu = component.proxy(gpuAddr)
gpu.bind(screenAddr)
local w, h = gpu.getResolution()

if not keyboardAddr then
  gpu.setBackground(0x000000); gpu.setForeground(0xFFFFFF); gpu.fill(1,1,w,h," ")
  gpu.set(2,2,"TerminalV2 requires a keyboard.")
  computer.pullSignal(2)
  return
end

local fsAddr = computer.getBootAddress()
local fs = fsAddr and component.proxy(fsAddr) or nil
if not fs then return end

local cwd = "/"
local activeFs = fs
local activeAddr = fsAddr
local input = ""
local cursor = 1
local scroll = 0
local history = {}
local commandHistory = {}
local historyPos = 1
local running = true
local hostname = "yellowos"

local KEY_ENTER, KEY_BACKSPACE, KEY_UP, KEY_DOWN = 28,14,200,208
local KEY_LEFT, KEY_RIGHT, KEY_END, KEY_DELETE = 203,205,207,211
local KEY_HOME = 199

local function norm(path)
  path = tostring(path or "")
  if path == "" then return cwd end
  local full = path:sub(1,1) == "/" and path or (cwd == "/" and "/"..path or cwd.."/"..path)
  local out = {}
  for p in full:gmatch("[^/]+") do
    if p == ".." then table.remove(out)
    elseif p ~= "." and p ~= "" then out[#out+1] = p end
  end
  return "/"..table.concat(out,"/")
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
    local i = 0
    return function() i=i+1; return result[i] end
  end
  return function() return nil end
end

local function push(line)
  line = tostring(line or "")
  for part in (line.."\n"):gmatch("(.-)\n") do history[#history+1] = part end
  while #history > 500 do table.remove(history,1) end
  scroll = 0
end

local function bytes(n)
  n = tonumber(n) or 0
  if n >= 1048576 then return string.format("%.2fM", n/1048576) end
  if n >= 1024 then return string.format("%.1fK", n/1024) end
  return tostring(n).."B"
end

local function prompt()
  local short = cwd == "/" and "/" or cwd
  return "root@"..hostname..":"..short.."# "
end

local function redraw()
  gpu.setBackground(0x000000); gpu.setForeground(0xFFFFFF); gpu.fill(1,1,w,h," ")
  local visible = h - 2
  local endIndex = math.max(0, #history - scroll)
  local startIndex = math.max(1, endIndex - visible + 1)
  local y = 1
  for i=startIndex,endIndex do
    gpu.set(1,y,(history[i] or ""):sub(1,w)); y=y+1
  end
  local p = prompt()
  gpu.setForeground(0xFFFFFF)
  gpu.set(1,h,(p..input):sub(math.max(1,#p+#input-w+1)))
  local absolute = #p + cursor - 1
  local shownStart = math.max(1,#p+#input-w+1)
  local cx = absolute - shownStart + 1
  if cx >= 1 and cx <= w then
    local ch = input:sub(cursor,cursor)
    if ch == "" then ch = " " end
    gpu.setBackground(0xFFFFFF); gpu.setForeground(0x000000); gpu.set(cx,h,ch)
    gpu.setBackground(0x000000); gpu.setForeground(0xFFFFFF)
  end
end

local function split(line)
  local t = {}
  local current, quote = "", nil
  local i = 1
  while i <= #line do
    local ch = line:sub(i,i)
    if quote then
      if ch == quote then quote = nil else current = current .. ch end
    elseif ch == '"' or ch == "'" then quote = ch
    elseif ch:match("%s") then
      if #current > 0 then t[#t+1]=current; current="" end
    else current = current .. ch end
    i=i+1
  end
  if #current > 0 then t[#t+1]=current end
  return t
end

local function copyFile(src,dst)
  src,dst=norm(src),norm(dst)
  local data,reason=readAll(src); if not data then return false,reason end
  return writeAll(dst,data)
end

local function cmd_ls(a)
  local path = norm(a[2] or cwd)
  if not activeFs.exists(path) then push("ls: cannot access '"..path.."': No such file or directory"); return end
  if not activeFs.isDirectory(path) then push(path); return end
  local items={}
  for name in listIterator(path) do items[#items+1]=name end
  table.sort(items)
  local line=""
  for _,name in ipairs(items) do
    local entry = name
    if #line + #entry + 2 > w then push(line); line=entry else line = line=="" and entry or line.."  "..entry end
  end
  if line~="" then push(line) end
end

local function cmd_cat(a)
  if not a[2] then push("cat: missing operand"); return end
  local d,r=readAll(norm(a[2])); if not d then push("cat: "..tostring(r)) else push(d) end
end

local function cmd_edit(a)
  local path=norm(a[2] or "new.lua")
  push("TerminalV2 editor - type lines, :wq saves, :q cancels")
  redraw()
  local lines={}
  while true do
    local line=""
    while true do
      gpu.setBackground(0x000000); gpu.setForeground(0xFFFFFF); gpu.fill(1,h,w,1," "); gpu.set(1,h,(tostring(#lines+1).."> "..line):sub(1,w))
      local e={computer.pullSignal()}
      if e[1]=="clipboard" then line=line..tostring(e[3] or ""):gsub("[\r\n]","")
      elseif e[1]=="key_down" then
        local ch,code=e[3] or 0,e[4] or 0
        if code==KEY_END then return
        elseif code==KEY_ENTER or ch==13 then break
        elseif code==KEY_BACKSPACE or ch==8 then line=line:sub(1,-2)
        elseif ch>=32 and ch<=126 then line=line..string.char(ch) end
      end
    end
    if line==":q" then push("Cancelled"); return end
    if line==":wq" then local ok,r=writeAll(path,table.concat(lines,"\n")..(#lines>0 and "\n" or "")); push(ok and "Saved "..path or "edit: "..tostring(r)); return end
    lines[#lines+1]=line
  end
end

local function cmd_wget(a)
  if not a[2] or not a[3] then push("Usage: wget <url> <file>"); return end
  local internetAddr=component.list("internet")(); if not internetAddr then push("wget: no internet card"); return end
  local internet=component.proxy(internetAddr)
  local ok,req=pcall(internet.request,a[2]); if not ok or not req then push("wget: request failed"); return end
  local data=""
  while true do local chunk=req.read and req.read(math.huge) or nil; if not chunk then break end; data=data..chunk end
  if req.close then pcall(req.close) end
  local wr,r=writeAll(norm(a[3]),data); push(wr and ("Downloaded "..#data.." bytes") or "wget: "..tostring(r))
end

local function execute(line)
  local a=split(line); local cmd=(a[1] or ""):lower(); if cmd=="" then return end
  if cmd=="help" then
    push("OpenOS-style commands:")
    push("ls cd pwd cat echo clear cp mv rm mkdir rmdir touch edit")
    push("df mount label components uptime free wget lua run reboot shutdown exit help")
  elseif cmd=="ls" or cmd=="dir" then cmd_ls(a)
  elseif cmd=="cd" then
    local p=norm(a[2] or "/"); if activeFs.exists(p) and activeFs.isDirectory(p) then cwd=p else push("cd: no such directory: "..p) end
  elseif cmd=="pwd" then push(cwd)
  elseif cmd=="cat" or cmd=="type" then cmd_cat(a)
  elseif cmd=="echo" then
    local text=line:match("^%S+%s*(.-)%s*>%s*(%S+)%s*$")
    local out=line:match(">%s*(%S+)%s*$")
    if out and text then local ok,r=writeAll(norm(out),text.."\n"); if not ok then push("echo: "..tostring(r)) end else push(line:match("^%S+%s*(.*)$") or "") end
  elseif cmd=="clear" or cmd=="cls" then history={}
  elseif cmd=="cp" then local ok,r=copyFile(a[2] or "",a[3] or ""); push(ok and "" or "cp: "..tostring(r))
  elseif cmd=="mv" then local ok,r=copyFile(a[2] or "",a[3] or ""); if ok then activeFs.remove(norm(a[2])); else push("mv: "..tostring(r)) end
  elseif cmd=="rm" or cmd=="rmdir" then if not a[2] then push(cmd..": missing operand") else local ok,r=activeFs.remove(norm(a[2])); if not ok then push(cmd..": "..tostring(r)) end end
  elseif cmd=="mkdir" then if not a[2] then push("mkdir: missing operand") else local ok,r=activeFs.makeDirectory(norm(a[2])); if not ok then push("mkdir: "..tostring(r)) end end
  elseif cmd=="touch" then if not a[2] then push("touch: missing operand") elseif activeFs.exists(norm(a[2])) then else local ok,r=writeAll(norm(a[2]),""); if not ok then push("touch: "..tostring(r)) end end
  elseif cmd=="edit" then cmd_edit(a)
  elseif cmd=="df" then push("Filesystem  Used  Free  Total"); push(activeAddr:sub(1,8).."  "..bytes(activeFs.spaceUsed()).."  "..bytes(activeFs.spaceTotal()-activeFs.spaceUsed()).."  "..bytes(activeFs.spaceTotal()))
  elseif cmd=="mount" then
    for addr in component.list("filesystem") do local f=component.proxy(addr); push(addr:sub(1,8).."  "..tostring(f.getLabel() or "").."  "..bytes(f.spaceUsed()).."/"..bytes(f.spaceTotal())) end
    push("Use: mount <address-prefix>")
  elseif cmd=="label" then
    if a[2] then local ok,r=pcall(activeFs.setLabel,a[2]); if not ok then push("label: "..tostring(r)) end else push(tostring(activeFs.getLabel() or "")) end
  elseif cmd=="components" then for addr,typ in component.list() do push(typ.."  "..addr) end
  elseif cmd=="uptime" then push(string.format("%.1f seconds",computer.uptime()))
  elseif cmd=="free" then push("Memory: "..bytes(computer.freeMemory()).." free / "..bytes(computer.totalMemory()).." total")
  elseif cmd=="wget" then cmd_wget(a)
  elseif cmd=="lua" or cmd=="run" then
    local pth=norm(a[2] or ""); local d,r=readAll(pth); if not d then push(cmd..": "..tostring(r)) else local fn,e=load(d,"="..pth,"t",_ENV); if not fn then push("lua: "..tostring(e)) else local ok,res=pcall(fn); if not ok then push("lua: "..tostring(res)) elseif res~=nil then push(tostring(res)) end end end
  elseif cmd=="reboot" then computer.shutdown(true)
  elseif cmd=="shutdown" then computer.shutdown(false)
  elseif cmd=="exit" then running=false
  elseif cmd=="mountfs" or (cmd=="mount" and a[2]) then
    local prefix=a[2] or ""; for addr in component.list("filesystem") do if addr:sub(1,#prefix)==prefix then activeAddr=addr; activeFs=component.proxy(addr); cwd="/"; push("Mounted "..addr); return end end; push("mount: filesystem not found")
  else push(cmd..": command not found") end
end

push("OpenOS 1.7 compatible shell - TerminalV2 1.0.0")
push("Type 'help' for commands. END exits TerminalV2.")

while running do
  redraw()
  local e={computer.pullSignal()}
  if e[1]=="clipboard" then
    local txt=tostring(e[3] or ""):gsub("[\r\n]","")
    input=input:sub(1,cursor-1)..txt..input:sub(cursor); cursor=cursor+#txt
  elseif e[1]=="scroll" then
    local dir=e[5] or 0; if dir>0 then scroll=math.min(#history,scroll+3) else scroll=math.max(0,scroll-3) end
  elseif e[1]=="key_down" then
    local ch,code=e[3] or 0,e[4] or 0
    if code==KEY_END then running=false
    elseif code==KEY_ENTER or ch==13 then
      local line=input; input=""; cursor=1; push(prompt()..line)
      if line~="" then commandHistory[#commandHistory+1]=line; historyPos=#commandHistory+1 end
      execute(line)
    elseif code==KEY_BACKSPACE or ch==8 then
      if cursor>1 then input=input:sub(1,cursor-2)..input:sub(cursor); cursor=cursor-1 end
    elseif code==KEY_DELETE then
      if cursor<=#input then input=input:sub(1,cursor-1)..input:sub(cursor+1) end
    elseif code==KEY_LEFT then cursor=math.max(1,cursor-1)
    elseif code==KEY_RIGHT then cursor=math.min(#input+1,cursor+1)
    elseif code==KEY_HOME then cursor=1
    elseif code==KEY_UP then
      if #commandHistory>0 then historyPos=math.max(1,historyPos-1); input=commandHistory[historyPos] or ""; cursor=#input+1 end
    elseif code==KEY_DOWN then
      if #commandHistory>0 then historyPos=math.min(#commandHistory+1,historyPos+1); input=commandHistory[historyPos] or ""; cursor=#input+1 end
    elseif ch>=32 and ch<=126 then input=input:sub(1,cursor-1)..string.char(ch)..input:sub(cursor); cursor=cursor+1 end
  end
end

gpu.setBackground(0x000000); gpu.setForeground(0xFFFFFF); gpu.fill(1,1,w,h," ")
