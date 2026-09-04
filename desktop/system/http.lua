local component=rawget(_G,"component")
local http={}
function http.get(url)
 local a=component.list("internet")(); if not a then return nil,"Internet Card not found" end
 local internet=component.proxy(a); local req,reason=internet.request(url); if not req then return nil,reason end
 local data=""
 while true do local ch,r=req.read(2048); if ch then data=data..ch elseif r then req.close(); return nil,r else break end end
 req.close(); return data
end
YellowOS.http=http
