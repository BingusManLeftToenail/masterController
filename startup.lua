EXIT = false
rednet.open("back")
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

local function saveDoorControllers()
    local file = fs.open("doorControllers","w")
    file.write(textutils.serialise(doorControllers))
    file.close()
end

if fs.exists("doorControllers") then
    local file = fs.open("doorControllers","r")
    doorControllers = textutils.unserialise(file.readAll())
    file.close()
else
    doorControllers = {["editMe"]={owner="Kyler"}}
    saveDoorControllers()
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

while serverID == -1 do
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.yellow)
    write("ENTER SERVER ID: ")
    term.setTextColor(colors.white)
    local input = tonumber(read())
    if input then
        serverID = input
        saveServerID()
    else
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        write("MUST BE NUMBER!")
        sleep(2)
    end
end


local function sync(inLoop)
    term.setBackgroundColor(colors.white)
    rednet.send(serverID,{command="sync_request"})
    for i = 1, 5 do
        local id,message = rednet.receive(_,.1)
        if id == serverID then
            doorControllers = message.doorControllers
            users = message.users
            lightControllers = message.lightControllers
            saveLightControllers()
            saveDoorControllers()
            saveUsers()
            break
        end
    end
end

local userExist = next(users)
if not userExist then
    sync()
    local secondCheck = next(users)
    userExist = secondCheck
end
while not userExist do
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.yellow)
    write("Enter New Username: ")
    term.setTextColor(colors.white)
    local username = read()
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.yellow)
    write("Enter Password: ")
    term.setTextColor(colors.white)
    local password = read("*")
    users[username] = {password=password,accLevel=5}
    rednet.send(serverID,{command="updateUsers",users=users})
    userExist = true
    saveUsers()
end

local colorSel = {
    [1] = "White",
    [2] = "Orange",
    [4] = "Magenta",
    [8] = "Light Blue",
    [16] = "Yellow",
    [32] = "Lime",
    [64] = "Pink",
    [128] = "Gray",
    [256] = "Light Gray",
    [512] = "Cyan",
    [1024] = "Purple",
    [2048] = "Blue",
    [4096] = "Brown",
    [8192] = "Green",
    [16384] = "Red",
    [32768] = "Black"
}

local function writeDisplay(textList,posList)
    local currentBackCol = term.getBackgroundColor()
    local invalid = false
    if #textList ~= #posList then
        return false
    end
    for i = 1, #textList do
        if not (type(textList[i]) == "string" and type(posList[i]) == "table") then
            invalid = true
            break
        end
        if not (posList[i].x1 and posList[i].y) then
            error("Missing arguments, posList[i]: "..textutils.serialise(posList[i]),2)
        end
        term.setCursorPos(posList[i].x1,posList[i].y)
        term.setTextColor(posList[i].textColor or colors.black)
        term.setBackgroundColor(posList[i].backColor or colors.white)
        write(textList[i])
        term.setBackgroundColor(currentBackCol)
    end
    return invalid
end

local function detClick(posList,usesRightClick)
    local event,button,x,y = os.pullEvent("mouse_click")
    if event and button then
        for i = 1, #posList do
            if x >= posList[i].x1 and x <= posList[i].x2 and y == posList[i].y then
                if usesRightClick then
                    return {index=i,button=button}
                else
                    return i
                end
            end
        end
    end
    if usesRightClick then
        return {index=0}
    else
        return 0
    end
end

local currentUser = ""

local function editUser()
    local continue = false
    continue = false
    while not continue do
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        local textList = {
            [1] = "         #SETTINGS         ",
            [2] = "         #User Sub         ",
            [3] = "       Edit Username       ",
            [4] = "       Edit Password       ",
            [5] = " User Editing: "..currentUser
        }
        local posList = {}
        for i = 1,2 do
            posList[i] = {x1=1,y=i,x2=27,textColor=colors.white,backColor=colors.blue}
        end
        for i = 3,#textList do
            posList[i] = {x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow}
        end
        textList[#textList+1] = " < BACK "
        posList[#posList+1] = {x1=19,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        posList[2].backColor = colors.black
        posList[5].backColor = colors.orange
        writeDisplay(textList,posList)
        local clickRet = detClick(posList)
        if clickRet == 3 then
            local newUser = false
            while not newUser do
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.yellow)
                term.clear()
                term.setCursorPos(1,1)
                write("Username: ")
                term.setTextColor(colors.white)
                local input = read()
                if string.upper(input) == "BACK" then
                    newUser = true
                else
                    local oldData = users[currentUser]
                    users[currentUser] = nil
                    currentUser = input
                    users[input] = oldData
                    saveUsers()
                    rednet.send(serverID,{command="updateUsers",users=users})
                    newUser = true
                end
            end
        elseif clickRet == 4 then
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.yellow)
            term.clear()
            term.setCursorPos(1,1)
            write("Password: ")
            term.setTextColor(colors.white)
            local input = read()
            if string.upper(input) == "BACK" then
                newUser = true
            else
                users[currentUser].password = input
                saveUsers()
                rednet.send(serverID,{command="updateUsers",users=users})
                newUser = true
            end
        elseif clickRet == #textList then
            continue = true
        end
    end
end

local function removeUser()
    local continue = false
    while not continue do
        local indexedUsers = {}
        for k,v in pairs(users) do
            table.insert(indexedUsers,k)
        end
        term.clear()
        term.setCursorPos(1,1)
        local textList = {
            [1] = "         #SETTINGS         ",
            [2] = "         #User Sub         ",
        }
        local posList = {}
        for i = 1,2 do
            posList[i] = {x1=1,y=i,x2=27,textColor=colors.white,backColor=colors.blue}
        end
        posList[2].backColor = colors.black
        for i = 1, #indexedUsers do
            textList[i+2] = indexedUsers[i]
            posList[i+2] = {x1=1,y=i+2,x2=27,textColor=colors.black,backColor=colors.orange}
        end
        textList[#textList+1] = " < BACK "
        posList[#posList+1] = {x1=19,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local clickRet = detClick(posList)
        if clickRet == #posList then
            continue = true
        else
            for i = 1, #indexedUsers do
                if clickRet-2 == i then
                    for k,v in pairs(doorControllers) do
                        if v.owner == indexedUsers[i] then
                            doorControllers[k] = nil
                        end
                    end
                    saveDoorControllers()
                    users[indexedUsers[i]] = nil
                    indexedUsers[i] = nil
                    saveUsers()
                    rednet.send(serverID,{command="updateUsers",users=users})
                    break
                end
            end
        end
    end
end

local function addUser()
    local username = ""
    local continue = false
    while not continue do
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.yellow)
        write("Enter User: ")
        term.setTextColor(colors.white)
        username = read()
        if not users[username] then
            continue = true
        else
            term.clear()
            term.setCursorPos(1,1)
            term.setTextColor(colors.red)
            write("USER EXISTS!")
            sleep(2)
        end
    end
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.yellow)
    write("Enter Pass: ")
    term.setTextColor(colors.white)
    local password = read("*")
    local validLevel = false
    local accLevel = -1
    while accLevel == -1 do
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.yellow)
        write("Enter Access Level: \n")
        term.setTextColor(colors.white)
        write("MAX: "..users[currentUser].accLevel)
        term.setCursorPos(21,1)
        local input = tonumber(read())
        if input and input <= users[currentUser].accLevel then
            accLevel = input
        else
            term.clear()
            term.setCursorPos(1,1)
            term.setTextColor(colors.red)
            write("INVALID! Higher than your own access level OR not a number!")
            sleep(2)
        end
    end
    users[username] = {password=password,accLevel=accLevel,username=username}
    rednet.send(serverID,{command="updateUsers",users=users})
    saveUsers()
end

local function editDoorWhitelist(folderName,door,noCancel)
    local continue = false
    local indexedUsers = {}
    local cancel = false
    for _,v in pairs(users) do
        table.insert(indexedUsers,v)
    end
    local whitelisted = {}
    for username,_ in pairs(users) do
        if (username == currentUser) or doorControllers[folderName][door].whitelisted[username] then
            whitelisted[username] = true
        else
            whitelisted[username] = false
        end
    end
    while not continue and not cancel do
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.blue)
        write("    SELECT WHITELISTED:    ")
        term.setTextColor(colors.black)
        for whiteUser,isWhitelisted in pairs(whitelisted) do
            if isWhitelisted then
                term.setBackgroundColor(colors.lime)
                write("> "..whiteUser.." \n")
                term.setBackgroundColor(colors.white)
            else
                term.setBackgroundColor(colors.red)
                write("> "..whiteUser.." \n")
                term.setBackgroundColor(colors.white)
            end
        end
        term.setCursorPos(19,2)
        term.setTextColor(colors.black)
        term.setBackgroundColor(colors.lime)
        write("# DONE #")
        if not noCancel then
            term.setBackgroundColor(colors.black)
            term.setCursorPos(1,1)
            term.setBackgroundColor(colors.red)
            write(" x ")
        end
        term.setCursorPos(1,20)
        term.setTextColor(colors.black)
        term.setBackgroundColor(colors.white)
        if doorControllers[folderName] and doorControllers[folderName][door] and doorControllers[folderName][door].name then
            write("Door: "..doorControllers[folderName][door].name)
        end

        local event,button,x,y = os.pullEvent("mouse_click")
        local counter = 2
        for clickUser,clickListed in pairs(whitelisted) do
            if event and button then
                local validClick = (x >= 1 and x <= string.len("> "..clickUser)+2 and y == counter and y <= #indexedUsers+1)
                local isUser = clickUser == currentUser
                if validClick and not isUser then
                    whitelisted[clickUser] = not whitelisted[clickUser]
                    break
                else
                    counter = counter + 1
                end
                if x >= 19 and x <= 27 and y == 2 then
                    continue = true
                elseif x >= 1 and x <= 3 and y == 1 and not noCancel then
                    cancel = true
                    break
                end
            end
        end
    end
    if not cancel then
        doorControllers[folderName][door].whitelisted = whitelisted
        rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
        saveDoorControllers()
    else
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.yellow)
        write("Program terminated\n")
    end
end

local function addDoor(folderName)
    local CANCEL = false
    local newName = ""
    local newID = -1
    while newName == "" and not CANCEL do
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.yellow)
        term.clear()
        term.setCursorPos(1,1)
        write("NEW NAME: ")
        term.setTextColor(colors.white)
        local input = read()
        if string.upper(input) == "BACK" or string.upper(input) == "CANCEL" then
            CANCEL = true
        elseif input == "" or input == " " then
            term.clear()
            term.setCursorPos(1,1)
            term.setTextColor(colors.red)
            write("Cannot be blank!")
            sleep(2)
        else
            newName = input
        end
    end
    while newID == -1 and not CANCEL do
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.yellow)
        term.clear()
        term.setCursorPos(1,1)
        write("NEW ID: ")
        term.setTextColor(colors.white)
        local input = read()
        local tid = tonumber(input)
        if string.upper(input) == "BACK" or string.upper(input) == "CANCEL" then
            CANCEL = true
        else
            if tid and not doorControllers[folderName][tid] then
                newID = tid
            else
                term.clear()
                term.setTextColor(colors.red)
                write("INVALID! Must be number / already exists!")
                sleep(2)
            end
        end
    end
    if newName and newID and not CANCEL then
        doorControllers[folderName][newID] = {name=newName,owner=currentUser,id=newID,whitelisted={},isOpen=false}
        editDoorWhitelist(folderName,newID,true)
    end
end

local function addFolder()
    local CANCEL = false
    while not CANCEL do
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.yellow)
        term.clear()
        term.setCursorPos(1,1)
        write("FOLD NAME: ")
        term.setTextColor(colors.white)
        local input = read()
        if string.upper(input) == "BACK" or string.upper(input) == "CANCEL" then
            CANCEL = true
        elseif input == "" or input == " " then
            term.clear()
            term.setCursorPos(1,1)
            term.setTextColor(colors.red)
            write("Cannot be blank!")
            sleep(2)
        else
            doorControllers[input] = {}
            saveDoorControllers()
            CANCEL = true
        end
    end
end
local function moveToDoorFolder(currentFolder,doorID)
    local CANCEL = false
    local folderMoved = ""
    while not CANCEL do
        local indexedFolders = {}
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        for folderName,folderData in pairs(doorControllers) do
            table.insert(indexedFolders,{name=folderName,data=folderData,owner=folderData.owner})
        end
        local posList = {}
        local textList = {
            [1] = "      Door Controller      ",
            [2] = "        Folder Main        ",
            [3] = "Add Folder",
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        posList[1].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].textColor = colors.white
        posList[2].backColor = colors.black
        posList[3].backColor = colors.lime
        posList[3].x1 = 11
        posList[3].x2 = 20
        posList[3].y = 20
        for i = 1,#indexedFolders do
            table.insert(textList," "..indexedFolders[i].name..string.rep(" ",27-string.len(indexedFolders[i].name)))
            table.insert(posList,{x1=1,y=i+2,x2=27,textColor=colors.black,backColor=colors.lightBlue})
        end
        textList[#textList+1] = "< BACK"
        posList[#posList+1] = {x1=21,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local retClick = detClick(posList)
        if retClick == 3 then
            addFolder()
            rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
        elseif retClick == #textList then
            CANCEL = true
        else
            for i = 1, #indexedFolders do
                if retClick-3 == i then
                    local oldData = doorControllers[currentFolder][doorID]
                    doorControllers[currentFolder][doorID] = nil
                    doorControllers[indexedFolders[i].name][doorID] = oldData
                    rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
                    term.setBackgroundColor(colors.black)
                    term.setTextColor(colors.lime)
                    term.clear()
                    folderMoved = indexedFolders[i].name
                    write("Moved.")
                    sleep(2)
                    break
                end
            end
        end
        if folderMoved ~= "" then
            CANCEL = true
        end
    end
    if folderMoved ~= "" then
        return folderMoved
    end
end


local function editDoor(folderName,doorID)
    local CANCEL = false
    if not doorControllers[folderName] or not doorControllers[folderName][doorID] then
        CANCEL = true
    end
    while not CANCEL do
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        local posList = {}
        local textList = {
            [1] = "      Door Controller      ",
            [2] = "         Edit Menu         ",
            [3] = "        Change Name        ",
            [4] = "         Change ID         ",
            [5] = "      >Move To Folder      ",
            [6] = "      #Edit Whitelist      ",
            [7] = " Editing: "..doorControllers[folderName][doorID].name
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        posList[1].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].textColor = colors.white
        posList[2].backColor = colors.black
        posList[6].backColor = colors.orange

        textList[#textList+1] = "< BACK"
        posList[#posList+1] = {x1=21,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local clickRet = detClick(posList)
        if clickRet == #textList then
            CANCEL = true
        elseif clickRet == 3 then
            local newName = false
            while not newName do
                term.setBackgroundColor(colors.black)
                term.clear()
                term.setCursorPos(1,1)
                term.setTextColor(colors.yellow)
                write("NEW NAME: ")
                term.setTextColor(colors.white)
                local input = read()
                if input ~= "" then
                    doorControllers[folderName][doorID].name = input
                    saveDoorControllers()
                    rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
                    newName = true
                else
                    term.clear()
                    term.setCursorPos(1,1)
                    term.setTextColor(colors.red)
                    write("INVALID! Name cannot be blank!")
                    sleep(2)
                end
            end
        elseif clickRet == 4 then
            local newID = false
            while not newID do
                term.setBackgroundColor(colors.black)
                term.clear()
                term.setCursorPos(1,1)
                term.setTextColor(colors.yellow)
                write("NEW ID: ")
                term.setTextColor(colors.white)
                local input = read()
                local tid = tonumber(input)
                if type(tid) == "number" then
                    doorControllers[folderName][doorID].name = input
                    saveDoorControllers()
                    rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
                    newID = true
                else
                    term.clear()
                    term.setCursorPos(1,1)
                    term.setTextColor(colors.red)
                    write("INVALID! Must be number!")
                    sleep(2)
                end
            end
        elseif clickRet == 5 then
            local newFolder = moveToDoorFolder(folderName,doorID)
            if newFolder ~= folderName and type(newFolder) == "string" then
                folderName = newFolder
            end
        elseif clickRet == 6 then
            editDoorWhitelist(folderName,doorID)
        end
    end
end

local doorDeleteMode = false
local function doorList(folderName)
    local CANCEL = false
    while not CANCEL do
        local indexedDoors = {}
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        if next(doorControllers[folderName]) then
            for doorID,doorData in pairs(doorControllers[folderName]) do
                if doorData and doorData.whitelisted and doorData.whitelisted[currentUser] then
                    table.insert(indexedDoors,{name=doorData.name,owner=doorData.owner,doorID=doorID,isOpen=doorData.isOpen,whitelisted=doorData.whitelisted})
                end
            end
        end
        if #indexedDoors < 1 then
            term.setCursorPos(1,4)
            term.setTextColor(colors.black)
            write("No doors, try adding some!")
        end
        local posList = {}
        local textList = {
            [1] = "      Door Controller      ",
            [2] = " FOLDER: "..folderName..string.rep(" ",27-string.len(folderName)),
            [3] = "+Add  Door",
            [4] = "-Del  Door"
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        if doorDeleteMode then
            textList[4] = "  CANCEL  "
        end
        posList[1].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].textColor = colors.white
        posList[2].backColor = colors.black
        posList[3].backColor = colors.lime
        posList[3].x1 = 11
        posList[3].x2 = 20
        posList[3].y = 20
        posList[4].backColor = colors.orange
        posList[4].x1 = 1
        posList[4].x2 = 11
        posList[4].y = 20
        for i = 1,#indexedDoors do
            if doorDeleteMode then
                table.insert(textList," "..indexedDoors[i].name..string.rep(" ",27-string.len(indexedDoors[i].name)-7).."[DEL]")
                table.insert(posList,{x1=1,y=i+2,x2=27,textColor=colors.black,backColor=colors.orange})
            else
                if indexedDoors[i].isOpen == true and not doorDeleteMode then
                    table.insert(textList," "..indexedDoors[i].name..string.rep(" ",27-string.len(indexedDoors[i].name)-12).."[OP]")
                    table.insert(posList,{x1=1,y=i+2,x2=string.len(" "..indexedDoors[i].name..string.rep(" ",27-string.len(indexedDoors[i].name)-12).."[CL]"),textColor=colors.black,backColor=colors.green})
                elseif not indexedDoors[i].isOpen and not doorDeleteMode then
                    table.insert(textList," "..indexedDoors[i].name..string.rep(" ",27-string.len(indexedDoors[i].name)-12).."[CL]")
                    table.insert(posList,{x1=1,y=i+2,x2=string.len(" "..indexedDoors[i].name..string.rep(" ",27-string.len(indexedDoors[i].name)-12).."[CL]"),textColor=colors.black,backColor=colors.red})
                end
            end
        end
        local editButtons = {}
        if not doorDeleteMode then
            for i = 1,#indexedDoors do
                if currentUser then
                    table.insert(posList,{x1=21,x2=27,y=i+2,textColor=colors.black,backColor=colors.lightBlue})
                    table.insert(textList," EDIT ")
                    table.insert(editButtons,#posList)
                end
            end
        end
        textList[#textList+1] = "< BACK"
        posList[#posList+1] = {x1=21,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local retClick = detClick(posList,true)
        local selected = -1
        for i = 1,#indexedDoors do
            if retClick.index-4 == i then
                if doorDeleteMode then
                    if indexedDoors[i].owner == currentUser then
                        doorControllers[folderName][indexedDoors[i].doorID] = nil
                        indexedDoors[i] = nil
                        saveDoorControllers()
                        rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
                        term.setCursorPos(1,2)
                        selected = i
                        break
                    else
                        term.setTextColor(colors.red)
                        term.setBackgroundColor(colors.white)
                        write("You must be the owner of this door in order to remove it!")
                        sleep(2)
                    end
                elseif retClick.index-4 == i and retClick.button == 1 and not doorControllers[folderName][indexedDoors[i].doorID].isOpen then
                    rednet.send(serverID,{command="shortOpen",folderName=folderName,doorID=indexedDoors[i].doorID})
                elseif retClick.index-4 == i and retClick.button == 2 then
                    doorControllers[folderName][indexedDoors[i].doorID].isOpen = not doorControllers[folderName][indexedDoors[i].doorID].isOpen
                    indexedDoors[i].isOpen = doorControllers[folderName][indexedDoors[i].doorID].isOpen
                    rednet.send(serverID,{command="toggleDoor",folderName=folderName,isOpen=doorControllers[folderName][indexedDoors[i].doorID].isOpen,doorID=indexedDoors[i].doorID})
                    saveDoorControllers()
                    term.setCursorPos(1,2)
                    selected = i
                    break
                end
            end
            if retClick.index == editButtons[i] and currentUser == indexedDoors[i].owner then
                editDoor(folderName,indexedDoors[i].doorID)
            end
        end
        if retClick.index == #textList then
            CANCEL = true
        elseif retClick.index == 3 then
            addDoor(folderName)
        elseif retClick.index == 4 then
            doorDeleteMode = not doorDeleteMode
        end
    end
end

local function editFolder(folderName)
    local CANCEL = false
    while not CANCEL do
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        local posList = {}
        local textList = {
            [1] = "      Door Controller      ",
            [2] = "         Edit Menu         ",
            [3] = "        Change Name        ",
            [4] = " Editing: "..folderName
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        posList[1].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].textColor = colors.white
        posList[2].backColor = colors.black
        posList[4].backColor = colors.orange

        textList[#textList+1] = "< BACK"
        posList[#posList+1] = {x1=21,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local clickRet = detClick(posList)
        if clickRet == #textList then
            CANCEL = true
        elseif clickRet == 3 then
            local newName = false
            while not newName do
                term.setBackgroundColor(colors.black)
                term.clear()
                term.setCursorPos(1,1)
                term.setTextColor(colors.yellow)
                write("NEW NAME: ")
                term.setTextColor(colors.white)
                local input = read()
                if input ~= "" then
                    local oldData = doorControllers[folderName]
                    doorControllers[folderName] = nil
                    doorControllers[input] = oldData
                    saveDoorControllers()
                    rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
                    newName = true
                    folderName = input
                else
                    term.clear()
                    term.setCursorPos(1,1)
                    term.setTextColor(colors.red)
                    write("INVALID! Name cannot be blank!")
                    sleep(2)
                end
            end
        end
    end

end

local folderDeleteMode = false
local function doorFolderController()
    local CANCEL = false
    while not CANCEL do
        local indexedFolders = {}
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        for folderName,folderData in pairs(doorControllers) do
            table.insert(indexedFolders,{name=folderName,data=folderData,owner=folderData.owner})
        end
        local posList = {}
        local textList = {
            [1] = "      Door Controller      ",
            [2] = "        Folder Main        ",
            [3] = "Add Folder",
            [4] = "Del Folder"
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        if folderDeleteMode then
            textList[4] = "  CANCEL  "
        end
        posList[1].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].textColor = colors.white
        posList[2].backColor = colors.black
        posList[3].backColor = colors.lime
        posList[3].x1 = 11
        posList[3].x2 = 20
        posList[3].y = 20
        posList[4].backColor = colors.orange
        posList[4].x1 = 1
        posList[4].x2 = 11
        posList[4].y = 20
        for i = 1,#indexedFolders do
            if folderDeleteMode then
                table.insert(textList," "..indexedFolders[i].name..string.rep(" ",27-string.len(indexedFolders[i].name)-7).."[DEL]")
                table.insert(posList,{x1=1,y=i+2,x2=27,textColor=colors.black,backColor=colors.orange})
            else
                table.insert(textList," "..indexedFolders[i].name..string.rep(" ",27-string.len(indexedFolders[i].name)-8))
                table.insert(posList,{x1=1,y=i+2,x2=string.len(" "..indexedFolders[i].name..string.rep(" ",21-string.len(indexedFolders[i].name)-2)),textColor=colors.black,backColor=colors.yellow})
            end
        end
        local editButtons = {}
        if not folderDeleteMode then
            for i = 1,#indexedFolders do
                if currentUser then
                    table.insert(posList,{x1=21,x2=27,y=i+2,textColor=colors.black,backColor=colors.lightBlue})
                    table.insert(textList," EDIT ")
                    table.insert(editButtons,#posList)
                end
            end
        end
        textList[#textList+1] = "< BACK"
        posList[#posList+1] = {x1=21,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local retClick = detClick(posList)
        if retClick == 3 then
            addFolder()
            rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
        elseif retClick == 4 then
            folderDeleteMode = not folderDeleteMode
        elseif retClick == #textList then
            CANCEL = true
        else
            if folderDeleteMode then
                local continue = true
                local folderDelete = ""
                for i = 1,#indexedFolders do
                    if retClick-4 == i then
                        for doorID,doorData in pairs(doorControllers[indexedFolders[i].name]) do
                            if doorData.owner ~= currentUser then
                                continue = false
                                break
                            end
                        end
                        if continue then
                            folderDelete = indexedFolders[i].name
                        end
                    end
                end
                local accLvlValid = users[currentUser].accLevel > 4
                continue = continue or accLvlValid
                if continue then
                    doorControllers[folderDelete] = nil
                    indexedFolders[folderDelete] = nil
                    saveDoorControllers()
                    rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
                else
                    write("NO ACCESS / CONTAINS DOORS YOU DON'T OWN!")
                    sleep(2)
                end
            else
                for i = 1, #indexedFolders do
                    if retClick-4 == i then
                        doorList(indexedFolders[i].name)
                        rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
                        break
                    elseif retClick == editButtons[i] then
                        editFolder(indexedFolders[i].name)
                        rednet.send(serverID,{command="updateDoorControllers",doorControllers=doorControllers})
                        break
                    end
                end
            end
        end
    end
end

local function addLight()
    local CANCEL = false
    local name = ""
    local id = -1
    while name == "" and not CANCEL do
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.yellow)
        write("LIGHT NAME: ")
        term.setTextColor(colors.white)
        local input = read()
        if input ~= "" then
            name = input
        elseif string.upper(input) == "CANCEL" then
            CANCEL = true
        else
            term.clear()
            term.setCursorPos(1,1)
            term.setTextColor(colors.red)
            write("INVALID! Maybe blank!")
            sleep(2)
        end
    end

    while id == -1 and not CANCEL do
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.yellow)
        write("LIGHT ID: ")
        term.setTextColor(colors.white)
        local input = read()
        local tid = tonumber(input)
        if tid then
            id = tid
        elseif string.upper(input) == "CANCEL" then
            CANCEL = true
        else
            term.clear()
            term.setCursorPos(1,1)
            term.setTextColor(colors.red)
            write("INVALID! Exists or is blank!")
            sleep(2)
        end
    end

    if not CANCEL then
        lightControllers[id] = {name=name,isOn=false}
        rednet.send(serverID,{command="updateLightControllers",lightControllers=lightControllers})
        saveLightControllers()
    end
end

local function editLight(lightID)
    local CANCEL = false
    while not CANCEL do
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        local posList = {}
        local textList = {
            [1] = "     #Light Controller     ",
            [2] = "         Edit Menu         ",
            [3] = "        Change Name        ",
            [4] = "         Change ID         ",
            [5] = " Editing: "..lightControllers[lightID].name
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        posList[1].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].textColor = colors.white
        posList[2].backColor = colors.black
        posList[5].backColor = colors.orange
        textList[#textList+1] = "< BACK"
        posList[#posList+1] = {x1=21,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local clickRet = detClick(posList)
        if clickRet == #textList then
            CANCEL = true
        elseif clickRet == 3 then
            local newName = false
            while not newName do
                term.setBackgroundColor(colors.black)
                term.clear()
                term.setCursorPos(1,1)
                term.setTextColor(colors.yellow)
                write("NEW NAME: ")
                term.setTextColor(colors.white)
                local input = read()
                if input ~= "" then
                    lightControllers[lightID].name = input
                    saveLightControllers()
                    rednet.send(serverID,{command="updateLightControllers",lightControllers=lightControllers})
                    newName = true
                else
                    term.clear()
                    term.setCursorPos(1,1)
                    term.setTextColor(colors.red)
                    write("INVALID! Name cannot be blank!")
                    sleep(2)
                end
            end
        elseif clickRet == 4 then
            local newID = false
            while not newID do
                term.setBackgroundColor(colors.black)
                term.clear()
                term.setCursorPos(1,1)
                term.setTextColor(colors.yellow)
                write("NEW ID: ")
                term.setTextColor(colors.white)
                local input = read()
                local tid = tonumber(input)
                if type(tid) == "number" then
                    lightControllers[lightID].name = input
                    saveLightControllers()
                    rednet.send(serverID,{command="updateLightControllers",lightControllers=lightControllers})
                    newID = true
                else
                    term.clear()
                    term.setCursorPos(1,1)
                    term.setTextColor(colors.red)
                    write("INVALID! Must be number!")
                    sleep(2)
                end
            end
        end
    end
end

local lightDeleteMode = false
local function lightController()
    local CANCEL = false
    while not CANCEL do
        local indexedLights = {}
        for lightID,lightData in pairs(lightControllers) do
            table.insert(indexedLights,{name=lightData.name,lightID=lightID,isOn=lightData.isOn})
        end
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        local posList = {}
        local textList = {
            [1] = "     #Light Controller     ",
            [2] = "        #L-Con Main        ",
            [3] = "+Add Light",
            [4] = "-Del Light",
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        posList[1].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].textColor = colors.white
        posList[2].backColor = colors.black
        posList[3].backColor = colors.lime
        posList[3].x1 = 11
        posList[3].x2 = 20
        posList[3].y = 20
        posList[4].backColor = colors.orange
        posList[4].x1 = 1
        posList[4].x2 = 11
        posList[4].y = 20
        for i = 1,#indexedLights do
            if lightDeleteMode then
                table.insert(textList," "..indexedLights[i].name..string.rep(" ",27-string.len(indexedLights[i].name)-7).."[DEL]")
                table.insert(posList,{x1=1,y=i+2,x2=27,textColor=colors.black,backColor=colors.orange})
            else
                if indexedLights[i].isOn == true and not lightDeleteMode then
                    table.insert(textList," "..indexedLights[i].name..string.rep(" ",27-string.len(indexedLights[i].name)-12).."[ON]")
                    table.insert(posList,{x1=1,y=i+2,x2=string.len(" "..indexedLights[i].name..string.rep(" ",27-string.len(indexedLights[i].name)-12).."[ON]"),textColor=colors.black,backColor=colors.green})
                elseif not indexedLights[i].isOn and not lightDeleteMode then
                    table.insert(textList," "..indexedLights[i].name..string.rep(" ",27-string.len(indexedLights[i].name)-12).."[OF]")
                    table.insert(posList,{x1=1,y=i+2,x2=string.len(" "..indexedLights[i].name..string.rep(" ",27-string.len(indexedLights[i].name)-12).."[OF]"),textColor=colors.black,backColor=colors.red})
                end
            end
        end
        local editButtons = {}
        if not doorDeleteMode then
            for i = 1,#indexedLights do
                table.insert(posList,{x1=21,x2=27,y=i+2,textColor=colors.black,backColor=colors.lightBlue})
                table.insert(textList," EDIT ")
                table.insert(editButtons,#posList)
            end
        end
        textList[#textList+1] = "< BACK"
        posList[#posList+1] = {x1=21,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local retClick = detClick(posList)
        local selected = -1
        for i = 1,#indexedLights do
            if retClick-4 == i then
                if lightDeleteMode then
                    lightControllers[indexedLights[i].lightID] = nil
                    indexedLights[i] = nil
                    saveLightControllers()
                    rednet.send(serverID,{command="updateLightControllers",lightControllers=lightControllers})
                    term.setCursorPos(1,2)
                    selected = i
                    break
                else
                    lightControllers[indexedLights[i].lightID].isOn = not lightControllers[indexedLights[i].lightID].isOn
                    indexedLights[i].isOn = lightControllers[indexedLights[i].lightID].isOn
                    rednet.send(serverID,{command="toggleLight",isOn=lightControllers[indexedLights[i].lightID].isOn,id=indexedLights[i].lightID})
                    saveLightControllers()
                    term.setCursorPos(1,2)
                    selected = i
                    break
                end
            end
            if retClick == editButtons[i] then
                editLight(indexedLights[i].lightID)
            end
        end
        if retClick == #textList then
            CANCEL = true
        elseif retClick == 3 then
            addLight()
        elseif retClick == 4 then
            lightDeleteMode = not lightDeleteMode
        end
    end
end

local function globalUserSettings()
    sync()
    local CANCEL = false
    while not CANCEL do
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        local posList = {}
        local textList = {
            [1] = "         #Settings         ",
            [2] = "      User Global Sub      ",
            [3] = "         +Add User         ",
            [4] = "         -Del User         ",
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        
        posList[1].textColor = colors.white
        posList[2].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].backColor = colors.black
        textList[#textList+1] = " < BACK "
        posList[#posList+1] = {x1=19,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local clickRet = detClick(posList)
        if clickRet == #posList then
            CANCEL = true
        else
            if clickRet == 3 then
                addUser()
            elseif clickRet == 4 then
                removeUser()
            end
        end
    end
end

local function serverSettings()
    sync()
    local CANCEL = false
    while not CANCEL do
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        local posList = {}
        local textList = {
            [1] = "         #Settings         ",
            [2] = "       Serv Sub Main       ",
            [3] = "      !Restart Server      ",
            [4] = "     Reassign ServerID     ",
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        
        posList[1].textColor = colors.white
        posList[2].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].backColor = colors.black
        posList[4].backColor = colors.red
        posList[4].textColor = colors.white
        textList[#textList+1] = " < BACK "
        posList[#posList+1] = {x1=19,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local clickRet = detClick(posList)
        if clickRet == #posList then
            CANCEL = true
        else
            if clickRet == 3 then
                rednet.send(serverID,{command="restart"})
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.orange)
                term.clear()
                write("Server restarted.")
                sleep(2)
            elseif clickRet == 4 then
                users = {}
                doorControllers = {}
                saveUsers()
                saveDoorControllers()
                serverID = -1
                saveServerID()
                os.reboot()
            end
        end
    end
end

local function compSettings()
    sync()
    local CANCEL = false
    while not CANCEL do
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        local posList = {}
        local textList = {
            [1] = "         #Settings         ",
            [2] = "       Comp Sub Main       ",
            [3] = "         Set Label         ",
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        
        posList[1].textColor = colors.white
        posList[2].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].backColor = colors.black
        textList[#textList+1] = " < BACK "
        posList[#posList+1] = {x1=19,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local clickRet = detClick(posList)
        if clickRet == #posList then
            CANCEL = true
        else
            if clickRet == 3 then
                term.setBackgroundColor(colors.black)
                term.clear()
                term.setCursorPos(1,1)
                term.setTextColor(colors.yellow)
                write("NEW LABEL: ")
                term.setTextColor(colors.white)
                local input = read()
                os.setComputerLabel(input)
                term.setTextColor(colors.lime)
                write("\nDONE.")
                sleep(2)
            end
        end
    end
end

local function settings()
    sync()
    local CANCEL = false
    while not CANCEL do
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        local posList = {}
        local textList = {
            [1] = "         #Settings         ",
            [2] = "       Sett Sub Main       ",
            [3] = "    #Self User Settings    ",
            [4] = "   #Global User Settings   ",
            [5] = "      Server Settings      ",
            [6] = "       Comp Settings       "
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,y=i,x2=27,textColor=colors.black,backColor=colors.yellow})
        end
        
        posList[1].textColor = colors.white
        posList[2].textColor = colors.white
        posList[1].backColor = colors.blue
        posList[2].backColor = colors.black
        textList[#textList+1] = " < BACK "
        posList[#posList+1] = {x1=19,y=20,x2=27,textColor=colors.black,backColor=colors.red}
        writeDisplay(textList,posList)
        local clickRet = detClick(posList)
        if clickRet == #posList then
            CANCEL = true
        else
            if clickRet == 3 then
                editUser()
            elseif clickRet == 4 then
                globalUserSettings()
            elseif clickRet == 5 then
                if users[currentUser].accLevel == 5 then
                    serverSettings()
                else
                    term.setBackgroundColor(colors.black)
                    term.setTextColor(colors.red)
                    term.clear()
                    term.setCursorPos(1,1)
                    write("Haha you don't have access to this bitch")
                    sleep(2)
                end
            elseif clickRet == 6 then
                compSettings()
            end
        end
    end
end

local function menu()
    sync()
    if currentUser == "" then
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.white)
        term.clear()
        local indexedUsers = {}
        for username,userData in pairs(users) do
            table.insert(indexedUsers,username)
        end
        local posList = {}
        local textList = {
            [1] = "         Sel  User         ",
        }
        posList[1] = {x1=1,y=1,x2=27,textColor=colors.white,backColor=colors.blue}
        for i = 1,#indexedUsers do
            textList[i+1] = " "..indexedUsers[i].." "
            posList[i+1] = {x1=1,x2=string.len(" "..indexedUsers[i].." "),y=i+1,textColor=colors.black,backColor=colors.yellow}
        end
        writeDisplay(textList,posList)
        local clickRet = detClick(posList)-1
        if indexedUsers[clickRet] then
            local validPass = false
            while not validPass do
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.yellow)
                term.clear()
                term.setCursorPos(1,1)
                write("PASS: \n")
                term.setTextColor(colors.lightGray)
                write("Type 'Back' to go back.\n")
                term.setTextColor(colors.orange)
                write("User: "..indexedUsers[clickRet])
                term.setTextColor(colors.white)
                term.setCursorPos(7,1)
                local input = read("*")
                if input == users[indexedUsers[clickRet]].password then
                    currentUser = indexedUsers[clickRet]
                    validPass = true
                elseif string.upper(input) == "BACK" then
                    validPass = true
                else
                    term.setBackgroundColor(colors.white)
                    term.clear()
                    term.setCursorPos(1,1)
                    term.setTextColor(colors.red)
                    write("INVALID PASSWORD!")
                    sleep(2)
                end
            end
        end
    else
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.white)
        term.clear()
        term.setBackgroundColor(colors.blue)
        term.setCursorPos(1,1)
        write("         MAIN MENU         \n")
        term.setBackgroundColor(colors.black)
        write(string.rep(" ",27))
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        local posList = {}
        local textList = {
            [1] = "      Door Controller      ",
            [2] = "     Lights Controller     ",
            [3] = "         #Settings         ",
            [4] = "          !LOGOUT          ",
            [5] = "         !SHUTDOWN         ",
            [6] = "           !EXIT           ",
            [7] = currentUser..string.rep(" ",27-string.len(currentUser)),
            [8] = "    Master Control V1.0    ",
            [9] = "         UPD 1.0:         ",
            [10] = "- Full func for door cont ",
            [11] = "- Full func for user syst ",
            [12] = "- Full func for perm syst ",
            [13] = "- Automated syncing w/serv",
            [14] = "- Soon to be:             ",
            [15] = "- Folder store for doors  ",
            [16] = "- Hide doors w/no access  ",
            [17] = " Sync "
        }
        for i = 1, #textList do
            table.insert(posList,{x1=1,x2=23,y=i+2,textColor=colors.black,backColor=colors.yellow})
        end
        for i = 9,#textList do
            posList[i].backColor = colors.white
            posList[i].y = posList[i].y-1
        end
        posList[4].backColor = colors.orange
        posList[5].textColor = colors.white
        posList[5].backColor = colors.red
        posList[6].textColor = colors.white
        posList[6].backColor = colors.red
        posList[6].textColor = colors.white
        posList[7].backColor = colors.blue
        posList[7].textColor = colors.white
        posList[8].textColor = colors.yellow
        posList[8].backColor = colors.blue
        posList[9].textColor = colors.black
        posList[8].y = 20
        posList[14].backColor = colors.blue
        posList[14].textColor = colors.white
        posList[17].backColor = colors.yellow
        posList[17].y = 19
        writeDisplay(textList,posList)
        term.setBackgroundColor(colors.white)
        local clickRet = detClick(posList)
        if clickRet == 1 then -- Door Controller
            doorFolderController()
        elseif clickRet == 2 then -- Light Controller
            lightController()
        elseif clickRet == 3 then -- Settings
            settings()
        elseif clickRet == 4 then
            currentUser = ""
        elseif clickRet == 5 then -- Shutdown
            os.shutdown()
        elseif clickRet == 6 and users[currentUser].accLevel > 4 then -- Exit
            EXIT = true
            CANCEL = true
        elseif clickRet == 17 then
            sync()
        end
    end
end

local counter = 0
while not EXIT do
    menu()
end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)