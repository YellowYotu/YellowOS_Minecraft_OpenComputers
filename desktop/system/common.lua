local component = rawget(_G, "component")
local computer = rawget(_G, "computer")
if not component or not computer then error("Missing OpenComputers globals") end

local gpuAddress = component.list("gpu")()
local screenAddress = component.list("screen")()
if not gpuAddress or not screenAddress then error("GPU and screen are required") end

local gpu = component.proxy(gpuAddress)
gpu.bind(screenAddress)
local maxWidth, maxHeight = gpu.maxResolution()
gpu.setResolution(maxWidth, maxHeight)
local width, height = gpu.getResolution()

local common = {
    gpu = gpu,
    width = width,
    height = height,
    KEY_UP = 200,
    KEY_DOWN = 208,
    KEY_LEFT = 203,
    KEY_RIGHT = 205,
    KEY_ENTER = 28,
    KEY_BACKSPACE = 14
}

function common.clear(bg)
    gpu.setBackground(bg or 0x0B0B0B)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, width, height, " ")
end

function common.header(title, subtitle)
    common.clear()
    gpu.setBackground(0x242424)
    gpu.fill(1, 1, width, 3, " ")
    gpu.setForeground(0xFFD23F)
    gpu.set(2, 2, "YellowOS")
    gpu.setForeground(0xFFFFFF)
    gpu.set(12, 2, tostring(title or "Desktop"))
    gpu.setBackground(0x0B0B0B)
    if subtitle and subtitle ~= "" then
        gpu.setForeground(0x6EA8FF)
        gpu.set(3, 5, tostring(subtitle):sub(1, width - 4))
    end
end

function common.footer(text)
    gpu.setBackground(0x161616)
    gpu.fill(1, height - 1, width, 2, " ")
    gpu.setForeground(0x888888)
    gpu.set(3, height, tostring(text or "")):sub(1, width - 4)
    gpu.setBackground(0x0B0B0B)
end

function common.formatBytes(bytes)
    bytes = tonumber(bytes) or 0
    if bytes >= 1048576 then return string.format("%.2f MB", bytes / 1048576) end
    if bytes >= 1024 then return string.format("%.1f KB", bytes / 1024) end
    return tostring(bytes) .. " B"
end

function common.message(title, text)
    common.header(title)
    gpu.setBackground(0x2D2D2D)
    gpu.fill(4, 6, width - 7, math.max(6, math.min(height - 10, 12)), " ")
    gpu.setForeground(0xFFFFFF)
    local y = 8
    for line in (tostring(text) .. "\n"):gmatch("(.-)\n") do
        gpu.set(6, y, line:sub(1, width - 12))
        y = y + 1
        if y >= height - 5 then break end
    end
    gpu.setBackground(0xFFD23F)
    gpu.setForeground(0x000000)
    local label = " BACK "
    local x = math.max(4, math.floor((width - #label) / 2))
    gpu.set(x, height - 4, label)
    gpu.setBackground(0x0B0B0B)
    while true do
        local e = {computer.pullSignal()}
        if e[1] == "touch" then return end
        if e[1] == "key_down" and ((e[4] or 0) == common.KEY_BACKSPACE or (e[3] or 0) == 8 or (e[4] or 0) == common.KEY_ENTER) then return end
    end
end

function common.menu(title, subtitle, items, selected)
    selected = selected or 1
    local firstRow = 7
    while true do
        common.header(title, subtitle)
        for i, item in ipairs(items) do
            local y = firstRow + (i - 1) * 2
            if y >= height - 2 then break end
            if i == selected then
                gpu.setBackground(0xFFD23F)
                gpu.setForeground(0x000000)
            else
                gpu.setBackground(0x303030)
                gpu.setForeground(0xFFFFFF)
            end
            gpu.fill(4, y, width - 7, 1, " ")
            gpu.set(6, y, tostring(item):sub(1, width - 11))
        end
        gpu.setBackground(0x0B0B0B)
        common.footer("UP/DOWN + ENTER   BACKSPACE = back   mouse/touch supported")
        local e = {computer.pullSignal()}
        if e[1] == "key_down" then
            local char, code = e[3] or 0, e[4] or 0
            if code == common.KEY_UP then selected = selected - 1; if selected < 1 then selected = #items end
            elseif code == common.KEY_DOWN then selected = selected + 1; if selected > #items then selected = 1 end
            elseif code == common.KEY_ENTER or char == 13 then return selected
            elseif code == common.KEY_BACKSPACE or char == 8 then return nil end
        elseif e[1] == "touch" then
            local x, y = e[3], e[4]
            for i = 1, #items do
                local row = firstRow + (i - 1) * 2
                if y == row and x >= 4 and x <= width - 4 then return i end
            end
        end
    end
end

function common.input(title, prompt, initial)
    local value = tostring(initial or "")
    while true do
        common.header(title, prompt)
        gpu.setBackground(0x303030)
        gpu.setForeground(0xFFFFFF)
        gpu.fill(4, 8, width - 7, 1, " ")
        gpu.set(6, 8, value:sub(math.max(1, #value - width + 12)))
        common.footer("ENTER = confirm   BACKSPACE = erase   ESC-like back: empty + BACKSPACE")
        local e = {computer.pullSignal()}
        if e[1] == "key_down" then
            local char, code = e[3] or 0, e[4] or 0
            if code == common.KEY_ENTER or char == 13 then return value end
            if code == common.KEY_BACKSPACE or char == 8 then
                if #value == 0 then return nil end
                value = value:sub(1, -2)
            elseif char >= 32 and char <= 126 then
                value = value .. string.char(char)
            end
        end
    end
end

YellowOS.common = common
