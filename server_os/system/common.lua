local component = rawget(_G, "component")
local computer = rawget(_G, "computer")
if not component then component = require("component") end
if not computer then computer = require("computer") end

local gpuAddress = component.list("gpu")()
local screenAddress = component.list("screen")()
if not gpuAddress or not screenAddress then error("GPU or screen not found") end
local gpu = component.proxy(gpuAddress)
gpu.bind(screenAddress)
local maxWidth, maxHeight = gpu.maxResolution()
gpu.setResolution(maxWidth, maxHeight)
local width, height = gpu.getResolution()
local common = {gpu=gpu,width=width,height=height,KEY_ENTER=28,KEY_BACKSPACE=14,KEY_UP=200,KEY_DOWN=208,KEY_END=207}

local function dispatch(event)
    if YellowOS.appserver then YellowOS.appserver.processSignal(table.unpack(event)) end
    if YellowOS.handleSignal then YellowOS.handleSignal(table.unpack(event)) end
end

function common.isExit(char, code)
    return code == common.KEY_END
end

function common.clear()
    gpu.setBackground(0x000000); gpu.setForeground(0xFFFFFF); gpu.fill(1,1,width,height," ")
end

function common.header(title)
    common.clear(); gpu.setBackground(0x202020); gpu.fill(1,1,width,3," ")
    gpu.setForeground(0xFFFF00); gpu.set(2,2,"YellowOS"); gpu.setForeground(0xFFFFFF); gpu.set(12,2,title); gpu.setBackground(0x000000)
end

function common.message(title,text)
    common.header(title); gpu.setForeground(0xFFFFFF); local y=5
    for line in tostring(text):gmatch("[^\n]+") do gpu.set(3,y,line:sub(1,width-4)); y=y+1; if y>=height-2 then break end end
    gpu.setForeground(0x808080); gpu.set(3,height-1,"Tap anywhere or END")
    while true do
        local event={computer.pullSignal()}; local signal=event[1]; local code=event[4] or 0
        if signal=="touch" or (signal=="key_down" and (code==common.KEY_END or code==common.KEY_BACKSPACE)) then return end
        dispatch(event)
    end
end

function common.menu(title,subtitle,items,selected)
    selected=selected or 1
    while true do
        common.header(title)
        if subtitle then gpu.setForeground(0x808080); gpu.set(3,4,subtitle:sub(1,width-4)) end
        local firstRow=6
        for i,item in ipairs(items) do
            local y=firstRow+i-1
            if i==selected then gpu.setBackground(0xFFFFFF); gpu.setForeground(0x000000) else gpu.setBackground(0x000000); gpu.setForeground(0xFFFFFF) end
            gpu.fill(3,y,width-5,1," "); gpu.set(5,y,tostring(item):sub(1,width-7))
        end
        gpu.setBackground(0x000000); gpu.setForeground(0x808080); gpu.set(3,height-1,"UP/DOWN + ENTER   END = back")
        local event={computer.pullSignal()}; local signal=event[1]
        if signal=="key_down" then
            local code=event[4] or 0
            if code==common.KEY_UP then selected=selected-1; if selected<1 then selected=#items end
            elseif code==common.KEY_DOWN then selected=selected+1; if selected>#items then selected=1 end
            elseif code==common.KEY_ENTER then return selected
            elseif code==common.KEY_END or code==common.KEY_BACKSPACE then return nil end
        elseif signal=="touch" then
            local y=event[4]; local index=y-firstRow+1; if index>=1 and index<=#items then return index end
        else dispatch(event) end
    end
end

function common.input(title,prompt,initial,masked)
    local value=tostring(initial or "")
    while true do
        common.header(title)
        gpu.setForeground(0x808080); gpu.set(3,5,tostring(prompt or ""):sub(1,width-4))
        gpu.setBackground(0x202020); gpu.fill(3,8,width-5,1," "); gpu.setForeground(0xFFFFFF)
        local shown = masked and string.rep("*",#value) or value
        gpu.set(5,8,shown:sub(math.max(1,#shown-width+8)))
        gpu.setBackground(0x000000); gpu.setForeground(0x808080); gpu.set(3,height-1,"ENTER save   Ctrl+V paste   END cancel")
        local e={computer.pullSignal()}
        if e[1]=="clipboard" then
            value=value..tostring(e[3] or ""):gsub("[\r\n]","")
        elseif e[1]=="key_down" then
            local char,code=e[3] or 0,e[4] or 0
            if code==common.KEY_ENTER or char==13 then return value
            elseif code==common.KEY_END then return nil
            elseif code==common.KEY_BACKSPACE or char==8 then value=value:sub(1,-2)
            elseif char>=32 and char<=126 then value=value..string.char(char) end
        else dispatch(e) end
    end
end

function common.formatBytes(bytes)
    if bytes>=1048576 then return string.format("%.2f MB",bytes/1048576) elseif bytes>=1024 then return string.format("%.1f KB",bytes/1024) end
    return tostring(bytes).." B"
end

YellowOS.common=common
