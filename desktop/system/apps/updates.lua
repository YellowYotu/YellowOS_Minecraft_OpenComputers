local computer=rawget(_G,"computer")
local c=YellowOS.common
local u=YellowOS.updater
local m,r=u.check(); if not m then c.message("Updates","Check failed:\n"..tostring(r)); return end
if not m.updateAvailable then c.message("Updates","YellowOS Desktop is up to date.\nVersion: "..YellowOS.version); return end
local free=YellowOS.fs.spaceTotal()-YellowOS.fs.spaceUsed()
local s=c.menu("Updates","Current "..YellowOS.version.." | Latest "..m.version.." | "..c.formatBytes(m.size).." | Free "..c.formatBytes(free),{"Install update","Later"})
if s~=1 then YellowOS.pendingUpdate=m; return end
local ok,er=u.install(m); if not ok then c.message("Update failed",tostring(er)); return end
computer.shutdown(true)
