local component = component
local computer = computer

local gpuAddress = component.list("gpu")()
local screenAddress = component.list("screen")()

if not gpuAddress then
    error("GPU not found")
end

if not screenAddress then
    error("Screen not found")
end

local gpu = component.proxy(gpuAddress)
gpu.bind(screenAddress)

local maxWidth, maxHeight = gpu.maxResolution()
gpu.setResolution(maxWidth, maxHeight)

local width, height = gpu.getResolution()
local common = {}

common.gpu = gpu
common.width = width
common.height = height
common.KEY_ENTER = 28
common.KEY_BACKSPACE = 14
common.KEY_UP = 200
common.KEY_DOWN = 208
common.KEY_LEFT = 203
common.KEY_RIGHT = 205
common.hasKeyboard = component.list("keyboard")() ~= nil

function common.isEnter(char, code)
    return code == common.KEY_ENTER or char == 13
end

function common.isBack(char, code)
    return code == common.KEY_BACKSPACE or char == 8
end

function common.clear()
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, width, height, " ")
end

function common.header(title)
    common.clear()
    gpu.setBackground(0x202020)
    gpu.fill(1, 1, width, 3, " ")
    gpu.setForeground(0xFFFF00)
    gpu.set(2, 2, "YellowOS")
    gpu.setForeground(0xFFFFFF)
    gpu.set(12, 2, title)
    gpu.setBackground(0x000000)
end

function common.waitInput(timeout)
    local event = {computer.pullSignal(timeout)}
    return table.unpack(event)
end

function common.dispatchSystemEvent(event)
    if YellowOS.handleSignal then
        return YellowOS.handleSignal(table.unpack(event))
    end

    return false
end

function common.waitForKey()
    while true do
        local event = {computer.pullSignal()}
        local signal = event[1]

        if signal == "key_down" then
            return event[3] or 0, event[4] or 0
        end

        common.dispatchSystemEvent(event)
    end
end

function common.message(title, text)
    common.header(title)
    gpu.setForeground(0xFFFFFF)
    local y = 6

    for line in tostring(text):gmatch("[^\n]+") do
        gpu.set(3, y, line:sub(1, width - 4))
        y = y + 1

        if y >= height - 2 then
            break
        end
    end

    gpu.setForeground(0x808080)
    gpu.set(3, height - 1, "Tap anywhere or BACKSPACE")

    while true do
        local event = {computer.pullSignal()}
        local signal = event[1]
        local char = event[3] or 0
        local code = event[4] or 0

        if signal == "touch" then
            return
        end

        if signal == "key_down" and common.isBack(char, code) then
            return
        end

        common.dispatchSystemEvent(event)
    end
end

function common.menu(title, subtitle, items, selected)
    selected = selected or 1

    while true do
        common.header(title)

        if subtitle then
            gpu.setForeground(0x808080)
            gpu.set(3, 4, subtitle:sub(1, width - 4))
        end

        local firstRow = 6

        for i, item in ipairs(items) do
            local y = firstRow + i - 1

            if i == selected then
                gpu.setBackground(0xFFFFFF)
                gpu.setForeground(0x000000)
            else
                gpu.setBackground(0x000000)
                gpu.setForeground(0xFFFFFF)
            end

            gpu.fill(3, y, width - 5, 1, " ")
            gpu.set(5, y, tostring(item):sub(1, width - 7))
        end

        gpu.setBackground(0x000000)
        gpu.setForeground(0x808080)

        if common.hasKeyboard then
            gpu.set(3, height - 1, "BACKSPACE Back   UP/DOWN Select   ENTER Open")
        else
            gpu.set(3, height - 1, "Tap item   [keyboard upgrade not installed]")
        end

        local event = {computer.pullSignal()}
        local signal = event[1]

        if signal == "key_down" then
            local char = event[3] or 0
            local code = event[4] or 0

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
            elseif common.isEnter(char, code) then
                return selected
            elseif common.isBack(char, code) then
                return nil
            end
        elseif signal == "touch" then
            local x = event[3]
            local y = event[4]
            local index = y - firstRow + 1

            if y == height - 1 and x <= 14 then
                return nil
            end

            if index >= 1 and index <= #items then
                return index
            end
        else
            common.dispatchSystemEvent(event)
        end
    end
end

function common.formatBytes(bytes)
    if bytes >= 1048576 then
        return string.format("%.2f MB", bytes / 1048576)
    elseif bytes >= 1024 then
        return string.format("%.1f KB", bytes / 1024)
    end

    return tostring(bytes) .. " B"
end

YellowOS.common = common
