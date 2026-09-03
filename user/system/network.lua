local component = component
local computer = computer
local network = {}

network.modem = nil
network.port = 24120
network.pendingUpdate = nil

local modemAddress = component.list("modem")()

if modemAddress then
    network.modem = component.proxy(modemAddress)
    network.modem.open(network.port)
end

function network.processSignal(signal, receiver, sender, port, distance, kind, version, size, targetDevice)
    if signal ~= "modem_message" or port ~= network.port then
        return false
    end

    if kind == "YELLOWOS_UPDATE" then
        targetDevice = tostring(targetDevice or "ALL")

        if targetDevice ~= "ALL" and targetDevice ~= YellowOS.device then
            return false
        end

        network.pendingUpdate = {
            version = tostring(version or "unknown"),
            size = tonumber(size) or 0,
            sender = sender,
            targetDevice = targetDevice
        }
        return true
    end

    return false
end

function network.broadcastPresence()
    if network.modem then
        network.modem.broadcast(network.port, "YELLOWOS_CLIENT", YellowOS.version, YellowOS.device, computer.address())
    end
end

YellowOS.network = network
