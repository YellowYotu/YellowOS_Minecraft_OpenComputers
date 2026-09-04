local common = YellowOS.common
local fs = YellowOS.fs

local function ensure(path)
    if not fs.exists(path) then fs.makeDirectory(path) end
end

local value = common.input("GitHub Setup", "Paste GitHub token with Ctrl+V, ENTER saves.", "", true)
if value == nil then return end

if #value < 10 then
    common.message("GitHub Setup", "Token is too short.")
    return
end

ensure("/system/secrets")
local h, reason = fs.open("/system/secrets/github_token.cfg", "w")
if not h then
    common.message("GitHub Setup", tostring(reason))
    return
end

fs.write(h, value)
fs.close(h)
common.message("GitHub Setup", "GitHub publishing token saved locally.")
