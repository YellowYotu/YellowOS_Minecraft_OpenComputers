local c=YellowOS.common
local computer=rawget(_G,"computer")
local items={{"Terminal","/system/apps/terminal.lua"},{"Developer Wiki","/system/apps/wiki.lua"},{"Submit App","/system/apps/submit.lua"},{"About"},{"Reboot"},{"Shutdown"}}
while true do
 local names={}; for _,it in ipairs(items) do table.insert(names,it[1]) end
 local s=c.menu("Development Edition "..YellowOS.version,"Build, test and publish YellowOS apps",names)
 if s then local it=items[s]; if it[2] then YellowOS.loadFile(it[2]) elseif it[1]=="About" then c.message("About","YellowOS Development Edition\nVersion "..YellowOS.version.."\nIncludes terminal, SDK wiki and YellowStore submission tools.") elseif it[1]=="Reboot" then computer.shutdown(true) elseif it[1]=="Shutdown" then computer.shutdown(false) end end
end
