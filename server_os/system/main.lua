local common = YellowOS.common
local computer = rawget(_G, "computer")
if not computer then computer = require("computer") end

local items = {
    {name = "Files", path = "/system/apps/files.lua"},
    {name = "Terminal", path = "/system/apps/terminal.lua"},
    {name = "App Review", path = "/system/apps/review_apps.lua"},
    {name = "GitHub Setup", path = "/system/apps/github_setup.lua"},
    {name = "Update All Clients", path = "/system/apps/update_clients.lua"},
    {name = "Flash User HDD", path = "/system/apps/flash_user.lua"},
    {name = "Update Server", path = "/system/apps/update_server.lua"},
    {name = "Settings", path = "/system/apps/settings.lua"},
    {name = "System Information", path = "/system/apps/info.lua"},
    {name = "Reboot"},
    {name = "Shutdown"}
}

while true do
    local names = {}
    for _, item in ipairs(items) do table.insert(names, item.name) end
    local selected = common.menu("Server Edition " .. YellowOS.version, "YellowOS Control Center | YellowStore service online", names)
    if selected then
        local item = items[selected]
        if item.path then
            YellowOS.loadFile(item.path)
        elseif item.name == "Reboot" then
            common.clear(); common.gpu.set(3,3,"Rebooting..."); computer.shutdown(true)
        elseif item.name == "Shutdown" then
            common.clear(); common.gpu.set(3,3,"Shutting down..."); computer.shutdown(false)
        end
    end
end
