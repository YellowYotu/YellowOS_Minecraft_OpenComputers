local c=YellowOS.common
local fs=YellowOS.fs
local function read(p) local h=fs.open(p,"r"); if not h then return nil end; local d=""; while true do local x=fs.read(h,2048); if not x then break end; d=d..x end; fs.close(h); return d end
if not fs.exists("/apps") then c.message("Applications","No applications installed.\nOpen YellowStore to install some."); return end
while true do
 local apps={}
 for name in fs.list("/apps") do
  local id=name:gsub("/$",""); local main="/apps/"..id.."/main.lua"
  if fs.exists(main) then local cfg=read("/apps/"..id.."/app.cfg") or ""; table.insert(apps,{name=cfg:match("name=([^\r\n]+)") or id,path=main}) end
 end
 table.sort(apps,function(a,b) return a.name:lower()<b.name:lower() end)
 if #apps==0 then c.message("Applications","No applications installed."); return end
 local names={}; for _,a in ipairs(apps) do table.insert(names,a.name) end; table.insert(names,"Back")
 local s=c.menu("Applications","Installed software",names); if not s or s==#names then return end
 local code=read(apps[s].path)
 if not code then c.message("Application error","Cannot read application.") else
  local p,r=load(code,"="..apps[s].path,"t",_ENV); if not p then c.message("Application error",tostring(r)) else local ok,rr=pcall(p); if not ok then c.message("Application error",tostring(rr)) end end
 end
end
