local component = rawget(_G, "component")

if not component then
    component = require("component")
end

local common = YellowOS.common
local drives = {}

for address in component.list("filesystem") do
    local fs = component.proxy(address)
    local label = fs.getLabel() or address:sub(1, 8)
    table.insert(drives, label .. "  " .. common.formatBytes(fs.spaceUsed()) .. "/" .. common.formatBytes(fs.spaceTotal()))
end

if #drives == 0 then
    common.message("Files", "No storage devices found")
    return
end

common.menu("Files", "Connected storage", drives)
