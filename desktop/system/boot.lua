YellowOS.loadFile("/system/common.lua")

local common = YellowOS.common
local gpu = common.gpu
local computer = require("computer")

common.clear()
gpu.setForeground(0xFFD23F)
gpu.set(3, 3, "YellowOS")
gpu.setForeground(0xFFFFFF)
gpu.set(3, 5, "Desktop Edition")
gpu.set(3, 6, "Version " .. YellowOS.version)
gpu.setForeground(0x808080)
gpu.set(3, 9, "Starting desktop...")
computer.pullSignal(0.5)
YellowOS.loadFile("/system/main.lua")
