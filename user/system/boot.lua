YellowOS.loadFile("/system/common.lua")
YellowOS.loadFile("/system/settings.lua")
YellowOS.loadFile("/system/http.lua")
YellowOS.loadFile("/system/updater.lua")
YellowOS.loadFile("/system/network.lua")

local common = YellowOS.common
local gpu = common.gpu
local computer = rawget(_G, "computer")

if not computer then
    computer = require("computer")
end

common.clear()
local boxW = math.max(24, math.min(common.width - 8, 44))
local boxH = 11
local boxX = math.floor((common.width - boxW) / 2) + 1
local boxY = math.max(2, math.floor((common.height - boxH) / 2) + 1)

common.panel(boxX, boxY, boxW, boxH, common.colors.panel)
gpu.setBackground(common.colors.panel)
gpu.setForeground(common.colors.accent)
gpu.set(boxX + 3, boxY + 2, "YellowOS")
gpu.setForeground(common.colors.text)
gpu.set(boxX + 3, boxY + 4, YellowOS.device)
gpu.setForeground(common.colors.muted)
gpu.set(boxX + 3, boxY + 5, "User Edition  " .. YellowOS.version)

local barX = boxX + 3
local barY = boxY + 8
local barW = boxW - 6
common.panel(barX, barY, barW, 1, common.colors.panelAlt)
computer.pullSignal(0.2)
common.panel(barX, barY, math.max(1, math.floor(barW * 0.35)), 1, common.colors.accentDark)
computer.pullSignal(0.2)
common.panel(barX, barY, math.max(1, math.floor(barW * 0.7)), 1, common.colors.accentDark)
computer.pullSignal(0.2)
common.panel(barX, barY, barW, 1, common.colors.accent)
computer.pullSignal(0.2)

YellowOS.loadFile("/system/main.lua")
