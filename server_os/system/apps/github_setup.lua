local common = YellowOS.common
local computer = rawget(_G, "computer")
local fs = YellowOS.fs

local function ensure(path)
    if not fs.exists(path) then fs.makeDirectory(path) end
end

common.header("GitHub Setup")
common.gpu.setForeground(0xFFFFFF)
common.gpu.set(3, 6, "Enter a GitHub token for YellowStore publishing.")
common.gpu.set(3, 8, "The token is stored only on this server disk.")
common.gpu.setForeground(0x808080)
common.gpu.set(3, 10, "ENTER Save   BACKSPACE Erase/Cancel")

local value = ""
while true do
    common.gpu.setBackground(0x202020)
    common.gpu.fill(3, 12, common.width - 5, 1, " ")
    common.gpu.setForeground(0xFFFFFF)
    local masked = string.rep("*", math.min(#value, common.width - 8))
    common.gpu.set(5, 12, masked)
    common.gpu.setBackground(0x000000)

    local e = {computer.pullSignal()}
    if e[1] == "key_down" then
        local char, code = e[3] or 0, e[4] or 0
        if code == common.KEY_ENTER or char == 13 then
            if #value < 10 then
                common.message("GitHub Setup", "Token is too short.")
                return
            end
            ensure("/system/secrets")
            local h, reason = fs.open("/system/secrets/github_token.cfg", "w")
            if not h then common.message("GitHub Setup", tostring(reason)); return end
            fs.write(h, value)
            fs.close(h)
            common.message("GitHub Setup", "GitHub publishing token saved locally.")
            return
        elseif code == common.KEY_BACKSPACE or char == 8 then
            if #value == 0 then return end
            value = value:sub(1, -2)
        elseif char >= 32 and char <= 126 then
            value = value .. string.char(char)
        end
    elseif YellowOS.appserver then
        YellowOS.appserver.processSignal(table.unpack(e))
    end
end
