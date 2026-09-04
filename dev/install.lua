local component=require("component")
local shell=require("shell")
local args=shell.parse(...)
local targetPath=args[1]
if not targetPath then io.stderr:write("Usage: lua install.lua /mnt/xxx\n"); return end
local proxy=require("filesystem").get(targetPath)
if not proxy then io.stderr:write("Target filesystem not found\n"); return end
local internetAddress=component.list("internet")(); if not internetAddress then io.stderr:write("Internet Card not found\n"); return end
local internet=component.proxy(internetAddress)
local BASE="https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/dev/"
local function get(url)
 local r,reason=internet.request(url.."?t="..tostring(math.floor(require("computer").uptime()*1000))); if not r then return nil,reason end
 local d=""; while true do local c,e=r.read(4096); if c then d=d..c elseif e then r.close(); return nil,e else break end end; r.close(); return d
end
local manifest,reason=get(BASE.."manifest.txt"); if not manifest then io.stderr:write("Manifest download failed: "..tostring(reason).."\n"); return end
local files={}; local version=manifest:match("version=([^\r\n]+)") or "unknown"
for line in manifest:gmatch("[^\r\n]+") do if line~="" and not line:match("^version=") and not line:match("^size=") and line:sub(1,1)~="#" then table.insert(files,line) end end
local function mkdirs(path) local dir=path:match("^(.*)/[^/]+$"); if not dir then return end; local cur=""; for p in dir:gmatch("[^/]+") do cur=cur.."/"..p; if not proxy.exists(cur) then proxy.makeDirectory(cur) end end end
print("Installing YellowOS Development Edition "..version.." to "..targetPath)
for i,path in ipairs(files) do
 io.write("["..i.."/"..#files.."] "..path.."\n"); local data,r=get(BASE..path); if not data then io.stderr:write("Download failed: "..tostring(r).."\n"); return end
 mkdirs("/"..path); local h,er=proxy.open("/"..path,"w"); if not h then io.stderr:write("Write failed: "..tostring(er).."\n"); return end; proxy.write(h,data); proxy.close(h)
end
proxy.setLabel("YellowOS_Dev")
print("Install complete. Remove OpenOS media and reboot.")
