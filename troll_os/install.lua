local component=require("component")
local shell=require("shell")
local filesystem=require("filesystem")
local computer=require("computer")

local args=shell.parse(...)
local targetPath=args[1]
if not targetPath then io.stderr:write("Usage: lua install.lua /mnt/xxx\n"); return end
local proxy=filesystem.get(targetPath)
if not proxy then io.stderr:write("Target filesystem not found\n"); return end
local internetAddress=component.list("internet")()
if not internetAddress then io.stderr:write("Internet Card not found\n"); return end
local internet=component.proxy(internetAddress)
local BASE="https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/troll_os/"

local function get(url)
  local req,reason=internet.request(url.."?t="..tostring(math.floor(computer.uptime()*1000)))
  if not req then return nil,reason end
  local data=""
  while true do
    local chunk,err=req.read(4096)
    if chunk then data=data..chunk elseif err then req.close(); return nil,err else break end
  end
  req.close()
  return data
end

local manifest,reason=get(BASE.."manifest.txt")
if not manifest then io.stderr:write("Manifest download failed: "..tostring(reason).."\n"); return end
local version=manifest:match("version=([^\r\n]+)") or "unknown"
local files={}
for line in manifest:gmatch("[^\r\n]+") do
  if line~="" and not line:match("^version=") and not line:match("^size=") and line:sub(1,1)~="#" then files[#files+1]=line end
end

print("Installing TrollOS "..version.." to "..targetPath)
for i,path in ipairs(files) do
  print("["..i.."/"..#files.."] "..path)
  local data,err=get(BASE..path)
  if not data then io.stderr:write("Download failed: "..tostring(err).."\n"); return end
  local h,openErr=proxy.open("/"..path,"w")
  if not h then io.stderr:write("Write failed: "..tostring(openErr).."\n"); return end
  proxy.write(h,data)
  proxy.close(h)
end
pcall(proxy.setLabel,"TrollOS")
print("Install complete. Remove OpenOS media and reboot.")
