local common = YellowOS.common
local http = YellowOS.http
local gpu = common.gpu
local computer = computer

local function htmlToText(html)
    html = html:gsub("<script.-</script>", "")
    html = html:gsub("<style.-</style>", "")
    html = html:gsub("<[bB][rR]%s*/?>", "\n")
    html = html:gsub("</[pP]>", "\n\n")
    html = html:gsub("</[dD][iI][vV]>", "\n")
    html = html:gsub("</[lL][iI]>", "\n")
    html = html:gsub("<[^>]->", "")
    html = html:gsub("&nbsp;", " ")
    html = html:gsub("&amp;", "&")
    html = html:gsub("&lt;", "<")
    html = html:gsub("&gt;", ">")
    html = html:gsub("&quot;", "\"")
    html = html:gsub("&#39;", "'")
    html = html:gsub("\r", "")
    html = html:gsub("\n%s+", "\n")
    html = html:gsub("[ \t]+", " ")
    return html
end

local function readUrl(url)
    common.header("Browser")
    gpu.setForeground(0xFFFFFF)
    gpu.set(3, 5, "Loading...")
    gpu.set(3, 6, url:sub(1, common.width - 4))

    local data, reason = http.get(url)

    if not data then
        common.message("Browser", "Request failed:\n" .. tostring(reason))
        return
    end

    local text = htmlToText(data)
    local lines = {}

    for line in (text .. "\n"):gmatch("(.-)\n") do
        if line ~= "" then
            while #line > common.width - 4 do
                table.insert(lines, line:sub(1, common.width - 4))
                line = line:sub(common.width - 3)
            end

            table.insert(lines, line)
        end
    end

    local page = 1
    local pageSize = common.height - 7
    local pageCount = math.max(1, math.ceil(#lines / pageSize))

    while true do
        common.header("Browser " .. page .. "/" .. pageCount)
        gpu.setForeground(0x808080)
        gpu.set(2, 4, url:sub(1, common.width - 3))
        gpu.setForeground(0xFFFFFF)

        for i = 1, pageSize do
            local line = lines[(page - 1) * pageSize + i]

            if line then
                gpu.set(2, i + 4, line)
            end
        end

        gpu.setForeground(0x808080)
        gpu.set(2, common.height - 1, "[BACK]   LEFT/RIGHT or UP/DOWN pages")
        local event = {computer.pullSignal()}
        local signal = event[1]

        if signal == "key_down" then
            local char = event[3] or 0
            local code = event[4] or 0

            if common.isBack(char, code) then
                return
            elseif code == common.KEY_LEFT or code == common.KEY_UP then
                page = math.max(1, page - 1)
            elseif code == common.KEY_RIGHT or code == common.KEY_DOWN then
                page = math.min(pageCount, page + 1)
            end
        elseif signal == "touch" then
            local x = event[3]
            local y = event[4]

            if y == common.height - 1 and x <= 8 then
                return
            elseif x < common.width / 2 then
                page = math.max(1, page - 1)
            else
                page = math.min(pageCount, page + 1)
            end
        else
            common.dispatchSystemEvent(event)
        end
    end
end

while true do
    local selected = common.menu("Browser", "Real HTTP text browser", {"YellowOS GitHub", "Example.com", "About browser", "Back"})

    if not selected or selected == 4 then
        return
    elseif selected == 1 then
        readUrl("https://github.com/YellowYotu/YellowOS_Minecraft_OpenComputers")
    elseif selected == 2 then
        readUrl("https://example.com")
    elseif selected == 3 then
        common.message("Browser", "Loads real HTTP/HTTPS pages through the Internet Card. HTML is converted to text. JavaScript, CSS, images, video and forms are not supported.")
    end
end
