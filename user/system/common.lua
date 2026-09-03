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

function common.waitForKey()
    while true do
        local signal, _, char, code = computer.pullSignal()

        if signal == "key_down" then
            return char or 0, code or 0
        end
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
        local signal, _, _, code = computer.pullSignal()

        if signal == "touch" then
            return
        end

        if signal == "key_down" and code == common.KEY_BACKSPACE then
            return
        end
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
        gpu.set(3, height - 1, "Tap item or use UP/DOWN + ENTER")

        local signal, _, a, b = computer.pullSignal()

        if signal == "key_down" then
            local code = b or 0

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
                return selected
            elseif code == common.KEY_BACKSPACE then
                return nil
            end
        elseif signal == "touch" then
            local y = b
            local index = y - firstRow + 1

            if index >= 1 and index <= #items then
                return index
            end
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
