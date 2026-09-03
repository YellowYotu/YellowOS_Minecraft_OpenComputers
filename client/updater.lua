local component = component
local computer = computer

local REPOSITORY = "YellowYotu/YellowOS_Minecraft_OpenComputers"
local BRANCH = "main"
local BASE_URL = "https://raw.githubusercontent.com/" .. REPOSITORY .. "/" .. BRANCH .. "/"
local MANIFEST_PATH = "releases/user/manifest.txt"

local internetAddress = component.list("internet")()

if not internetAddress then
    error("Internet Card not found")
end

local internet = component.proxy(internetAddress)
local bootAddress = computer.getBootAddress()

if not bootAddress then
    error("Boot filesystem not found")
end

local filesystem = component.proxy(bootAddress)

local function httpGet(url)
    local request, reason = internet.request(url)

    if not request then
        return nil, reason or "request failed"
    end

    local startTime = computer.uptime()

    while true do
        local connected, connectReason = request.finishConnect()

        if connected then
            break
        end

        if connected == nil then
            request.close()
            return nil, connectReason or "connection failed"
        end

        if computer.uptime() - startTime > 15 then
            request.close()
            return nil, "connection timeout"
        end

        computer.pullSignal(0.05)
    end

    local data = ""

    while true do
        local chunk, readReason = request.read(math.huge)

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

local function ensureDirectory(path)
    local directory = path:match("^(.*)/[^/]+$")

    if not directory or directory == "" or directory == "/" then
        return true
    end

    local current = ""

    for part in directory:gmatch("[^/]+") do
        current = current .. "/" .. part

        if not filesystem.exists(current) then
            local ok, reason = filesystem.makeDirectory(current)

            if not ok then
                return false, reason
            end
        end
    end

    return true
end

local function writeFile(path, data)
    local ok, reason = ensureDirectory(path)

    if not ok then
        return false, reason
    end

    if filesystem.exists(path) then
        filesystem.remove(path)
    end

    local handle, openReason = filesystem.open(path, "w")

    if not handle then
        return false, openReason
    end

    filesystem.write(handle, data)
    filesystem.close(handle)
    return true
end

local manifest, manifestReason = httpGet(BASE_URL .. MANIFEST_PATH)

if not manifest then
    error("Cannot download update manifest: " .. tostring(manifestReason))
end

local version = manifest:match("version=([^\r\n]+)") or "unknown"
local files = {}

for targetPath, sourcePath in manifest:gmatch("file=([^|\r\n]+)|([^\r\n]+)") do
    table.insert(files, {
        target = targetPath,
        source = sourcePath
    })
end

print("YellowOS User Edition updater")
print("Update version: " .. version)
print("Files: " .. tostring(#files))
print("")

for index, file in ipairs(files) do
    print("[" .. index .. "/" .. #files .. "] " .. file.target)

    local data, reason = httpGet(BASE_URL .. file.source)

    if not data then
        error("Download failed: " .. file.source .. ": " .. tostring(reason))
    end

    local ok, writeReason = writeFile(file.target, data)

    if not ok then
        error("Write failed: " .. file.target .. ": " .. tostring(writeReason))
    end
end

print("")
print("Update installed successfully.")
print("Version: " .. version)
