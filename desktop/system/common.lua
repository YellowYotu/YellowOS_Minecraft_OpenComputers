local component = rawget(_G,"component")
local computer = rawget(_G,"computer")
if not component or not computer then error("Missing OpenComputers globals") end
local ga,sa=component.list("gpu")(),component.list("screen")()
if not ga or not sa then error("GPU and screen are required") end
local gpu=component.proxy(ga); gpu.bind(sa)
local mw,mh=gpu.maxResolution(); gpu.setResolution(mw,mh)
local w,h=gpu.getResolution()
local c={gpu=gpu,width=w,height=h,KEY_UP=200,KEY_DOWN=208,KEY_ENTER=28,KEY_BACKSPACE=14}
function c.clear(bg) gpu.setBackground(bg or 0x0B0B0B); gpu.setForeground(0xFFFFFF); gpu.fill(1,1,w,h," ") end
function c.header(title,sub)
 c.clear(); gpu.setBackground(0x242424); gpu.fill(1,1,w,3," "); gpu.setForeground(0xFFD23F); gpu.set(2,2,"YellowOS"); gpu.setForeground(0xFFFFFF); gpu.set(12,2,tostring(title or "Desktop")); gpu.setBackground(0x0B0B0B)
 if sub and sub~="" then gpu.setForeground(0x6EA8FF); gpu.set(3,5,tostring(sub):sub(1,w-4)) end
end
function c.footer(text) gpu.setBackground(0x161616); gpu.fill(1,h-1,w,2," "); gpu.setForeground(0x888888); gpu.set(3,h,tostring(text or ""):sub(1,w-4)); gpu.setBackground(0x0B0B0B) end
function c.formatBytes(n) n=tonumber(n) or 0; if n>=1048576 then return string.format("%.2f MB",n/1048576) elseif n>=1024 then return string.format("%.1f KB",n/1024) end; return tostring(n).." B" end
function c.message(title,text)
 c.header(title); gpu.setBackground(0x2D2D2D); gpu.fill(4,6,w-7,math.max(6,math.min(h-10,12))," "); gpu.setForeground(0xFFFFFF); local y=8
 for line in (tostring(text).."\n"):gmatch("(.-)\n") do gpu.set(6,y,line:sub(1,w-12)); y=y+1; if y>=h-5 then break end end
 gpu.setBackground(0xFFD23F); gpu.setForeground(0x000000); gpu.set(math.max(4,math.floor(w/2)-4),h-4,"  BACK  "); gpu.setBackground(0x0B0B0B)
 while true do local e={computer.pullSignal()}; if e[1]=="touch" then return end; if e[1]=="key_down" and ((e[4] or 0)==c.KEY_BACKSPACE or (e[4] or 0)==c.KEY_ENTER or (e[3] or 0)==8) then return end end
end
function c.menu(title,sub,items,selected)
 selected=selected or 1; local first=7
 while true do
  c.header(title,sub)
  for i,item in ipairs(items) do local y=first+(i-1)*2; if y>=h-2 then break end; if i==selected then gpu.setBackground(0xFFD23F); gpu.setForeground(0x000000) else gpu.setBackground(0x303030); gpu.setForeground(0xFFFFFF) end; gpu.fill(4,y,w-7,1," "); gpu.set(6,y,tostring(item):sub(1,w-11)) end
  gpu.setBackground(0x0B0B0B); c.footer("UP/DOWN + ENTER   BACKSPACE = back   mouse/touch supported")
  local e={computer.pullSignal()}
  if e[1]=="key_down" then local ch,code=e[3] or 0,e[4] or 0; if code==c.KEY_UP then selected=selected-1; if selected<1 then selected=#items end elseif code==c.KEY_DOWN then selected=selected+1; if selected>#items then selected=1 end elseif code==c.KEY_ENTER or ch==13 then return selected elseif code==c.KEY_BACKSPACE or ch==8 then return nil end
  elseif e[1]=="touch" then local x,y=e[3],e[4]; for i=1,#items do local row=first+(i-1)*2; if y==row and x>=4 and x<=w-4 then return i end end end
 end
end
function c.input(title,prompt,initial)
 local v=tostring(initial or "")
 while true do c.header(title,prompt); gpu.setBackground(0x303030); gpu.setForeground(0xFFFFFF); gpu.fill(4,8,w-7,1," "); gpu.set(6,8,v:sub(math.max(1,#v-w+12))); c.footer("ENTER confirm   BACKSPACE erase   empty+BACKSPACE cancel"); local e={computer.pullSignal()}; if e[1]=="key_down" then local ch,code=e[3] or 0,e[4] or 0; if code==c.KEY_ENTER or ch==13 then return v elseif code==c.KEY_BACKSPACE or ch==8 then if #v==0 then return nil end; v=v:sub(1,-2) elseif ch>=32 and ch<=126 then v=v..string.char(ch) end end end
end
YellowOS.common=c
