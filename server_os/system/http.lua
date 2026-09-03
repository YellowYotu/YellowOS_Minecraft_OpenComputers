local component = rawget(_G, "component")

if not component then
    component = require("component")
end

local http = {}
local internetAddress = component.list("internet")()

function http.available()
    return internetAddress ~= nil
end

function http.get(url)
    if not internetAddress then
        return nil, "Internet Card not found"
    end

    local internet = component.proxy(internetAddress)
    local request, reason = internet.request(url)

    if not request then
        return nil, reason
    end

    local data = ""

    while true do
        local chunk, readReason = request.read(4096)

        if chunk then
            data = data .. chunk
        elseif readReason then
            request.close()
            return nil, readReason
        else
            break
        end
    end

    request.close()
    return data
end

YellowOS.http = http
