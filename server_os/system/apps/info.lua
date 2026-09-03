local component = rawget(_G, "component")
local computer = rawget(_G, "computer")

if not component then
    component = require("component")
end

if not computer then
    computer = require("computer")
end

local common = YellowOS.common
local totalMemory = computer.totalMemory()
local freeMemory = computer.freeMemory()
local filesystems = 0

for _ in component.list("filesystem") do
    filesystems = filesystems + 1
end

common.message("System Information", "YellowOS Server Edition " .. YellowOS.version .. "\nMemory: " .. common.formatBytes(totalMemory - freeMemory) .. "/" .. common.formatBytes(totalMemory) .. "\nFilesystems: " .. filesystems .. "\nInternet: " .. (component.list("internet")() and "YES" or "NO") .. "\nWireless modem: " .. (component.list("modem")() and "YES" or "NO"))
