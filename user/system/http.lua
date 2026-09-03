local component = component
local http = {}

function http.available()
    return component.list("internet")() ~= nil
end

function http.get(url)
    local address = component.list("internet")()

    if not address then
        return nil, "Internet Card not found"
    end

    local internet = component.proxy(address)
    local request, reason = internet.request(url)

    if not request then
        return nil, tostring(reason)
    end

    local data = ""

    while true do
        local chunk, readReason = request.read(4096)

        if chunk then
            data = data .. chunk
        elseif readReason then
            request.close()
            return nil, tostring(readReason)
        else
            break
        end
    end

    request.close()
    return data
end

YellowOS.http = http
