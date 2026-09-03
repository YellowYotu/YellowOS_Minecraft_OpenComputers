YellowOS.loadFile("/system/common.lua")

local common = YellowOS.common
local gpu = common.gpu
local computer = computer

common.clear()
gpu.setForeground(0xFFFF00)
gpu.set(3, 3, "YellowOS")
gpu.setForeground(0xFFFFFF)
gpu.set(3, 5, YellowOS.edition)
gpu.set(3, 6, YellowOS.device)
gpu.set(3, 7, "Version " .. YellowOS.version)
gpu.setForeground(0x808080)
gpu.set(3, 10, "Starting YellowOS...")
computer.pullSignal(0.7)
YellowOS.loadFile("/system/main.lua")
