YellowOS.loadFile("/system/common.lua")
YellowOS.loadFile("/system/http.lua")
local c=YellowOS.common
local computer=rawget(_G,"computer")
c.clear(); c.gpu.setForeground(0xFFD23F); c.gpu.set(3,3,"YellowOS Development Edition"); c.gpu.setForeground(0xFFFFFF); c.gpu.set(3,5,"Version "..YellowOS.version); c.gpu.setForeground(0x888888); c.gpu.set(3,8,"Developer tools and SDK ready."); computer.pullSignal(0.7)
YellowOS.loadFile("/system/main.lua")
