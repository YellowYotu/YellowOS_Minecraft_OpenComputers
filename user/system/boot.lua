YellowOS.loadFile("/system/common.lua")
YellowOS.loadFile("/system/settings.lua")
YellowOS.loadFile("/system/http.lua")
YellowOS.loadFile("/system/updater.lua")
YellowOS.loadFile("/system/network.lua")

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
gpu.set(3, 10, "Starting services...")
computer.pullSignal(0.4)
gpu.set(3, 11, "Network and updater ready.")
computer.pullSignal(0.4)
YellowOS.loadFile("/system/main.lua")
