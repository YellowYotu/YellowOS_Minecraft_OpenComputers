local c=YellowOS.common
local fs=YellowOS.fs
local computer=rawget(_G,"computer")
local topics={{"Getting Started","/wiki/getting_started.txt"},{"App Structure","/wiki/app_structure.txt"},{"YellowPad API","/wiki/mobile_api.txt"},{"Desktop API","/wiki/desktop_api.txt"},{"UI + Input","/wiki/ui_input.txt"},{"Networking","/wiki/networking.txt"},{"YellowStore Publishing","/wiki/yellowstore.txt"},{"Examples","/wiki/examples.txt"}}
local function read(path) local h=fs.open(path,"r"); if not h then return "Missing wiki file: "..path end; local d=""; while true do local x=fs.read(h,4096); if not x then break end; d=d..x end; fs.close(h); return d end
local function view(title,text)
 local lines={}; local width=c.width-6
 for raw in (text.."\n"):gmatch("(.-)\n") do
  if raw=="" then table.insert(lines,"") else while #raw>width do table.insert(lines,raw:sub(1,width)); raw=raw:sub(width+1) end; table.insert(lines,raw) end
 end
 local offset=1
 while true do
  c.header("Dev Wiki",title.."  "..offset.."/"..math.max(1,#lines)); c.gpu.setForeground(0xFFFFFF); local y=7
  for i=offset,math.min(#lines,offset+c.height-11) do c.gpu.set(3,y,lines[i]); y=y+1 end
  c.footer("UP/DOWN scroll   BACKSPACE back")
  local e={computer.pullSignal()}; if e[1]=="key_down" then local code=e[4] or 0; if code==c.KEY_UP then offset=math.max(1,offset-1) elseif code==c.KEY_DOWN then offset=math.min(math.max(1,#lines),offset+1) elseif code==c.KEY_BACKSPACE or (e[3] or 0)==8 then return end end
 end
end
while true do local names={}; for _,t in ipairs(topics) do table.insert(names,t[1]) end; table.insert(names,"Back"); local s=c.menu("Developer Wiki","YellowOS application development",names); if not s or s==#names then return end; view(topics[s][1],read(topics[s][2])) end
