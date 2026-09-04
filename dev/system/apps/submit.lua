local component=rawget(_G,"component")
local computer=rawget(_G,"computer")
local c=YellowOS.common
local modemAddress=component.list("modem")()
if not modemAddress then c.message("Submit App","Wireless Network Card is required."); return end
local modem=component.proxy(modemAddress); local PORT=24121; modem.open(PORT)

local drives={}; local names={}
for addr in component.list("filesystem") do
 local fs=component.proxy(addr); local label=fs.getLabel() or addr:sub(1,8); table.insert(drives,{addr=addr,fs=fs,label=label}); table.insert(names,label.."  "..addr:sub(1,8))
end
table.insert(names,"Cancel")
local s=c.menu("Submit App","Choose disk containing your program",names); if not s or s==#names then return end
local drive=drives[s]
local path=c.input("Submit App","Program path on "..drive.label,"/main.lua"); if not path then return end
if path:sub(1,1)~="/" then path="/"..path end
local h,reason=drive.fs.open(path,"r"); if not h then c.message("Submit App","Cannot open program:\n"..tostring(reason)); return end
local code=""; while true do local x=drive.fs.read(h,4096); if not x then break end; code=code..x end; drive.fs.close(h)
if #code==0 then c.message("Submit App","Program file is empty."); return end

local id=c.input("Submit App","Application ID (letters/numbers/_/-)",""); if not id then return end
id=id:lower():gsub("[^%w_%-]",""); if id=="" then c.message("Submit App","Invalid application ID."); return end
local name=c.input("Submit App","Display name",id); if not name then return end
local version=c.input("Submit App","Version","1.0.0"); if not version then return end
local author=c.input("Submit App","Developer name","Developer"); if not author then return end
local targetChoice=c.menu("Submit App","Where should this app run?",{"YellowPad (mobile)","Desktop PC","Both","Cancel"}); if not targetChoice or targetChoice==4 then return end
local target=({"mobile","desktop","all"})[targetChoice]
local confirm=c.menu("Submit App",name.." "..version.." | "..target,{"Send for review","Cancel"}); if confirm~=1 then return end

local sid=computer.address():sub(1,8).."-"..tostring(math.floor(computer.uptime()*1000))
local chunkSize=5000; local total=math.ceil(#code/chunkSize)
modem.broadcast(PORT,"YELLOWSTORE_SUBMIT_BEGIN",sid,id,name,version,author,target,total,#code)
for i=1,total do
 local chunk=code:sub((i-1)*chunkSize+1,math.min(i*chunkSize,#code))
 modem.broadcast(PORT,"YELLOWSTORE_SUBMIT_CHUNK",sid,i,chunk)
 computer.pullSignal(0.05)
end
modem.broadcast(PORT,"YELLOWSTORE_SUBMIT_END",sid)

c.header("Submit App","Waiting for YellowOS Server...")
c.gpu.set(4,8,"Submission: "..sid)
local deadline=computer.uptime()+12
while computer.uptime()<deadline do
 local e={computer.pullSignal(1)}
 if e[1]=="modem_message" and e[4]==PORT and e[6]=="YELLOWSTORE_SUBMIT_RESULT" and e[7]==sid then
  local ok=e[8]; local msg=e[9] or ""
  c.message("Submit App",(ok and "Submitted successfully.\n" or "Submission failed.\n")..tostring(msg)); return
 end
end
c.message("Submit App","Sent to the network.\nNo acknowledgement was received.\nCheck that YellowOS Server Edition 0.2.2+ is online.")
