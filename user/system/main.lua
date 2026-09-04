local common = YellowOS.common
local computer = rawget(_G, "computer")

if not computer then
    computer = require("computer")
end

local network = YellowOS.network
local updater = YellowOS.updater
local settings = YellowOS.settings

local function installPendingUpdate()
    common.header("Update received", YellowOS.device)
    common.gpu.setForeground(common.colors.text)
    common.gpu.set(3, 7, "Checking GitHub release...")

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
    common.header("YellowOS Update", YellowOS.device)
    common.panel(3, 7, common.width - 5, 7, common.colors.panel)
    common.gpu.setBackground(common.colors.panel)
    common.gpu.setForeground(common.colors.text)
    common.gpu.set(5, 8, "Version: " .. manifest.version)
    common.gpu.set(5, 10, "Update size: " .. common.formatBytes(manifest.size))
    common.gpu.set(5, 11, "Free storage: " .. common.formatBytes(free))

    if manifest.size > 0 and free < manifest.size then
        common.gpu.setForeground(common.colors.danger)
        common.gpu.set(5, 13, "Not enough storage.")
        computer.pullSignal(3)
        return
    end

    common.gpu.setForeground(common.colors.success)
    common.gpu.set(5, 13, "Installing automatically...")
    computer.pullSignal(0.6)

    local ok, installReason = updater.install(manifest)

    if not ok then
        common.message("Update failed", tostring(installReason))
        return
    end

    common.header("Update complete", YellowOS.device)
    common.gpu.setForeground(common.colors.success)
    common.gpu.set(3, 7, "YellowOS updated to " .. manifest.version)
    common.gpu.setForeground(common.colors.text)
    common.gpu.set(3, 9, "Rebooting...")
    computer.pullSignal(1)
    computer.shutdown(true)
end

YellowOS.handleSignal = function(...)
    if network.processSignal(...) and settings.autoUpdates then
        installPendingUpdate()
    end
end

network.broadcastPresence()

local items = {
    {name = "Apps", path = "/system/apps/apps.lua"},
    {name = "YellowStore", path = "/system/apps/appstore.lua"},
    {name = "Files", path = "/system/apps/files.lua"},
    {name = "Browser", path = "/system/apps/browser.lua"},
    {name = "Terminal", path = "/system/apps/terminal.lua"},
    {name = "Account", path = "/system/apps/account.lua"},
    {name = "Updates", path = "/system/apps/updates.lua"},
    {name = "Settings", path = "/system/apps/settings.lua"},
    {name = "About", path = "/system/apps/about.lua"},
    {name = "Reboot"},
    {name = "Shutdown"}
}

while true do
    local subtitle = YellowOS.device

    if network.pendingUpdate and not settings.autoUpdates then
        subtitle = subtitle .. " | Update " .. network.pendingUpdate.version .. " available"
    end

    local selected = common.home("Home", subtitle, items)

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
