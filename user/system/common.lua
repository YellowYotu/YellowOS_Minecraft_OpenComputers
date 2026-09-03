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

function common.waitForKey()
    while true do
        local signal, _, char, code = computer.pullSignal()

        if signal == "key_down" then
            return char or 0, code or 0
        end
    end
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

YellowOS.common = common
