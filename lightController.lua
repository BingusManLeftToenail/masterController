term.clear()
term.setCursorPos(1,1)

rednet.open("left")

local function saveServerID()
    local file = fs.open("serverID","w")
    file.write(textutils.serialise(serverID))
    file.close()
end

if fs.exists("serverID") then
    local file = fs.open("serverID","r")
    serverID = textutils.unserialise(file.readAll())
    file.close()
else
    serverID = -1
    saveServerID()
end

local function saveOpenStatus()
    local file = fs.open("onStatus","w")
    file.write(textutils.serialise(onStatus))
    file.close()
end

if fs.exists("onStatus") then
    local file = fs.open("onStatus","r")
    onStatus = textutils.unserialise(file.readAll())
    file.close()
else
    onStatus = false
    saveOpenStatus()
end

while serverID == -1 do
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.yellow)
    write("ENTER SERVER ID: ")
    term.setTextColor(colors.white)
    local input = tonumber(read())
    if input and input > 0 then
        serverID = input
        saveServerID()
    else
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        write("INVALID! Must be a number greater than 0!")
        sleep(2)
    end
end

local function receive()
    local id,message = rednet.receive()
    local validID = id == serverID
    local validMessage = message and type(message) == "table" and message.command
    if not validID and validMessage then
        return
    end
    if message.command == "toggleLight" then
        isOn = message.isOn
        term.clear()
        term.setCursorPos(1,1)
        rs.setOutput("right",isOn)
    end
end

while true do
    receive()
    term.setCursorPos(1,1)
end