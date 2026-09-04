local component=require("component")
local filesystem=require("filesystem")
local shell=require("shell")
local args=shell.parse(...)
local target=args[1]
if not target then io.stderr:write("Usage: lua install.lua /mnt/xxx\n"); return end
local internetAddress=component.list("internet")()
if not internetAddress then io.stderr:write("Internet Card not found\n"); return end
local internet=component.proxy(internetAddress)
local BASE="https://raw.githubusercontent.com/YellowYotu/YellowOS_Minecraft_OpenComputers/main/desktop/"
local function get(url)
 local r,reason=internet.request(url); if not r then return nil,reason end
 local data=""; while true do local ch,er=r.read(2048); if ch then data=data..ch elseif er then r.close(); return nil,er else break end end; r.close(); return data
end
local manifest,reason=get(BASE.."manifest.txt?t="..tostring(os.time()))
if not manifest then io.stderr:write("Manifest download failed: "..tostring(reason).."\n"); return end
local version=manifest:match("version=([^\r\n]+)") or "unknown"
print("Installing YellowOS Desktop "..version.." to "..target)
for line in manifest:gmatch("[^\r\n]+") do
 if line~="" and not line:match("^[%w_]+=") and line:sub(1,1)~="#" then
  print("  "..line)
  local data,er=get(BASE..line.."?v="..version.."&t="..tostring(os.time()))
  if not data then io.stderr:write("Download failed: "..tostring(er).."\n"); return end
  local out=filesystem.concat(target,line)
  local dir=filesystem.path(out)
  if dir and dir~="" and not filesystem.exists(dir) then filesystem.makeDirectory(dir) end
  local h,openError=io.open(out,"w")
  if not h then io.stderr:write("Write failed: "..tostring(openError).."\n"); return end
  h:write(data); h:close()
 end
end
print("Install complete. Reboot and remove OpenOS media.")
