local common = YellowOS.common
local internet = component.list("internet")() and "Available" or "Missing"
local modem = component.list("modem")() and "Available" or "Missing"

common.message("About", "YellowOS " .. YellowOS.edition .. "\nVersion: " .. YellowOS.version .. "\nDevice: " .. YellowOS.device .. "\nInternet: " .. internet .. "\nWireless: " .. modem .. "\n\nYellowYotu/YellowOS_Minecraft_OpenComputers")
