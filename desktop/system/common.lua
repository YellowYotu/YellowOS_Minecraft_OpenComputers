local component = require("component")
local computer = require("computer")

local gpuAddress = component.list("gpu")()
local screenAddress = component.list("screen")()
if not gpuAddress or not screenAddress then
    error("GPU and screen are required")
end

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
    KEY_ENTER = 28,
    KEY_BACKSPACE = 14
}

function common.clear()
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, width, height, " ")
end

function common.header(title)
    common.clear()
    gpu.setBackground(0x303030)
    gpu.fill(1, 1, width, 3, " ")
    gpu.setForeground(0xFFD23F)
    gpu.set(2, 2, "YellowOS")
    gpu.setForeground(0xFFFFFF)
    gpu.set(12, 2, title)
    gpu.setBackground(0x000000)
end

function common.menu(title, subtitle, items)
    local selected = 1
    local firstRow = 7

    while true do
        common.header(title)
        gpu.setForeground(0x6EA8FF)
        gpu.set(3, 5, tostring(subtitle or ""))

        for i, item in ipairs(items) do
            local y = firstRow + (i - 1) * 2
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

        gpu.setBackground(0x000000)
        gpu.setForeground(0x808080)
        gpu.set(3, height - 2, "UP/DOWN + ENTER   or tap")

        local event = {computer.pullSignal()}
        if event[1] == "key_down" then
            local char = event[3] or 0
            local code = event[4] or 0
            if code == common.KEY_UP then
                selected = selected - 1
                if selected < 1 then selected = #items end
            elseif code == common.KEY_DOWN then
                selected = selected + 1
                if selected > #items then selected = 1 end
            elseif code == common.KEY_ENTER or char == 13 then
                return selected
            elseif code == common.KEY_BACKSPACE or char == 8 then
                return nil
            end
        elseif event[1] == "touch" then
            local x, y = event[3], event[4]
            for i = 1, #items do
                local row = firstRow + (i - 1) * 2
                if y == row and x >= 4 and x <= width - 4 then
                    return i
                end
            end
        end
    end
end

YellowOS.common = common
