local common = YellowOS.common
local updater = YellowOS.updater

common.header("Updates")
common.gpu.setForeground(0xFFFFFF)
common.gpu.set(3, 6, "Checking GitHub...")

local manifest, reason = updater.check()

if not manifest then
    common.message("Updates", "Check failed:\n" .. tostring(reason))
    return
end

local free = YellowOS.fs.spaceTotal() - YellowOS.fs.spaceUsed()
local lines = {
    "Current: " .. YellowOS.version,
    "Latest:  " .. manifest.version,
    "Update size: " .. common.formatBytes(manifest.size),
    "Free storage: " .. common.formatBytes(free)
}

if not manifest.updateAvailable then
    table.insert(lines, "")
    table.insert(lines, "YellowOS is up to date.")
    common.message("Updates", table.concat(lines, "\n"))
    return
end

local choice = common.menu("Update available", table.concat(lines, " | "), {"Install now", "Later"})

if choice ~= 1 then
    return
end

local ok, installReason = updater.install(manifest)

if not ok then
    common.message("Update failed", tostring(installReason))
    return
end

common.header("Updates")
common.gpu.setForeground(0x00FF00)
common.gpu.set(3, 6, "Update installed successfully.")
common.gpu.setForeground(0xFFFFFF)
common.gpu.set(3, 8, "Rebooting...")
computer.pullSignal(1)
computer.shutdown(true)
