local computer=rawget(_G,"computer")
local c=YellowOS.common
local items={
 {"Applications","/system/apps/apps.lua"},
 {"YellowStore","/system/apps/appstore.lua"},
 {"Files","/system/apps/files.lua"},
 {"Terminal","/system/apps/terminal.lua"},
 {"Browser","/system/apps/browser.lua"},
 {"Updates","/system/apps/updates.lua"},
 {"Settings","/system/apps/settings.lua"},
 {"About","/system/apps/about.lua"},
 {"Reboot"},{"Shutdown"}
}
while true do
 local names={}; for _,it in ipairs(items) do table.insert(names,it[1]) end
 local sub="Desktop Edition"
 if YellowOS.pendingUpdate then sub=sub.." | Update "..YellowOS.pendingUpdate.version.." available" end
 local s=c.menu("Desktop "..YellowOS.version,sub,names)
 if s then local it=items[s]; if it[2] then YellowOS.loadFile(it[2]) elseif it[1]=="Reboot" then computer.shutdown(true) elseif it[1]=="Shutdown" then computer.shutdown(false) end end
end
