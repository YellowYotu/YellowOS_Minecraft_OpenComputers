local c=YellowOS.common
local component=rawget(_G,"component")
local computer=rawget(_G,"computer")
local gpu=component.proxy(component.list("gpu")())
local w,h=gpu.getResolution()
local free=YellowOS.fs.spaceTotal()-YellowOS.fs.spaceUsed()
c.message("About","YellowOS Desktop Edition\nVersion "..YellowOS.version.."\nResolution "..w.."x"..h.."\nRAM "..c.formatBytes(computer.totalMemory()).."\nFree storage "..c.formatBytes(free))
