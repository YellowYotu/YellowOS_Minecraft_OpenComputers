local common = YellowOS.common
local computer = computer
local network = YellowOS.network
local updater = YellowOS.updater
local settings = YellowOS.settings

local function installPendingUpdate()
    common.header("Update received")
    common.gpu.setForeground(0xFFFFFF)
    common.gpu.set(3, 6, "Checking GitHub release...")

    local manifest, reason = updater.check()

    if not manifest then
        common.message("Update", "Cannot check update:\n" .. tostring(reason))
        return
    end

    if not manifest.updateAvailable then
        network.pendingUpdate = nil
        return
    end

    local free = YellowOS.fs.spaceTotal() - YellowOS.fs.spaceUsed()
    common.header("YellowOS Update")
    common.gpu.setForeground(0xFFFFFF)
    common.gpu.set(3, 5, "Version: " .. manifest.version)
    common.gpu.set(3, 7, "Update size: " .. common.formatBytes(manifest.size))
    common.gpu.set(3, 8, "Free storage: " .. common.formatBytes(free))

    if manifest.size > 0 and free < manifest.size then
        common.gpu.setForeground(0xFF5555)
        common.gpu.set(3, 10, "Not enough storage.")
        computer.pullSignal(3)
        return
    end

    common.gpu.setForeground(0x00FF00)
    common.gpu.set(3, 10, "Installing automatically...")
    computer.pullSignal(0.6)

    local ok, installReason = updater.install(manifest)

    if not ok then
        common.message("Update failed", tostring(installReason))
        return
    end

    common.header("Update complete")
    common.gpu.setForeground(0x00FF00)
    common.gpu.set(3, 6, "YellowOS updated to " .. manifest.version)
    common.gpu.setForeground(0xFFFFFF)
    common.gpu.set(3, 8, "Rebooting...")
    computer.pullSignal(1)
    computer.shutdown(true)
end

YellowOS.handleSignal = function(...)
    if network.processSignal(...) then
        if settings.autoUpdates then
            installPendingUpdate()
        end
    end
end

network.broadcastPresence()

local items = {
    {name = "Files", path = "/system/apps/files.lua"},
    {name = "Browser", path = "/system/apps/browser.lua"},
    {name = "Account", path = "/system/apps/account.lua"},
    {name = "Updates", path = "/system/apps/updates.lua"},
    {name = "Settings", path = "/system/apps/settings.lua"},
    {name = "About", path = "/system/apps/about.lua"},
    {name = "Reboot"},
    {name = "Shutdown"}
}

while true do
    local names = {}

    for _, item in ipairs(items) do
        table.insert(names, item.name)
    end

    local subtitle = YellowOS.device

    if network.pendingUpdate and not settings.autoUpdates then
        subtitle = subtitle .. " | Update " .. network.pendingUpdate.version .. " available"
    end

    local selected = common.menu(YellowOS.edition .. " " .. YellowOS.version, subtitle, names)

    if selected then
        local item = items[selected]

        if item.path then
            YellowOS.loadFile(item.path)
        elseif item.name == "Reboot" then
            computer.shutdown(true)
        elseif item.name == "Shutdown" then
            computer.shutdown(false)
        end
    end
end
