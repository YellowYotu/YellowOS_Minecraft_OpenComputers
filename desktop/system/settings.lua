local fs=YellowOS.fs
local settings={autoUpdates=false,browserHome="https://example.com"}
local path="/system/settings.cfg"
if fs.exists(path) then local h=fs.open(path,"r"); local data=""; while true do local ch=fs.read(h,2048); if not ch then break end; data=data..ch end; fs.close(h); for k,v in data:gmatch("([%w_]+)=([^\r\n]+)") do if k=="autoUpdates" then settings.autoUpdates=(v=="true") elseif k=="browserHome" then settings.browserHome=v end end end
function settings.save() local h=fs.open(path,"w"); if not h then return false end; fs.write(h,"autoUpdates="..tostring(settings.autoUpdates).."\nbrowserHome="..settings.browserHome.."\n"); fs.close(h); return true end
YellowOS.settings=settings
