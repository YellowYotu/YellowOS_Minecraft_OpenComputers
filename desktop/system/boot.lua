local computer=rawget(_G,"computer")
YellowOS.loadFile("/system/common.lua")
YellowOS.loadFile("/system/settings.lua")
YellowOS.loadFile("/system/http.lua")
YellowOS.loadFile("/system/updater.lua")
local c=YellowOS.common
c.clear(); c.gpu.setForeground(0xFFD23F); c.gpu.set(3,3,"YellowOS Desktop"); c.gpu.setForeground(0xFFFFFF); c.gpu.set(3,5,"Version "..YellowOS.version); c.gpu.setForeground(0x888888); c.gpu.set(3,8,"Starting desktop services..."); computer.pullSignal(0.5)
local manifest=YellowOS.updater.check()
if manifest and manifest.updateAvailable then
 if YellowOS.settings.autoUpdates then
  local ok=YellowOS.updater.install(manifest); if ok then computer.shutdown(true) end
 else
  YellowOS.pendingUpdate=manifest
 end
end
YellowOS.loadFile("/system/main.lua")
