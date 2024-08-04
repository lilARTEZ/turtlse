local locationFile='location.txt'
local directiveFile='directive.txt'
local actionFile='action.txt'


local location={{0,0,0},{0,' - facing Z'}}
local directive={{"Inquisitor"}}
local action={}


local function encodeTable(tablet)
    local data={}
    for index, value in ipairs(tablet) do
        local string=''
        if type(value) == "table" then
            for index, content in ipairs(value) do
                if string=='' then
                    string=content
                else
                    string=string..'$'..content
                end
            end
        else
            string=value
        end
        table.insert(data,string)
    end
    return data
end



local function decodeTable(fileContent)
    local tableLines={}
    for index, value in ipairs(fileContent) do
        local line={}
        for str in string.gmatch(value,"([^%$]+)") do
            if tonumber(str)==nil then
                table.insert( line, str)
            else
                table.insert( line,tonumber(str))
            end
        end
        table.insert(tableLines,line)
    end
    return tableLines
end



local function fileExists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end



local function deleteFile(path)
    os.remove(path)
end



local function writeFile(path,data)--list of rows to write {data,data,data}
    data=encodeTable(data)
    local file = io.open(path, 'w')
    for index, value in ipairs(data) do
        value=tostring(value)
        file:write(value..'\n')
    end
    io.close(file)
end



local function readFile(inputFile)
    local file = io.open(inputFile, 'r')
    local fileContent = {}
    for line in file:lines() do
        table.insert(fileContent, line)
    end
    io.close(file)
    return decodeTable(fileContent)
end



local function editFile(inputFile,data) --Takes a list [line,text]
    local fileContent=readFile(inputFile)
    for index, value in pairs(data)do
        table.insert( fileContent,value[1],value[2])
    end
    writeFile(inputFile,fileContent)
end


local function appendFile(inputFile,data)
    local fileContent=readFile(inputFile)
    for index, value in pairs(data)do
        table.insert(fileContent,value)
    end
    writeFile(inputFile,fileContent)
end


local function refuel()
    while (turtle.getFuelLevel() < turtle.getFuelLimit()/2) do
        for i = 1, 16, 1 do
            term.clear()
            print('refueling: '..turtle.getFuelLevel())
            turtle.select(i)
            turtle.refuel()
        end
    end
    turtle.select(1)
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
        if direction==2 or direction==-2 then
            if location[2][1]==2 or location[2][1]==-2 then
                break
            end
        end
        location = turn(location,'left')
    end
    return location
end



local function move(location,destiny,mine)
    print(mine)
    local destiny = tonumber(destiny)
    if destiny==3 then
        while mine do
            local state,datatable = turtle.inspectUp()
            if type(datatable.tags)=="nil" or state==false then
                break
            elseif datatable.tags[ "minecraft:replaceable" ]==true then
                break
            else
                turtle.digUp()
                os.sleep(0.5)
            end
        end
        turtle.up()
        location[1][2]=location[1][2]+1
    elseif destiny==-3 then
        while mine do
            local state,datatable = turtle.inspectDown()
            if type(datatable.tags)=="nil" or state==false then
                break
            elseif datatable.tags[ "minecraft:replaceable" ]==true then
                break
            else
                turtle.digDown()
                os.sleep(0.5)
            end
        end
        turtle.down()
        location[1][2]=location[1][2]-1
    else
        location = turnTo(location,destiny)
        if destiny==1 then
            location[1][1]=location[1][1]+1
        elseif destiny==-1 then
            location[1][1]=location[1][1]-1
        elseif destiny==0 then
            location[1][3]=location[1][3]+1
        else
            location[1][3]=location[1][3]-1
        end
        while mine do
            local state,datatable = turtle.inspect()
            if type(datatable.tags)=="nil" or state==false then
                break
            elseif datatable.tags[ "minecraft:replaceable" ]==true then
                break
            else
                turtle.dig()
                os.sleep(0.5)
            end
        end
        turtle.forward()
    end
    writeFile(locationFile,location)
    return location
end



local function findAction(name)
    local actionData = readFile(actionFile)
    local found=false
    local action={}
    for index, value in ipairs(actionData) do
        if value[1]==name then
            found=true
        elseif found==true then
            if value[1]=='end' then
                break
            else
                table.insert(action,value)
            end
        end
    end
    if found then
        return action
    else
        return found
    end
end


local function editAction(name,actionList)
    local actionData = readFile(actionFile)
    local found=0
    local before = {}
    local after = {}


    for index, value in ipairs(actionData) do
        if value[1]==name and found==0 then
            found=1
        elseif value[1]=='end' and found==1 then
            found=2
        else
            if found==0 then
                table.insert(before,value)
            elseif found==2 then
                table.insert(after,value)
            end
        end
    end


    local main = {}
    if before~={} then
        for index, value in ipairs(before) do
            table.insert(main,value)
        end
    end
    if actionList~={} then
        for index, value in ipairs(actionList) do
            table.insert(main,value)
        end
    end
    if after~={} then
        for index, value in ipairs(after) do
            table.insert(main,value)
        end
    end
    writeFile(actionFile,main)
end



local function newAction(action)
    local fileData={}
    for index, value in ipairs(action) do
        table.insert(value)
    end
    for index, value in ipairs(readFile(actionFile)) do
        table.insert(value)
    end
    writeFile(fileData)
end



local function goTo()
    location = readFile(locationFile)
    local action = {'move'}
    for index, value in ipairs(findAction('move')) do
        table.insert(action,value)
    end
    while action[2]~="end" do
        location=move(location,action[2][2],true)
        if action[2][1]<=1 then
            table.remove(action,2)
        else
            action[2][1]=action[2][1]-1
        end
        if action[#action] ~= 'end' then
            table.insert(action,'end')
        end
        editAction('move',action)
    end
    writeFile(locationFile,location)
    editAction('move',{})
end



local function goToPath(location,destiny)--{1x,1y,1z},{2x,2y,2z}
    local distance = {0,0,0}

    local path={'move'}

    for index, value in ipairs(location[1]) do
        distance[index]=destiny[index]-value
    end


    if distance[2]<0 then
        table.insert(path,{distance[2]*(-1),-3})
    elseif distance[2]>0 then
        table.insert(path,{distance[2],3})
    end


    if distance[1]<0 then
        table.insert(path,{distance[1]*(-1),-1})
    elseif distance[1]>0 then
        table.insert(path,{distance[1],1})
    end


    if distance[3]<0 then
        table.insert(path,{distance[3]*(-1),2})
    elseif distance[3]>0 then
        table.insert(path,{distance[3],0})
    end
    

    table.insert(path,'end')
    if path[2]~='end' then
        newAction(path)
        goTo()
    end
end






local function mineSpiral(center,step)
    local action={'mineSpiral'}
    table.insert(action,center)
    table.insert(action,step)
    local x=center[1]
    local z=center[3]
    local rotation = 1

    if step%2==0 then
        rotation=-1
    end

    if step>1 then
        z=center[3]+(4*(math.floor((step-1)/2)*(-rotation)))
    end

    x=center[1]+(4*(math.floor(step/2)*rotation))

    table.insert( action,{x,center[2],z})

    z=center[3]+(4*(math.floor(step/2)*rotation))


    table.insert( action,{x,center[2],z})
    table.insert(action,'end')

    if findAction('mineSpiral')==false then
        newAction(action)
    else
        editAction('mineSpiral',action)
    end
end



local function blockLocation(location)
    local blockLocation={0,0,0}
    local destiny=location[2][1]
    if destiny==3 then
        blockLocation[2]=location[1][2]+1
    elseif destiny==-3 then
        blockLocation[2]=location[1][2]-1
    else
        location = turnTo(location,destiny)
        if destiny==1 or destiny==-1 then
            blockLocation[1]=location[1][1]+destiny
        elseif destiny==0 then
            blockLocation[3]=location[1][3]+1
        else
            blockLocation[3]=location[1][3]-1
        end
    end
    return blockLocation
end



local function excavate(location)
    local scanned={location}
    for i = 1,4, 1 do
        location=turn(location,'left')
        local success, data = turtle.inspect()
        if success then
            if type(data.tags)~="nil" then
                local blockLocation=blockLocation(location)
                table.insert(blockLocation,data.name)
            end
        end
    end
    local success, data = turtle.inspectUp()
    if success then
        if type(data.tags)~="nil" then
            table.insert({location[1][1],location[1][2]+1,location[1][3]},data.name)
        end
    end
    local success, data = turtle.inspect()
    if success then
        if type(data.tags)~="nil" then
            table.insert({location[1][1],location[1][2]-1,location[1][3]},data.name)
        end
    end
end







if not fileExists(locationFile) or type(readFile(locationFile)[1])=='nil' then
    writeFile(locationFile,location)
else
    location = readFile(locationFile)
end


if not fileExists(directiveFile) or type(readFile(directiveFile)[1])=='nil' then
    writeFile(directiveFile,directive)
else
    directive = readFile(directiveFile)
end


if not fileExists(actionFile) then
    writeFile(actionFile,action)
else
    action=readFile(actionFile)
    if action[1]=='move' then
        goTo()
    end
end


refuel()
--goToPath(location,{2,0,2})
local steam=0
while turtle.getFuelLevel()>turtle.getFuelLimit()/2 do
    steam=steam+1
    location = readFile(locationFile)
    if findAction('mineSpiral')==false then
        mineSpiral(location[1],steam)
    else
        mineSpiral(findAction('mineSpiral')[1],steam)
    end
    if findAction('mineSpiral') then
        local coords  = findAction('mineSpiral')[3]
        goToPath(location,coords)
        local coords  = findAction('mineSpiral')[4]
        goToPath(location,coords)
    end
    if steam>20 then
        break
    end
end
--]]
--[[
local state,datatable = turtle.inspect()
if datatable.tags and datatable.tags[ "minecraft:replaceable" ] then
    print()
end
writeFile('testData.txt',{state,textutils.serialise(datatable)})
--]]
