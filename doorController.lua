term.clear()
term.setCursorPos(1,1)

local mon = peripheral.wrap("top")
if mon then
    mon.setTextScale(2)
    mon.setBackgroundColor(colors.blue)
    mon.clear()
    mon.setCursorPos(1,2)
    mon.setTextColor(colors.white)
    mon.write("CLEARANCE:   3")
    mon.setCursorPos(1,1)
    mon.setTextColor(colors.black)
    mon.setBackgroundColor(colors.yellow)
    mon.write("   LEVEL 01   ")
end

rednet.open("back")
local function saveDoors()
    local file = fs.open("doors","w")
    file.write(textutils.serialise(doors))
    file.close()
end

if fs.exists("doors") then
    local file = fs.open("doors","r")
    doors = textutils.unserialise(file.readAll())
    file.close()
else
    doors = {}
    saveDoors()
end

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
    local file = fs.open("openStatus","w")
    file.write(textutils.serialise(openStatus))
    file.close()
end

if fs.exists("openStatus") then
    local file = fs.open("openStatus","r")
    openStatus = textutils.unserialise(file.readAll())
    file.close()
else
    openStatus = false
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
    if message.command == "toggleDoor" then
        isOpen = message.isOpen
        term.clear()
        term.setCursorPos(1,1)
        rs.setOutput("bottom",isOpen)
    elseif message.command == "shortOpen" then
        rs.setOutput("bottom",true)
        sleep(4)
        rs.setOutput("bottom",false)
    end
end

while true do
    receive()
    term.setCursorPos(1,1)
end
