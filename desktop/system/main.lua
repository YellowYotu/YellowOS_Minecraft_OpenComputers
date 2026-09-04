local common = YellowOS.common
local computer = require("computer")

local items = {
    "Files",
    "Terminal",
    "Settings",
    "About",
    "Reboot",
    "Shutdown"
}

while true do
    local selected = common.menu("Desktop Edition " .. YellowOS.version, "YellowOS Desktop", items)
    if not selected then
        selected = 4
    end

    if selected == 1 then
        common.header("Files")
        common.gpu.set(3, 6, "Files app coming next.")
        computer.pullSignal(1)
    elseif selected == 2 then
        common.header("Terminal")
        common.gpu.set(3, 6, "Terminal app coming next.")
        computer.pullSignal(1)
    elseif selected == 3 then
        common.header("Settings")
        common.gpu.set(3, 6, "Settings app coming next.")
        computer.pullSignal(1)
    elseif selected == 4 then
        common.header("About")
        common.gpu.set(3, 6, "YellowOS Desktop Edition")
        common.gpu.set(3, 7, "Version " .. YellowOS.version)
        computer.pullSignal(1.5)
    elseif selected == 5 then
        computer.shutdown(true)
    elseif selected == 6 then
        computer.shutdown(false)
    end
end
