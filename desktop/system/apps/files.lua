local component=rawget(_G,"component")
local computer=rawget(_G,"computer")
local c=YellowOS.common
local function read(fs,path)
 local h=fs.open(path,"r"); if not h then c.message("Files","Cannot open file"); return end; local data=""; while #data<16000 do local ch=fs.read(h,2048); if not ch then break end; data=data..ch end; fs.close(h)
 c.header("Files",path); local y=7; for line in (data.."\n"):gmatch("(.-)\n") do c.gpu.set(3,y,line:sub(1,c.width-5)); y=y+1; if y>=c.height-3 then break end end; c.footer("BACKSPACE or click to return"); while true do local e={computer.pullSignal()}; if e[1]=="touch" then return elseif e[1]=="key_down" and ((e[4] or 0)==c.KEY_BACKSPACE or (e[3] or 0)==8) then return end end
end
local drives,names={},{}
for a in component.list("filesystem") do local fs=component.proxy(a); if fs.getLabel()~="tmpfs" then local label=fs.getLabel() or a:sub(1,8); drives[#drives+1]={fs=fs,label=label}; names[#names+1]=label.."   "..c.formatBytes(fs.spaceUsed()).." / "..c.formatBytes(fs.spaceTotal()) end end
local di=c.menu("Files","Storage devices",names); if not di then return end
local fs=drives[di].fs; local path="/"
while true do
 local entries={}; for n in fs.list(path) do entries[#entries+1]=n end; table.sort(entries)
 local items={"[..]"}; for _,n in ipairs(entries) do local full=path=="/" and "/"..n or path.."/"..n; items[#items+1]=(fs.isDirectory(full) and "[DIR] " or "")..n end
 local s=c.menu("Files",path,items); if not s then return elseif s==1 then if path=="/" then return end; path=path:match("^(.*)/[^/]+/?$") or "/"; if path=="" then path="/" end else local n=entries[s-1]; local full=path=="/" and "/"..n or path.."/"..n; if fs.isDirectory(full) then path=full:gsub("/$","") else read(fs,full) end end
end
