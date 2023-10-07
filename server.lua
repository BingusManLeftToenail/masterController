term.clear()
term.setCursorPos(1,1)
rednet.open("left")
local function saveDoors()
    local file = fs.open("doorControllers","w")
    file.write(textutils.serialise(doorControllers))
    file.close()
end

if fs.exists("doorControllers") then
    local file = fs.open("doorControllers","r")
    doorControllers = textutils.unserialise(file.readAll())
    file.close()
else
    doorControllers = {}
    write(textutils.serialise(doorControllers).."\n")
    saveDoors()
end

local function saveLightControllers()
    local file = fs.open("lightControllers","w")
    file.write(textutils.serialise(lightControllers))
    file.close()
end

if fs.exists("lightControllers") then
    local file = fs.open("lightControllers","r")
    lightControllers = textutils.unserialise(file.readAll())
    file.close()
else
    lightControllers = {}
    saveLightControllers()
end


local function saveUsers()
    local file = fs.open("users","w")
    file.write(textutils.serialise(users))
    file.close()
end

if fs.exists("users") then
    local file = fs.open("users","r")
    users = textutils.unserialise(file.readAll())
    file.close()
else
    users = {}
    saveUsers()
end

local function receive()
    term.setTextColor(colors.yellow)
    write("Waiting...\n")
    local id,message = rednet.receive()
    local command = message.command
    term.setTextColor(colors.lime)
    write("Message received! ID: "..id.."\n")
    if id and message and type(message) == "table" then
        term.setTextColor(colors.white)
        write("Message was table.\n")
        local commandExists = command and type(command) == "string"
        if not commandExists then
            term.setTextColor(colors.red)
            write("Command invalid! Message: \n"..textutils.serialise(message).."\n")
            return
        end
        if command == "updateDoorControllers" then
            write("Door controller update request!\n")
            local data = message.doorControllers
            if not type(data) == "table" then
                term.setTextColor(colors.red)
                write("doorController list invalid! Message: \n"..textutils.serialise(message).."\n")
                return
            end
            term.setTextColor(colors.orange)
            write("Updated door controller list!\n")
            doorControllers = message.doorControllers
            saveDoors()
        elseif command == "updateUsers" then
            write("User update request!\n")
            local data = message.users
            if not type(data) == "table" then
                term.setTextColor(colors.red)
                write("User list invalid! Message: \n"..textutils.serialise(message).."\n")
                return
            end
            term.setTextColor(colors.orange)
            write("Updated user list!\n")
            users = message.users
            saveUsers()
        elseif command == "sync_request" then
            term.setTextColor(colors.orange)
            write("Sync request.\n")
            rednet.send(id,{users=users,doorControllers=doorControllers,lightControllers=lightControllers})
        elseif command == "toggleDoor" then
            term.setTextColor(colors.orange)
            write("Door toggle request.\n")
            if type(message.doorID) == "number" then
                term.setTextColor(colors.white)
                write("Toggling door "..message.doorID.."\n")
                doorControllers[message.folderName][message.doorID].isOpen = not doorControllers[message.folderName][message.doorID].isOpen
                rednet.send(message.doorID,{command="toggleDoor",isOpen=doorControllers[message.folderName][message.doorID].isOpen})
                saveDoors()
            else
                term.setTextColor(colors.red)
                write("Invalid, door ID missing or corrupt. Message:\n"..textutils.serialise(message).."\n")
            end
        elseif command == "shortOpen" then
            term.setTextColor(colors.orange)
            write("shortOpen requested for "..message.doorID..".\n")
            rednet.send(message.doorID,{command="shortOpen"})
        elseif command == "request_open_status" then
            term.setTextColor(colors.orange)
            write("Request open status.\n")
            if doorControllers[message.folderName][id] then
                term.setTextColor(colors.white)
                write("Sending open status to "..id.."\n")
                rednet.send(id,{doorControllers[message.folderName][id].isOpen})
            else
                term.setTextColor(colors.red)
                write("Could not send open status, "..id.." does not exist in network.\n")
            end
        elseif command == "restart" then
            os.reboot()
        elseif command == "updateLightControllers" then
            term.clear()
            term.setCursorPos(1,1)
            term.setTextColor(colors.orange)
            write(id.." Requested update lights.\n")
            term.setTextColor(colors.white)
            lightControllers = message.lightControllers
            saveLightControllers()
        elseif command == "toggleLight" then
            term.setTextColor(colors.orange)
            write(id.." requested toggle lights.\n")
            term.setTextColor(colors.white)
            write("Alerting "..message.id.." of this change.\n")
            lightControllers[message.id].isOn = message.isOn
            rednet.send(message.id,{command="toggleLight",isOn=message.isOn})
            saveLightControllers()
        else
            term.setTextColor(colors.red)
            write("Invalid command! Message:\n"..textutils.serialise(message).."\n")
        end
        term.setTextColor(colors.lime)
        write("Done.\n")
    end
end

while true do
    receive()
end