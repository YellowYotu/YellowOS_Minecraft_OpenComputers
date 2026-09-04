local component=rawget(_G,"component")
local computer=rawget(_G,"computer")
if not component or not computer then error("OpenComputers globals missing") end

local gpuAddr=component.list("gpu")()
local screenAddr=component.list("screen")()
if not gpuAddr or not screenAddr then error("GPU/screen missing") end
local gpu=component.proxy(gpuAddr)
gpu.bind(screenAddr)
local mw,mh=gpu.maxResolution()
gpu.setResolution(mw,mh)
local w,h=gpu.getResolution()

local KEY_END=207
local colorDepth=gpu.getDepth and gpu.getDepth() or 1
local hasColor=colorDepth>1

local colors={
  black=0x000000, white=0xFFFFFF, red=0xFF3030, green=0x33FF66,
  yellow=0xFFFF33, blue=0x3366FF, magenta=0xFF33CC, cyan=0x33FFFF
}

local errors={
  "KERNEL PANIC: brain.dll stopped responding",
  "CRITICAL: RAM MELTED AT 982 C",
  "ERROR 0xDEADBEEF: skill issue detected",
  "SYSTEM32 DELETED SUCCESSFULLY",
  "FATAL: toaster driver not found",
  "WARNING: FBI uplink established",
  "GPU OVERHEAT: 1204 C - perfectly normal",
  "DISK FAILURE: vibes partition corrupted",
  "SECURITY ALERT: suspicious amount of gaming",
  "NETWORK ERROR: internet escaped",
  "CPU EXCEPTION: too many thoughts per second",
  "BOOT DEVICE HAS DEVELOPED FEELINGS",
  "MEMORY LEAK: thoughts are leaving the computer",
  "CRITICAL PROCESS DIED: probably on purpose",
  "ERROR: keyboard detected user",
  "WARNING: computer is judging you"
}

local troll={
  "        #######        ",
  "     ###       ###     ",
  "   ##  #########  ##   ",
  "  ## ##         ## ##  ",
  " ## ##  ##   ##  ## ## ",
  " ## ##           ## ## ",
  " ##  ###       ###  ## ",
  "  ##    #######    ##  ",
  "   ###           ###   ",
  "      ###########      ",
  "         U MAD?        "
}

local function fg(c) gpu.setForeground(hasColor and c or colors.white) end
local function bg(c) gpu.setBackground(hasColor and c or colors.black) end
local function clear(back)
  bg(back or colors.black); fg(colors.white); gpu.fill(1,1,w,h," ")
end

local function centered(y,text)
  local x=math.max(1,math.floor((w-#text)/2)+1)
  gpu.set(x,y,text:sub(1,w))
end

local function wait(seconds)
  local deadline=computer.uptime()+seconds
  while computer.uptime()<deadline do
    local e={computer.pullSignal(math.min(0.1,deadline-computer.uptime()))}
    if e[1]=="key_down" and (e[4] or 0)==KEY_END then
      clear(); fg(colors.white); centered(math.floor(h/2),"TrollOS emergency exit")
      computer.pullSignal(0.4)
      computer.shutdown(false)
    end
  end
end

local function fakeBoot()
  clear()
  fg(colors.white)
  centered(math.max(2,math.floor(h/2)-4),"TrollOS 1.0.0")
  fg(colors.green)
  centered(math.max(3,math.floor(h/2)-2),"Loading absolutely legitimate operating system...")
  local barW=math.max(10,math.min(w-8,40))
  local x=math.floor((w-barW)/2)+1
  local y=math.floor(h/2)+1
  bg(colors.white); gpu.fill(x,y,barW,1," ")
  for i=1,barW do
    bg(hasColor and colors.green or colors.white)
    gpu.fill(x,y,i,1," ")
    wait(0.03)
  end
  bg(colors.black); fg(colors.white)
  centered(y+3,"Everything is fine.")
  wait(1.0)
  fg(colors.red); centered(y+5,"...nope.")
  wait(0.8)
end

local function fakeError()
  local back=colors.black
  if hasColor and math.random(1,4)==1 then
    local choices={colors.red,colors.blue,colors.magenta,colors.cyan}
    back=choices[math.random(#choices)]
  end
  clear(back)
  fg(hasColor and colors.white or colors.white)
  centered(2,"*** TROLLOS SYSTEM FAILURE ***")
  fg(hasColor and colors.yellow or colors.white)
  centered(4,errors[math.random(#errors)])
  fg(colors.white)
  local code=string.format("0x%08X",math.random(0,0x7FFFFFFF))
  centered(6,"Diagnostic code: "..code)
  centered(8,"Collecting completely fake crash data...")
  local p=math.random(1,99)
  centered(10,tostring(p).."% complete")
  centered(h-1,"Press END for emergency shutdown")
end

local function trollface()
  clear()
  fg(hasColor and colors.green or colors.white)
  local start=math.max(1,math.floor((h-#troll)/2))
  for i,line in ipairs(troll) do
    if start+i-1<=h then centered(start+i-1,line) end
  end
end

local function matrixSpam()
  clear()
  fg(hasColor and colors.green or colors.white)
  local chars="01#$%@!?ZXCVBNM"
  for y=1,h do
    local line={}
    for x=1,w do line[#line+1]=chars:sub(math.random(#chars),math.random(#chars)) end
    gpu.set(1,y,table.concat(line):sub(1,w))
  end
end

local function fakeDelete()
  clear()
  fg(hasColor and colors.red or colors.white)
  gpu.set(2,2,"TrollOS Recovery Utility")
  fg(colors.white)
  local files={"/system/kernel.lua","/boot/init.lua","/home/memes.txt","/drivers/gpu.sys","/definitely/not/important"}
  for i,f in ipairs(files) do
    if i+3<=h then gpu.set(2,i+3,("Deleting "..f.." ... OK"):sub(1,w-1)) end
    wait(0.15)
  end
  fg(hasColor and colors.yellow or colors.white)
  if h>10 then gpu.set(2,10,"Just kidding. Nothing was deleted.") end
end

local function shake()
  clear()
  fg(hasColor and colors.magenta or colors.white)
  for i=1,18 do
    local x=math.random(1,math.max(1,w-20))
    local y=math.random(1,h)
    gpu.set(x,y,"ERROR ERROR ERROR")
  end
end

math.randomseed(math.floor(computer.uptime()*1000)+w*31+h)
fakeBoot()

local nextChaos=computer.uptime()
while true do
  if computer.uptime()>=nextChaos then
    local mode=math.random(1,6)
    if mode==1 then fakeError()
    elseif mode==2 then trollface()
    elseif mode==3 then matrixSpam()
    elseif mode==4 then fakeDelete()
    elseif mode==5 then shake()
    else
      clear(); fg(colors.white)
      centered(math.floor(h/2)-1,"TrollOS repaired all problems successfully.")
      wait(1.2)
      fg(hasColor and colors.red or colors.white)
      centered(math.floor(h/2)+1,"LOL NO")
    end
    nextChaos=computer.uptime()+3
  end

  local e={computer.pullSignal(0.1)}
  if e[1]=="key_down" and (e[4] or 0)==KEY_END then
    clear(); fg(colors.white); centered(math.floor(h/2),"TrollOS emergency shutdown")
    computer.pullSignal(0.4)
    computer.shutdown(false)
  elseif e[1]=="touch" and math.random(1,4)==1 then
    fg(hasColor and colors.red or colors.white)
    local x=math.max(1,math.min(w-8,(e[3] or 1)-4))
    local y=math.max(1,math.min(h,e[4] or 1))
    gpu.set(x,y,"DON'T TOUCH")
  end
end
