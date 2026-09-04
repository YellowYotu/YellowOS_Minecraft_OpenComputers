local component=rawget(_G,"component")
local computer=rawget(_G,"computer")
if not component or not computer then error("Missing OpenComputers boot globals") end
local boot=computer.getBootAddress(); if not boot then error("Boot drive not found") end
local fs=component.proxy(boot)
local function read(path) local h,r=fs.open(path,"r"); if not h then return nil,r end; local d=""; while true do local c=fs.read(h,2048); if not c then break end; d=d..c end; fs.close(h); return d end
local function loadFile(path) local d,r=read(path); if not d then error("Cannot open "..path..": "..tostring(r)) end; local p,e=load(d,"="..path,"t",_ENV); if not p then error(e) end; return p() end
_G.YellowOS={fs=fs,bootAddress=boot,readAll=read,loadFile=loadFile,version="0.1.1",edition="Development Edition",device="Development PC"}
loadFile("/system/boot.lua")
