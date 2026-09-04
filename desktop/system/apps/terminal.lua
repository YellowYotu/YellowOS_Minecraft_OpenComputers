local computer=rawget(_G,"computer")
local fs=YellowOS.fs
local c=YellowOS.common
local function split(s) local t={}; for p in tostring(s):gmatch("%S+") do t[#t+1]=p end; return t end
local cwd="/"
while true do
 local line=c.input("Terminal",cwd.." >",""); if line==nil then return end
 local a=split(line); local cmd=a[1] or ""
 if cmd=="" then
 elseif cmd=="exit" then return
 elseif cmd=="clear" then
 elseif cmd=="help" then c.message("Terminal","help, ls, cd, cat, mkdir, rm, write, update, version, reboot, shutdown, exit")
 elseif cmd=="version" then c.message("Terminal","YellowOS Desktop "..YellowOS.version)
 elseif cmd=="ls" then local p=a[2] or cwd; local out=""; if fs.exists(p) and fs.isDirectory(p) then for n in fs.list(p) do out=out..n.."\n" end else out="Not a directory" end; c.message("ls",out)
 elseif cmd=="cd" then local p=a[2] or "/"; if p==".." then cwd=cwd:match("^(.*)/[^/]+/?$") or "/"; if cwd=="" then cwd="/" end elseif fs.exists(p) and fs.isDirectory(p) then cwd=p end
 elseif cmd=="cat" then local p=a[2]; if not p then c.message("cat","Usage: cat <path>") else local h=fs.open(p,"r"); if not h then c.message("cat","Cannot open") else local d=""; while true do local ch=fs.read(h,2048); if not ch then break end; d=d..ch; if #d>12000 then break end end; fs.close(h); c.message("cat",d) end end
 elseif cmd=="mkdir" then local p=a[2]; if p then local ok,r=fs.makeDirectory(p); c.message("mkdir",ok and "Done" or tostring(r)) end
 elseif cmd=="rm" then local p=a[2]; if p then local ok,r=fs.remove(p); c.message("rm",ok and "Done" or tostring(r)) end
 elseif cmd=="write" then local p=a[2]; if not p then c.message("write","Usage: write <path> <text>") else local text=line:match("^%S+%s+%S+%s+(.+)$") or ""; local h,r=fs.open(p,"w"); if not h then c.message("write",tostring(r)) else fs.write(h,text); fs.close(h); c.message("write","Saved") end end
 elseif cmd=="update" then local m,r=YellowOS.updater.check(); if not m then c.message("Update",tostring(r)) elseif not m.updateAvailable then c.message("Update","Already up to date") else local ok,er=YellowOS.updater.install(m); if ok then computer.shutdown(true) else c.message("Update failed",tostring(er)) end end
 elseif cmd=="reboot" then computer.shutdown(true)
 elseif cmd=="shutdown" then computer.shutdown(false)
 else c.message("Terminal","Unknown command: "..cmd) end
end
