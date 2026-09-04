local computer=rawget(_G,"computer")
local fs=YellowOS.fs
local http=YellowOS.http
local c=YellowOS.common
local updater={}
local BASE="https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/desktop/"
local function cmp(a,b)
 local av,bv={},{}; for n in tostring(a):gmatch("%d+") do av[#av+1]=tonumber(n) end; for n in tostring(b):gmatch("%d+") do bv[#bv+1]=tonumber(n) end
 for i=1,math.max(#av,#bv) do local x,y=av[i] or 0,bv[i] or 0; if x<y then return -1 elseif x>y then return 1 end end; return 0
end
local function parse(data)
 local m={version="0.0.0",size=0,files={}}
 for line in data:gmatch("[^\r\n]+") do if line:match("^version=") then m.version=line:match("^version=(.+)$") elseif line:match("^size=") then m.size=tonumber(line:match("^size=(%d+)$")) or 0 elseif line~="" and line:sub(1,1)~="#" then m.files[#m.files+1]=line end end
 return m
end
local function ensure(path)
 local d=path:match("^(.*)/[^/]+$"); if not d or d=="" then return true end; local cur=""
 for part in d:gmatch("[^/]+") do cur=cur.."/"..part; if not fs.exists(cur) then local ok,r=fs.makeDirectory(cur); if not ok then return false,r end end end; return true
end
function updater.check()
 local key=tostring(math.floor(computer.uptime()*1000)); local data,r=http.get(BASE.."manifest.txt?t="..key); if not data then return nil,r end
 local m=parse(data); m.updateAvailable=cmp(YellowOS.version,m.version)<0; return m
end
function updater.install(m)
 local free=fs.spaceTotal()-fs.spaceUsed(); if m.size>0 and free<m.size then return false,"Not enough storage" end
 local key=tostring(math.floor(computer.uptime()*1000))
 for i,path in ipairs(m.files) do c.header("Updating Desktop","Version "..m.version); c.gpu.setForeground(0xFFFFFF); c.gpu.set(4,8,"Downloading "..i.."/"..#m.files); c.gpu.set(4,10,path:sub(1,c.width-8)); local data,r=http.get(BASE..path.."?v="..m.version.."&t="..key); if not data then return false,r end; local ok,dr=ensure("/"..path); if not ok then return false,dr end; local h,er=fs.open("/"..path,"w"); if not h then return false,er end; fs.write(h,data); fs.close(h) end
 return true
end
YellowOS.updater=updater
