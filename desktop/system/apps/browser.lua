local computer=rawget(_G,"computer")
local c=YellowOS.common
local http=YellowOS.http
local function clean(html)
 html=html:gsub("<[sS][cC][rR][iI][pP][tT].-</[sS][cC][rR][iI][pP][tT]%s*>","")
 html=html:gsub("<[sS][tT][yY][lL][eE].-</[sS][tT][yY][lL][eE]%s*>","")
 html=html:gsub("<br%s*/?>","\n"):gsub("</p%s*>","\n"):gsub("</div%s*>","\n")
 html=html:gsub("<[^>]+>",""):gsub("&nbsp;"," "):gsub("&amp;","&"):gsub("&lt;","<"):gsub("&gt;",">")
 return html
end
local url=c.input("Browser","Enter URL",YellowOS.settings.browserHome); if not url or url=="" then return end
if not url:match("^https?://") then url="https://"..url end
c.header("Browser","Loading "..url); local data,r=http.get(url); if not data then c.message("Browser",tostring(r)); return end
local text=clean(data); c.header("Browser",url); local y=7; for line in (text.."\n"):gmatch("(.-)\n") do line=line:gsub("^%s+",""):gsub("%s+$",""); if line~="" then c.gpu.set(3,y,line:sub(1,c.width-5)); y=y+1; if y>=c.height-3 then break end end end; c.footer("BACKSPACE or click to return"); while true do local e={computer.pullSignal()}; if e[1]=="touch" then return elseif e[1]=="key_down" and ((e[4] or 0)==c.KEY_BACKSPACE or (e[3] or 0)==8) then return end end
