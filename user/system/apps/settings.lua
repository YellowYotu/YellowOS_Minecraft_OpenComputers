local common = YellowOS.common
local settings = YellowOS.settings

while true do
    local items = {
        "Automatic updates: " .. (settings.autoUpdates and "ON" or "OFF"),
        "Update channel: " .. settings.updateChannel,
        "Browser home: " .. settings.browserHome,
        "Back"
    }

    local selected = common.menu("Settings", YellowOS.device, items)

    if not selected or selected == 4 then
        settings.save()
        return
    elseif selected == 1 then
        settings.autoUpdates = not settings.autoUpdates
    elseif selected == 2 then
        settings.updateChannel = settings.updateChannel == "stable" and "beta" or "stable"
    elseif selected == 3 then
        common.message("Browser Home", "URL editing needs a keyboard. Current:\n" .. settings.browserHome)
    end

    settings.save()
end
