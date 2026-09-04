local component=rawget(_G,"component")
local computer=rawget(_G,"computer")
local c=YellowOS.common
local gpu=c.gpu

local activeFs=YellowOS.fs
local activeAddress=YellowOS.bootAddress
local cwd="/"
local history={"YellowOS Development Terminal 0.1.0","Type 'help' for commands."}
local input=""

local function norm(path)
 if not path or path=="" then return cwd end
 local full=path:sub(1,1)=="/" and path or (cwd=="/" and "/"..path or cwd.."/"..path)
 local parts={}
 for p in full:gmatch("[^/]+") do if p==".." then table.remove(parts) elseif p~="." and p~="" then table.insert(parts,p) end end
 return "/"..table.concat(parts,"/")
end
local function read(fs,path)
 local h,r=fs.open(path,"r"); if not h then return nil,r end
 local d=""; while true do local x=fs.read(h,4096); if not x then break end; d=d..x end; fs.close(h); return d
end
local function write(fs,path,data)
 local h,r=fs.open(path,"w"); if not h then return false,r end; fs.write(h,data); fs.close(h); return true
end
local function add(text)
 for line in (tostring(text or "").."\n"):gmatch("(.-)\n") do table.insert(history,line) end
 while #history>200 do table.remove(history,1) end
end
local function redraw()
 c.clear(0x060606)
 gpu.setBackground(0x202020); gpu.fill(1,1,c.width,2," "); gpu.setForeground(0xFFD23F); gpu.set(2,1,"YellowOS Dev Terminal"); gpu.setForeground(0x888888); gpu.set(c.width-18,1,activeAddress:sub(1,8)..":"..cwd)
 local maxLines=c.height-5; local start=math.max(1,#history-maxLines+1); local y=3; gpu.setBackground(0x060606); gpu.setForeground(0xDDDDDD)
 for i=start,#history do gpu.set(2,y,history[i]:sub(1,c.width-2)); y=y+1 end
 gpu.setBackground(0x151515); gpu.fill(1,c.height-1,c.width,2," "); gpu.setForeground(0xFFD23F); gpu.set(2,c.height,"> "); gpu.setForeground(0xFFFFFF); gpu.set(4,c.height,input:sub(math.max(1,#input-c.width+6)))
 gpu.setBackground(0x060606)
end
local function split(s) local t={}; for x in tostring(s):gmatch("%S+") do table.insert(t,x) end; return t end
local function list(path)
 path=norm(path); if not activeFs.exists(path) then return "Not found: "..path end
 if not activeFs.isDirectory(path) then return path end
 local out={}; for name in activeFs.list(path) do table.insert(out,name) end; table.sort(out); return table.concat(out,"  ")
end
local function edit(path)
 path=norm(path); local old=read(activeFs,path) or ""; local lines={}; for line in (old.."\n"):gmatch("(.-)\n") do table.insert(lines,line) end
 c.message("Editor","Simple line editor\nExisting file has "..#lines.." lines.\nNext screen replaces the file.\nEnter :wq on its own line to save, :q to cancel.")
 local new={}; while true do local line=c.input("Editor",path.." | line "..(#new+1),""); if line==nil or line==":q" then return false,"Cancelled" elseif line==":wq" then local ok,r=write(activeFs,path,table.concat(new,"\n")..(#new>0 and "\n" or "")); return ok,r or "Saved" else table.insert(new,line) end end
end
local function copy(src,dst)
 src,dst=norm(src),norm(dst); local d,r=read(activeFs,src); if not d then return false,r end; return write(activeFs,dst,d)
end
local function command(line)
 local a=split(line); local cmd=(a[1] or ""):lower(); if cmd=="" then return end
 if cmd=="help" then add("help ls cd pwd cat edit mkdir rm cp mv drives use df components wget lua run wiki submit clear reboot shutdown exit")
 elseif cmd=="pwd" then add(cwd)
 elseif cmd=="ls" then add(list(a[2]))
 elseif cmd=="cd" then local p=norm(a[2] or "/"); if activeFs.exists(p) and activeFs.isDirectory(p) then cwd=p else add("Not a directory: "..p) end
 elseif cmd=="cat" then local d,r=read(activeFs,norm(a[2] or "")); add(d or ("Error: "..tostring(r)))
 elseif cmd=="edit" then local ok,r=edit(a[2] or "new.lua"); add(ok and "Saved." or tostring(r))
 elseif cmd=="mkdir" then local ok,r=activeFs.makeDirectory(norm(a[2] or "")); add(ok and "Directory created." or tostring(r))
 elseif cmd=="rm" then local ok,r=activeFs.remove(norm(a[2] or "")); add(ok and "Removed." or tostring(r))
 elseif cmd=="cp" then local ok,r=copy(a[2] or "",a[3] or ""); add(ok and "Copied." or tostring(r))
 elseif cmd=="mv" then local ok,r=copy(a[2] or "",a[3] or ""); if ok then activeFs.remove(norm(a[2])); add("Moved.") else add(tostring(r)) end
 elseif cmd=="drives" then for addr in component.list("filesystem") do local f=component.proxy(addr); add(addr:sub(1,8).."  "..tostring(f.getLabel() or "").."  "..tostring(f.spaceUsed()).."/"..tostring(f.spaceTotal())) end
 elseif cmd=="use" then local p=a[2] or ""; local found=nil; for addr in component.list("filesystem") do if addr:sub(1,#p)==p then found=addr; break end end; if found then activeAddress=found; activeFs=component.proxy(found); cwd="/"; add("Using "..found:sub(1,8)) else add("Drive not found") end
 elseif cmd=="df" then add("Used "..tostring(activeFs.spaceUsed()).." / "..tostring(activeFs.spaceTotal()).." bytes")
 elseif cmd=="components" then for addr,typ in component.list() do add(typ.."  "..addr:sub(1,8)) end
 elseif cmd=="wget" then if not a[2] or not a[3] then add("Usage: wget <url> <path>") else local d,r=YellowOS.http.get(a[2]); if d then local ok,wr=write(activeFs,norm(a[3]),d); add(ok and "Downloaded." or tostring(wr)) else add("Error: "..tostring(r)) end end
 elseif cmd=="lua" or cmd=="run" then local path=norm(a[2] or ""); local d,r=read(activeFs,path); if not d then add("Error: "..tostring(r)) else local p,e=load(d,"="..path,"t",_ENV); if not p then add("Compile error: "..tostring(e)) else local ok,res=pcall(p); if not ok then add("Runtime error: "..tostring(res)) elseif res~=nil then add(tostring(res)) end end end
 elseif cmd=="wiki" then YellowOS.loadFile("/system/apps/wiki.lua")
 elseif cmd=="submit" then YellowOS.loadFile("/system/apps/submit.lua")
 elseif cmd=="clear" then history={}
 elseif cmd=="reboot" then computer.shutdown(true)
 elseif cmd=="shutdown" then computer.shutdown(false)
 elseif cmd=="exit" then return "exit"
 else add("Unknown command: "..cmd) end
end

while true do
 redraw(); local e={computer.pullSignal()}
 if e[1]=="key_down" then local ch,code=e[3] or 0,e[4] or 0
  if code==c.KEY_ENTER or ch==13 then local line=input; input=""; add("> "..line); if command(line)=="exit" then return end
  elseif code==c.KEY_BACKSPACE or ch==8 then input=input:sub(1,-2)
  elseif ch>=32 and ch<=126 then input=input..string.char(ch) end
 end
end
