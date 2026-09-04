local c=YellowOS.common
local s=YellowOS.settings
while true do
 local choice=c.menu("Settings","YellowOS Desktop",{"Automatic updates: "..(s.autoUpdates and "ON" or "OFF"),"Browser home: "..s.browserHome,"Back"})
 if not choice or choice==3 then s.save(); return elseif choice==1 then s.autoUpdates=not s.autoUpdates; s.save() elseif choice==2 then local v=c.input("Settings","Browser home URL",s.browserHome); if v and v~="" then s.browserHome=v; s.save() end end
end
