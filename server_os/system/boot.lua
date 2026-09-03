YellowOS.loadFile("/system/common.lua")
YellowOS.loadFile("/system/http.lua")
YellowOS.loadFile("/system/updater.lua")

local common = YellowOS.common
local gpu = common.gpu
local computer = rawget(_G, "computer")

if not computer then
    computer = require("computer")
end

common.clear()
gpu.setForeground(0xFFFF00)
gpu.set(3, 3, "YellowOS")
gpu.setForeground(0xFFFFFF)
gpu.set(3, 5, "Server Edition")
gpu.set(3, 6, "Version " .. YellowOS.version)
gpu.setForeground(0x808080)
gpu.set(3, 9, "Starting server services...")
computer.pullSignal(0.5)
YellowOS.loadFile("/system/main.lua")
