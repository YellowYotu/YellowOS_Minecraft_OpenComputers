local common = YellowOS.common
local gpu = common.gpu
local computer = computer

local selected = 1
local items = {
    "Files",
    "Account",
    "Updates",
    "Settings",
    "About",
    "Reboot",
    "Shutdown"
}

while true do
    common.header(YellowOS.edition .. " " .. YellowOS.version)
    gpu.setForeground(0x808080)
    gpu.set(3, 4, YellowOS.device)

    for i, item in ipairs(items) do
        if i == selected then
            gpu.setBackground(0xFFFFFF)
            gpu.setForeground(0x000000)
        else
            gpu.setBackground(0x000000)
            gpu.setForeground(0xFFFFFF)
        end

        gpu.fill(3, i + 5, common.width - 5, 1, " ")
        gpu.set(5, i + 5, item)
    end

    gpu.setBackground(0x000000)
    gpu.setForeground(0x808080)
    gpu.set(3, common.height - 1, "UP/DOWN Select    ENTER Open")

    local _, code = common.waitForKey()

    if code == common.KEY_UP then
        selected = selected - 1

        if selected < 1 then
            selected = #items
        end
    elseif code == common.KEY_DOWN then
        selected = selected + 1

        if selected > #items then
            selected = 1
        end
    elseif code == common.KEY_ENTER then
        if selected == 6 then
            computer.shutdown(true)
        elseif selected == 7 then
            computer.shutdown(false)
        else
            common.header(items[selected])
            gpu.setForeground(0xFFFFFF)
            gpu.set(3, 6, items[selected] .. " is coming soon.")
            gpu.setForeground(0x808080)
            gpu.set(3, common.height - 1, "BACKSPACE Back")

            while true do
                local _, backCode = common.waitForKey()

                if backCode == common.KEY_BACKSPACE then
                    break
                end
            end
        end
    end
end
