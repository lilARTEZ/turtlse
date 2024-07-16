local locationFile='location.txt'
local directiveFile='directive.txt'
local actionFile='action.txt'


local location={{0,0,0},{0,' - facing Z'}}
local directive={"Inquisitor"}
local action={}




local function fileExists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end



local function deleteFile(path)
    os.remove(path)
end



local function writeFile(path,data)--list of rows to write {data,data,data}
    local file = io.open(path, 'w')
    for index, value in ipairs(data) do
        file:write(value..'\n')
    end
    io.close(file)
end



local function readFile(inputFile)
    local file = io.open(inputFile, 'r')
    local fileContent = {}
    for line in file:lines() do
        table.insert (fileContent, line)
    end
    io.close(file)
    return fileContent
end



local function editFile(data,inputFile) --Takes a list [line,text]
    local fileContent=readFile(inputFile)
    for index, value in pairs(data)do
        fileContent[value[1]]=value[2]
    end
    writeFile(inputFile)
end



local function refuel()
    while (turtle.getFuelLevel() < turtle.getFuelLimit()/2) do
        for i = 1, 16, 1 do
            turtle.select()
            turtle.refuel()
        end
    end
end



local function turn(location,direction)

    local facing=location[2][1]


    if direction=='left' then
        facing=facing-1
        if facing<-2 then
            facing=1
        end
        turtle.turnLeft()
    elseif direction=='right' then
        facing=facing+1
        if facing>2 then
            facing=-1
        end
        turtle.turnRight()
    end


    if facing==0 then
        location[2]={facing,' - facing Z'}
    elseif facing==1 then
        location[2]={facing,' - facing X'}
    elseif facing==-1 then
        location[2]={facing,' - facing -X'}
    else
        location[2]={facing,' - facing -Z'}
    end

    writeFile(locationFile,location)
    return location
end


local function turnTo(location,direction)
    while location[2][1]~=direction do
        location = turn(location,'left')
    end
end



local function goToPath(location,destiny)
    local position=location[1]
    local distance = {0,0,0}

    local path={'move'}

    for index, value in ipairs(location) do
        distance[index]=destiny[index]-value
    end


    
    while position[2]~= destiny[2] do
        if distance[2]<0 then
            position[2]=position[2]-1
            table.insert(path,-3)
        else
            position[2]=position[2]+1
            table.insert(path,3)
        end
    end
    while position[1]~= destiny[1] do
        if distance[1]<0 then
            position[1]=position[1]-1
            table.insert(path,-1)
        else
            position[1]=position[1]+1
            table.insert(path,1)
        end
    end
    while position[3]~= destiny[3] do
        if distance[3]<0 then
            position[3]=position[3]-1
            table.insert(path,2)
        else
            position[3]=position[3]+1
            table.insert(path,0)
        end
    end
    writeFile(actionFile,{path})
    action = path
end





local function goTo()
    location = readFile(locationFile)
    action = readFile(actionFile)
    for i = 2, #action, 1 do
        if action[i]==5 or action[i]==-5 then
            
        end
    end
end




if not fileExists(locationFile) then
    writeFile(locationFile,location)
end
if not fileExists(directiveFile) then
    writeFile(directiveFile,directive)
end
if not fileExists(actionFile) then
    writeFile(actionFile,action)
else
    action=readFile(actionFile)
    if action[1]~='' then
        if action[1]=='move' then
            goTo()
        end
    end
end
