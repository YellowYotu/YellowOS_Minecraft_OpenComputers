local component=rawget(_G,"component")
local http={}
function http.get(url)
 local a=component.list("internet")(); if not a then return nil,"Internet Card not found" end
 local i=component.proxy(a); local r,reason=i.request(url); if not r then return nil,tostring(reason) end
 local d=""; while true do local c,e=r.read(4096); if c then d=d..c elseif e then r.close(); return nil,tostring(e) else break end end; r.close(); return d
end
YellowOS.http=http
