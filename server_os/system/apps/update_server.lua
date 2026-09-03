local common = YellowOS.common
local updater = YellowOS.updater
local computer = rawget(_G, "computer")

if not computer then
    computer = require("computer")
end

common.header("Update Server")
common.gpu.set(3, 6, "Checking GitHub...")
local manifest, reason = updater.check()

if not manifest then
    common.message("Update Server", "Check failed:\n" .. tostring(reason))
    return
end

local free = YellowOS.fs.spaceTotal() - YellowOS.fs.spaceUsed()
local subtitle = "Current " .. YellowOS.version .. " | Latest " .. manifest.version .. " | " .. common.formatBytes(manifest.size) .. " | Free " .. common.formatBytes(free)

if not manifest.updateAvailable then
    common.message("Update Server", "Server is up to date.\nVersion: " .. YellowOS.version)
    return
end

local choice = common.menu("Server Update", subtitle, {"Install update", "Cancel"})

if choice ~= 1 then
    return
end

local ok, installReason = updater.install(manifest)

if not ok then
    common.message("Update failed", tostring(installReason))
    return
end

common.header("Update complete")
common.gpu.setForeground(0x00FF00)
common.gpu.set(3, 6, "Server updated to " .. manifest.version)
common.gpu.setForeground(0xFFFFFF)
common.gpu.set(3, 8, "Rebooting...")
computer.pullSignal(1)
computer.shutdown(true)
