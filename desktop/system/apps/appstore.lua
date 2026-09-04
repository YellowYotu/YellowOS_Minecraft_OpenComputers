local c=YellowOS.common
local http=YellowOS.http
local fs=YellowOS.fs
local computer=rawget(_G,"computer")
local CATALOG="https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/store/catalog.txt"
local BASE="https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/"
local function mkdir(p) if not fs.exists(p) then return fs.makeDirectory(p) end return true end
local function write(p,d) local h,r=fs.open(p,"w"); if not h then return false,r end; fs.write(h,d); fs.close(h); return true end
local function parse(data)
 local out={}
 for line in data:gmatch("[^\r\n]+") do
  if line~="" and line:sub(1,1)~="#" then
   local id,name,ver,author,target,desc,path=line:match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.+)$")
   if id and (target=="desktop" or target=="all") then table.insert(out,{id=id,name=name,version=ver,author=author,description=desc,path=path}) end
  end
 end
 return out
end
c.header("YellowStore","Loading catalog...")
local key=tostring(math.floor((computer and computer.uptime() or 0)*1000))
local data,reason=http.get(CATALOG.."?t="..key)
if not data then c.message("YellowStore","Cannot load catalog:\n"..tostring(reason)); return end
local apps=parse(data)
if #apps==0 then c.message("YellowStore","No desktop applications are published yet."); return end
while true do
 local names={}; for _,a in ipairs(apps) do table.insert(names,a.name.."  "..a.version) end; table.insert(names,"Back")
 local s=c.menu("YellowStore","Desktop applications",names)
 if not s or s==#names then return end
 local a=apps[s]
 local choice=c.menu(a.name,"by "..a.author.." | "..a.version,{a.description,"Install","Back"})
 if choice==2 then
  c.header("YellowStore","Downloading "..a.name.."...")
  local code,dr=http.get(BASE..a.path.."?v="..a.version.."&t="..key)
  if not code then c.message("Install failed",tostring(dr)) else
   local ok,r=mkdir("/apps"); if ok then ok,r=mkdir("/apps/"..a.id) end
   if not ok then c.message("Install failed",tostring(r)) else
    local w,wr=write("/apps/"..a.id.."/main.lua",code)
    if w then write("/apps/"..a.id.."/app.cfg","id="..a.id.."\nname="..a.name.."\nversion="..a.version.."\nauthor="..a.author.."\n"); c.message("YellowStore",a.name.." installed.") else c.message("Install failed",tostring(wr)) end
   end
  end
 end
end
