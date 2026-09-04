local component = rawget(_G, "component")
local computer = rawget(_G, "computer")

if not component then
    component = require("component")
end

if not computer then
    computer = require("computer")
end

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

common.colors = {
    background = 0x101318,
    panel = 0x1C222B,
    panelAlt = 0x252D38,
    accent = 0xF3C623,
    accentDark = 0x8C7415,
    text = 0xF4F4F4,
    muted = 0x8D98A6,
    danger = 0xE85D5D,
    success = 0x55C878,
    terminal = 0x0B0E12
}

function common.isEnter(char, code)
    return code == common.KEY_ENTER or char == 13
end

function common.isBack(char, code)
    return code == common.KEY_BACKSPACE or char == 8
end

function common.clear(color)
    gpu.setBackground(color or common.colors.background)
    gpu.setForeground(common.colors.text)
    gpu.fill(1, 1, width, height, " ")
end

function common.panel(x, y, w, h, color)
    gpu.setBackground(color or common.colors.panel)
    gpu.fill(x, y, math.max(1, w), math.max(1, h), " ")
end

function common.button(x, y, w, h, label, selected)
    local bg = selected and common.colors.accent or common.colors.panelAlt
    local fg = selected and 0x111111 or common.colors.text
    common.panel(x, y, w, h, bg)
    gpu.setForeground(fg)
    gpu.setBackground(bg)
    local tx = x + math.max(1, math.floor((w - #label) / 2))
    local ty = y + math.floor((h - 1) / 2)
    gpu.set(tx, ty, label:sub(1, math.max(1, w - 2)))
end

function common.header(title, subtitle)
    common.clear()
    common.panel(1, 1, width, 3, common.colors.panel)
    gpu.setBackground(common.colors.panel)
    gpu.setForeground(common.colors.accent)
    gpu.set(2, 2, "YellowOS")
    gpu.setForeground(common.colors.text)
    gpu.set(12, 2, tostring(title or "" ):sub(1, math.max(1, width - 13)))

    if subtitle and height > 5 then
        gpu.setBackground(common.colors.background)
        gpu.setForeground(common.colors.muted)
        gpu.set(3, 5, tostring(subtitle):sub(1, math.max(1, width - 5)))
    end
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
    local boxW = math.max(20, width - 8)
    local boxH = math.max(7, math.min(height - 6, 12))
    local boxX = math.floor((width - boxW) / 2) + 1
    local boxY = math.floor((height - boxH) / 2) + 1
    common.panel(boxX, boxY, boxW, boxH, common.colors.panel)

    gpu.setBackground(common.colors.panel)
    gpu.setForeground(common.colors.text)
    local y = boxY + 2

    for line in tostring(text):gmatch("[^\n]+") do
        gpu.set(boxX + 2, y, line:sub(1, math.max(1, boxW - 4)))
        y = y + 1
        if y >= boxY + boxH - 2 then
            break
        end
    end

    common.button(boxX + math.floor((boxW - 10) / 2), boxY + boxH - 2, 10, 1, "BACK", true)

    while true do
        local event = {computer.pullSignal()}
        local signal = event[1]
        local char = event[3] or 0
        local code = event[4] or 0

        if signal == "touch" then
            return
        elseif signal == "key_down" and common.isBack(char, code) then
            return
        else
            common.dispatchSystemEvent(event)
        end
    end
end

function common.menu(title, subtitle, items, selected)
    selected = selected or 1
    local firstRow = 7
    local rowH = 2

    while true do
        common.header(title, subtitle)
        local visible = math.max(1, math.floor((height - firstRow - 1) / rowH))
        local first = math.max(1, math.min(selected - math.floor(visible / 2), math.max(1, #items - visible + 1)))

        for slot = 1, visible do
            local i = first + slot - 1
            if i > #items then
                break
            end
            local y = firstRow + (slot - 1) * rowH
            common.button(3, y, width - 5, 1, tostring(items[i]), i == selected)
        end

        gpu.setBackground(common.colors.background)
        gpu.setForeground(common.colors.muted)
        gpu.set(2, height, common.hasKeyboard and "BACKSPACE  |  arrows + ENTER" or "Tap a button")

        local event = {computer.pullSignal()}
        local signal = event[1]

        if signal == "key_down" then
            local char = event[3] or 0
            local code = event[4] or 0

            if code == common.KEY_UP then
                selected = selected > 1 and selected - 1 or #items
            elseif code == common.KEY_DOWN then
                selected = selected < #items and selected + 1 or 1
            elseif common.isEnter(char, code) then
                return selected
            elseif common.isBack(char, code) then
                return nil
            end
        elseif signal == "touch" then
            local x = event[3]
            local y = event[4]
            if x >= 3 and x <= width - 2 and y >= firstRow then
                local slot = math.floor((y - firstRow) / rowH) + 1
                local index = first + slot - 1
                if index >= 1 and index <= #items then
                    return index
                end
            end
        else
            common.dispatchSystemEvent(event)
        end
    end
end

function common.home(title, subtitle, items, selected)
    selected = selected or 1
    local cols = width >= 60 and 3 or 2
    local gap = 2
    local tileW = math.floor((width - 4 - gap * (cols - 1)) / cols)
    local tileH = 4
    local startY = 7

    while true do
        common.header(title, subtitle)
        for i, item in ipairs(items) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local x = 3 + col * (tileW + gap)
            local y = startY + row * (tileH + 1)
            if y + tileH - 1 <= height - 1 then
                common.button(x, y, tileW, tileH, item.name or tostring(item), i == selected)
            end
        end

        local event = {computer.pullSignal()}
        local signal = event[1]
        if signal == "key_down" then
            local char = event[3] or 0
            local code = event[4] or 0
            if code == common.KEY_LEFT then
                selected = math.max(1, selected - 1)
            elseif code == common.KEY_RIGHT then
                selected = math.min(#items, selected + 1)
            elseif code == common.KEY_UP then
                selected = math.max(1, selected - cols)
            elseif code == common.KEY_DOWN then
                selected = math.min(#items, selected + cols)
            elseif common.isEnter(char, code) then
                return selected
            end
        elseif signal == "touch" then
            local tx, ty = event[3], event[4]
            for i = 1, #items do
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                local x = 3 + col * (tileW + gap)
                local y = startY + row * (tileH + 1)
                if tx >= x and tx < x + tileW and ty >= y and ty < y + tileH then
                    return i
                end
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
