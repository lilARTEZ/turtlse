local locationFile='Location.txt'
local directiveFile='directive.txt'
local actionFile='action.txt'
local stowageFile='stowage.txt'
local memoryFile = 'memory.txt'
local structureFile = '/structures/'
local commandsFile = 'commands.txt'
local manualOverrideFile = 'manualOverride.txt'
local mainGitFile = 'https://github.com/lilARTEZ/turtlse/raw/main/Main_turtle.lua'
local commandsGitFile = 'https://raw.githubusercontent.com/lilARTEZ/turtlse/refs/heads/main/commands.txt'

Location={{0,0,0},{0,' - facing Z'},{nil,' - bedrockLevel'},{1000,' - fuelcap'}}
local directive={{"Inquisitor"},{"start"},{0,0,0,' - hive home'},{0}}
local action={}
local avoidedBlocks={"computercraft:turtle","forge:chests"}
local blockTags={{"minecraft:logs",{'minecraft:oak_log'}},{"minecraft:sand",{}},{"forge:ores",{}},{"minecraft:bedrock",{"minecraft:bedrock"}},{'minecraft:stone',{"minecraft:stone","minecraft:andesite"}}}
local surfaceTags={"minecraft:sand","minecraft:logs"}
local blockNames={"minecraft:stone"}
local stowage = {}
local memory={"locations",{0,0,0,'home'},"end"}
local commands={}
local manualOverride = {}


local minerProgramGitFile = 'https://raw.githubusercontent.com/lilARTEZ/turtlse/refs/heads/main/miner.lua'

--[[

For storage item info there should be a request for materials to main computer, and then get the location back
same for structures, and locations in memory, to only be the ones necesary for the turtle.

//////
Broken/to be tested:
Crafting
harvesting surface materials

///////
To do:
surface mapping

]]


local function RunProtected(func, ...)-- Function to run tasks safely
    local success, result = pcall(func, ...)
    if not success then
        print("Error running function:", result)
        return nil
    end
    return result
end



local function RunMultipleProtected(taskList, env)-- Function to run multiple tasks safely
    local results = {}
    env = env or _G  -- Default to _G if no env provided

    for i, task in ipairs(taskList) do
        local funcName = task[1]  -- Function name as a string
        local args = {table.unpack(task, 2)}  -- Extract arguments


        local func = env[funcName]  -- Look for the function in the environment

        if type(func) == "function" then
            results[i] = RunProtected(func, table.unpack(args))
        elseif type(func)~="nil" then
            print("Error: Task " .. i .. " is not a valid function!")  -- Error message
            results[i] = nil
        end
    end

    return results
end







local function encodeTable(tablet)
    local data={}
    for index, value in ipairs(tablet) do
        local string=''
        if type(value) == "table" then
            for index, content in ipairs(value) do
                if string=='' then
                    string=content
                else
                    if type(content)=="table" then
                        error('encode table: given too big table matrix: '..content[1]..' '..content[2])
                    end
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
        local strings = {}
        for str in string.gmatch(value,"([^%$]+)") do
            table.insert( strings, str)
        end


        local function getValueOf(str)
            if tonumber(str)==nil then
                if tostring(str)~=nil then
                   if str=='false' then
                        return false
                   elseif str=='true' then
                        return true
                   else
                        return tostring(str)
                   end
                else
                    return str
                end
            else
                return tonumber(str)
            end
        end



        if #strings>1 then
            for index, str in ipairs(strings) do
                table.insert( line, getValueOf(str))
            end
            table.insert(tableLines,line)
        else
            table.insert(tableLines,getValueOf(strings[1]))
        end
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
    --term.clear()
    --print('write: ',path)
    --print('data: ',table.unpack(data),'\n')
    for index, value in ipairs(data) do
        --print(type(value))
    end
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


local function copyFile(source, destination)
    local inputFile = io.open(source, "r")
    if not inputFile then
        error("Could not open source file: " .. source)
    end

    local outputFile = io.open(destination, "w")
    if not outputFile then
        inputFile:close()
        error("Could not open destination file: " .. destination)
    end

    for line in inputFile:lines() do
        outputFile:write(line .. "\n")
    end

    inputFile:close()
    outputFile:close()
end


local function findInMemory(name)
    local memory = readFile(memoryFile)

    for index, line in ipairs(memory) do
        if type(line)=="table" then
            for index, value in ipairs(line) do
                if value==name then
                    return line
                end
            end
        end
    end
    return false
end



local function editInMemory(name,data)
    local memory = readFile(memoryFile)

    for index1, line in ipairs(memory) do
        if type(line)=="table" then
            for index, value in ipairs(line) do
                if value==name then
                    if type(data)=="table" then
                        table.insert( data,name)
                        memory[index1]=data
                    else
                        memory[index1]={data,name}
                    end
                    writeFile(memoryFile,memory)
                    return true
                end
            end
        end
    end
    return false
end



local function getFuelCap(refuel)
    local refuel = refuel or false
    Location = readFile(locationFile)
    local fuelCap = Location[4][1] or 500


    if refuel~= false then

        if turtle.refuel(0) and turtle.getFuelLevel()<=fuelCap then

            local fuelItem = turtle.getItemCount()
            local fuelLevel = turtle.getFuelLevel()
            turtle.refuel(1)

            fuelItem=fuelItem-1
            
            local usedFuel = (turtle.getFuelLevel()-fuelLevel)/2
            local fuelValue = (((turtle.getFuelLevel()-fuelLevel)*5)/100)*fuelItem



            if turtle.getFuelLevel()+fuelValue>1.2*fuelCap then

                turtle.refuel(math.floor(((fuelCap*1.2)-turtle.getFuelLevel())/(fuelValue/fuelItem)))

                usedFuel=usedFuel+(math.floor(((fuelCap*1.2)-turtle.getFuelLevel())/(fuelValue/fuelItem)))/2
                Location[4][1]=fuelCap+usedFuel
                writeFile(locationFile,Location)
                return true
            else
                turtle.refuel()
                usedFuel=usedFuel+fuelValue/2
                Location[4][1]=fuelCap+usedFuel
                writeFile(locationFile,Location)
                return false
            end
        elseif turtle.getFuelLevel()>=fuelCap then
            return true
        else
            return false
        end
    else
        return fuelCap
    end
end



local function refuel(start)
    local start = start or false
    while true do
        for i = 1, 16, 1 do
            term.clear()
            print('Refueling: '..turtle.getFuelLevel()..' / '..getFuelCap())
            turtle.select(i)
            if getFuelCap(true) then
                turtle.select(1)
                term.clear()
                print('Done refueling, current fuel level: '..turtle.getFuelLevel()..' / '..getFuelCap())
                return true
            end
        end
        if start~=true then
            return false
        end
        term.clear()
        print('Failed to refuel, please insert more fuel: '..turtle.getFuelLevel()..' / '..getFuelCap())
        os.sleep(2) 
    end
end



local function turn(direction,Location)--turns in provided str direction ('left','right','back'),Location optional 

    Location = Location or readFile(locationFile)
    if Location[2]==nil then
        Location=readFile(locationFile)
    end
    local facing=Location[2][1]

    if facing==-2 then
        facing=2
    end

    if direction=='left' then
        facing=facing-1
        if facing==-2 then
            facing=2
        end
        turtle.turnLeft()
    elseif direction=='right' then
        facing=facing+1
        if facing==3 then
            facing=-1
        end
        turtle.turnRight()
    elseif direction=='back' then
        facing=facing+2
        if facing==3 then
            facing=-1
        elseif facing==4 then
            facing=0
        end
        turtle.turnRight()
        turtle.turnRight()
    else
        return false
    end


    if facing==0 then
        Location[2]={facing,' - facing Z'}
    elseif facing==1 then
        Location[2]={facing,' - facing X'}
    elseif facing==-1 then
        Location[2]={facing,' - facing -X'}
    else
        Location[2]={facing,' - facing -Z'}
    end

    writeFile(locationFile,Location)
    return Location
end



local function turnTo(direction)--turns to number direction
    Location=readFile(locationFile)
    if type(direction)~="number" then
        error('turnTo() called with nill direction')
    end
    if math.sqrt(direction^2)==2 then
        direction=2
    end
    if math.sqrt(Location[2][1]^2)==2 then
        Location[2][1]=2
    end
    while Location[2][1]~=direction do
        if (Location[2][1]==2 and direction==-1) or (direction>Location[2][1]) then
            Location = turn('right',Location)
        else
            Location = turn('left',Location)
        end
    end
    writeFile(locationFile,Location)
    return Location
end



local function blockLocation(Location)
    local blockLocation={Location[1][1],Location[1][2],Location[1][3]}
    local destiny=Location[2][1]
    if destiny==3 then
        blockLocation[2]=Location[1][2]+1
    elseif destiny==-3 then
        blockLocation[2]=Location[1][2]-1
    else
        if destiny==1 or destiny==-1 then
            blockLocation[1]=Location[1][1]+destiny
        elseif destiny==0 then
            blockLocation[3]=Location[1][3]+1
        else
            blockLocation[3]=Location[1][3]-1
        end
    end
    return blockLocation
end



local function scan(mode,bable)--(what to can:'up'or'all'..,what to look for'avoid'or'ores'..)---{ { {blockLocation(x,y,z)} ,blockTag, if Turtle facing direction},...{} }
    bable = bable or 'ores'
    local tags = {}
    if bable=='avoid' then
        tags=avoidedBlocks
    elseif bable=='ores' then
        tags={{"forge:ores"}}
    elseif bable=='bedrock' then
        tags={{"minecraft:bedrock"}}
    elseif bable=='surface' then
        tags=surfaceTags
    else
        tags=blockTags
    end
    local scanned={}

    if mode=="forward" then
        local success, data = turtle.inspect()
        if success then
            if type(data.tags)~="nil" then
                for index, value in ipairs(tags) do
                    if data.tags[value[1]] then
                        Location = readFile(locationFile)
                        local blockLocation=blockLocation(Location)
                        if data.tags[ "computercraft:turtle" ] then
                            table.insert(scanned,{blockLocation,value[1],data.state.facing})
                        else
                            table.insert(scanned,{blockLocation,value[1]})
                        end
                        break
                    end
                end
            end
        end
    end


    if mode=="around" or mode=='all' then
        for i = 1,4, 1 do
            Location=turn('left') or Location
            local success, data = turtle.inspect()
            if success then
                if type(data.tags)~="nil" then
                    for index, value in ipairs(tags) do
                        if data.tags[value[1]] then
                            Location = readFile(locationFile)
                            local blockLocation=blockLocation(Location)
                            if data.tags[ "computercraft:turtle" ] then
                                table.insert(scanned,{blockLocation,value[1],data.state.facing})
                            else
                                table.insert(scanned,{blockLocation,value[1]})
                            end
                            break
                        end
                    end
                end
            end
        end
    end


    if mode=="up" or mode=='all' then
        local success, data = turtle.inspectUp()
        if success then
            if type(data.tags)~="nil" then
                for index, value in ipairs(tags) do
                    if data.tags[value[1]] then
                        Location = readFile(locationFile)
                        if data.tags[ "computercraft:turtle" ] then
                            table.insert(scanned,{{Location[1][1],Location[1][2]+1,Location[1][3]},value[1],data.state.facing})
                        else
                            table.insert(scanned,{{Location[1][1],Location[1][2]+1,Location[1][3]},value[1]})
                        end
                        break
                    end
                end
            end
        end
    end


    if mode=="down" or mode=='all' then
        local success, data = turtle.inspectDown()
        if success then
            if type(data.tags)~="nil" then
                for index, value in ipairs(tags) do
                    if data.tags[value[1]] then
                        Location = readFile(locationFile)
                        if data.tags[ "computercraft:turtle" ] then
                            table.insert(scanned,{{Location[1][1],Location[1][2]-1,Location[1][3]},value[1],data.state.facing})
                        else
                            table.insert(scanned,{{Location[1][1],Location[1][2]-1,Location[1][3]},value[1]})
                        end
                        break
                    end
                end
            end
        end
    end


    return scanned
end



local function addToLocation(Location,destiny)
    if destiny==1 then
        Location[1][1]=Location[1][1]+1
    elseif destiny==-1 then
        Location[1][1]=Location[1][1]-1
    elseif destiny==0 then
        Location[1][3]=Location[1][3]+1
    elseif destiny==2 then
        Location[1][3]=Location[1][3]-1
    elseif destiny==3 then
        Location[1][2]=Location[1][2]+1
    else
        Location[1][2]=Location[1][2]-1
    end
    return Location
end


local function turnFromLocation(destiny,direction)
    if math.sqrt(destiny^2)==2 then
        destiny=2
    end
    if direction=='right' then
        destiny=destiny+1
        if destiny>2 then
            destiny=-1
        end
    else
        destiny=destiny-1
        if destiny==-2 then
            destiny=2
        end
    end
    return destiny
end



local function getDirection(destiny)
    Location = readFile(locationFile)
    local distance = {0,0,0}
    local path={}
    
    for index, value in ipairs(Location[1]) do
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

    return path
end




local function move(destiny,mine,returnHome)

    returnHome = returnHome or false
    Location = readFile(locationFile)
    local mine = mine or false
    local destiny = tonumber(destiny)

    if returnHome==false then

        local home = findInMemory('home')
        local distance = math.sqrt( (home[1]-Location[1][1])^2+(home[2]-Location[1][2])^2+(home[3]-Location[1][3])^2 )

        if distance>=turtle.getFuelLevel()-20 then
            if refuel()==false then
                error('Turtle has no more fuel, turtle returning to home location')
            end
        end
    end



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
        Location[1][2]=Location[1][2]+1
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
        Location[1][2]=Location[1][2]-1
    else
        turnTo(destiny)
        Location = readFile(locationFile)
        Location = addToLocation(Location,destiny)
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
    writeFile(locationFile,Location)
    return Location
end



local function findData(fileName,name)--looks for single name, and writes table til 'end'
    local actionData = readFile(fileName)
    local found=false
    local action={}
    for index, value in ipairs(actionData) do
        if value==name then
            found=true
            table.insert(action,value)
        elseif found==true then
            if value=='end' then
                table.insert(action,value)
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


local function editData(fileName,name,actionList)
    local actionData = readFile(fileName)
    local found=0
    local before = {}
    local after = {}

    for index, value in ipairs(actionData) do
        if value==name and found==0 then
            found=1
        elseif value=='end' and found==1 then
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
    writeFile(fileName,main)
end



local function newData(fileName,data)
    local fileData={}
    for index, value in ipairs(data) do
        table.insert(fileData,value)
    end
    for index, value in ipairs(readFile(fileName)) do
        table.insert(fileData,value)
    end
    writeFile(fileName,fileData)
end



local function findInTag(item,tagName)
    for index, tag in ipairs(blockTags) do

        if tagName==tag[1] then
            local taggedBlocks=tag[2]
            for index, name in ipairs(taggedBlocks) do
                if item==name then
                    return true
                end
            end
        end
    end
    return false
end



local function isBlockTag(item)
    for index, tag in ipairs(blockTags) do

        if item==tag[1] then
            return true
        end
    end
    return false
end



local function checkStowage(stowageID,item)--{{slot,item.name,item.count,item.damage}}==stowageData if no stowageID {stowageID,stowageData}
    local stowageID = stowageID or nil
    local item = item or nil
    local stowageData={}

    if stowageID~=nil then
        stowageID=tonumber(stowageID)

        local stowage=findData(stowageFile,stowageID)--{{stowageID,Location,{slot,item.name,item.count,item.damage},"end"}}

        table.remove( stowage,1 )
        for index, value in ipairs(stowage) do
            if value[1]=='end' then
                break
            end
            if item~=nil then
                if type(item)=="table" then
                    for index, name in ipairs(item) do
                        if value[2]==name then

                            table.insert( stowageData, value )
                            break
                        end
                    end
                else
                    if value[2]==item then
                        table.insert( stowageData, value )
                    end
                end
            else
                table.insert( stowageData, value )
            end
        end


    else
        local stowage=readFile(stowageFile)
        for index, value in ipairs(stowage) do
            if type(value[2])=='nil' and value[1]~='end' then
                table.insert( stowageData, findData(stowageFile,value[1]) )
            end
        end

        stowage=stowageData
        stowageData={}


        for index, value in ipairs(stowage) do
            local stowageID = value[1]
            table.remove( value,1 )
            table.remove( value,1 )
            for index, value in ipairs(value) do
                if value[1]=='end' then
                    break
                end
                if item~=nil then
                    if type(item)=="table" then
                        for index, name in ipairs(item) do
                            if value[2]==item then
                                table.insert( stowageData, {stowageID,value} )
                                break
                            end
                        end
                    else
                        if value[2]==item then
                            table.insert( stowageData, {stowageID,value} )
                        end
                    end
                else
                    table.insert( stowageData, {stowageID,value} )
                end
            end
        end
    end
    return stowageData
end



local function checkInventory(item)--item == str or int  returns {item.name,item.count,item.damage} or {item count,{id's}} if no item return {{ID,item.name,item.count,item.damage}}
    local inventory={}
    local slot = false
    if type(item)=="number" then
        slot = item
    end


    if slot~=false then
        local item=turtle.getItemDetail(slot)
        return {item.name,item.count,item.damage}
    else
        for i = 1, 16, 1 do
            local item=turtle.getItemDetail(i)
            if item ~= nil then
                table.insert( inventory,{i,item.name,item.count,item.damage} )
            end
        end
    end


    if item~=nil then
        local items={0,{}}



        for index, value in ipairs(inventory) do
            if type(item)=="table" then
                for index, name in ipairs(item) do
                    if  isBlockTag(name) then
                        if findInTag(value[2],name) then
                            items[1]=items[1]+value[3]
                            table.insert( items[2],value[1])
                        end
                    elseif value[2]==name then
                        items[1]=items[1]+value[3]
                        table.insert( items[2],value[1])
                    end
                end
            else
                if  isBlockTag(item)==true then
                    if findInTag(value[2],item) then
                        items[1]=items[1]+value[3]
                        table.insert( items[2],value[1])
                    end
                elseif value[2]==item then
                    items[1]=items[1]+value[3]
                    table.insert( items[2],value[1])
                end
            end
        end

        return items
    else
        return inventory
    end
end



local function manageInventory(mode)--"mining" for iron redstone coal, stone and diamond
    local mode = mode or 'all'
    local reservedSlots={}

    if type(mode)=="table" then
        
    else
        if mode=="mining" then--{'tag or name',number of reserved slots or 0 for no limit}, location in table dictates priority of the item
            reservedSlots={{'fuel',0},{'minecraft:raw_iron',1},{'minecraft:redstone',1},{'minecraft:diamond',0},{'minecraft:stone',1}}
        elseif mode=="gathering" then
            reservedSlots={{'fuel',0},{'minecraft:raw_iron',1},{'minecraft:redstone',1},{'minecraft:diamond',1},{'minecraft:stone',1}}
        else
            reservedSlots={{'fuel',0},{'minecraft:raw_iron',1},{'minecraft:redstone',1},{'minecraft:diamond',0},{'minecraft:stone',1}}
        end
    end


    local inventory = checkInventory(nil)
    local order={}
    local orderless = {}
    for index, item in ipairs(inventory) do
        local found = false
        for priority, value in ipairs(reservedSlots) do
            for tagIndex, tags in ipairs(blockTags) do
                if value[1]==tags[1] then
                    for blockIndex, blockName in ipairs(tags[2]) do
                        if item[2]==blockName then
                            table.insert( order,{priority,index} )
                            found=true
                            break
                        end
                    end
                end
                if found then
                    break
                end
            end
            if item[2]==value[1] then
                found=true
                table.insert( order,{priority,index} )
                break
            end
            if found then
                break
            end
        end
        if found==false then
            table.insert( orderless,index)
        end
    end

    for index, value in ipairs(order) do
        if index>1 then
            for i = 1, index, 1 do
                if value[1]<order[i][1] then
                    local toOrder={value}
                    table.remove( order,value )
                    for index, value in ipairs(order) do
                        table.insert( toOrder,value )
                    end
                    order=toOrder
                end
            end
        end
    end


    local fulness=#order
    local sameBlocks={}
    local sameID=0
    for orderIndex, orderValue in ipairs(order) do
        if orderValue[1]==sameID then
            table.insert( sameBlocks,orderValue )
        else
            if sameBlocks[1]~=nil then

                local limit=reservedSlots[sameID][2]
                if limit>0 then

                    for index, value in ipairs(sameBlocks) do
                        limit=limit-1
                        local stackLeft=turtle.getItemSpace(inventory[value[2]][1])

                        if stackLeft>0 then
                            for i = index+1, #sameBlocks, 1 do
                                if inventory[value[2]][2]==reservedSlots[sameBlocks[i][1]][1] then
                                    if turtle.getItemSpace(inventory[sameBlocks[i][2]][1]) > stackLeft then
                                        turtle.select(inventory[sameBlocks[i][2]][1])
                                        turtle.transferTo(inventory[value[2]][1],stackLeft)
                                        stackLeft=0
                                    else
                                        turtle.select(inventory[sameBlocks[i][2]][1])
                                        turtle.transferTo(inventory[value[2]][1])
                                        table.remove( order,orderIndex)
                                        fulness=fulness-1
                                        table.remove( sameBlocks,i)
                                        stackLeft=turtle.getItemSpace(inventory[value[2]][1])
                                        inventory = checkInventory(nil)
                                    end
                                end

                                if stackLeft<=0 then
                                    break
                                end
                            end
                        end
                        if limit<=0 then
                            local toOrder={orderValue}
                            table.remove( order,orderIndex )
                            for index, value in ipairs(orderless) do
                                table.insert( toOrder,value )
                            end
                            orderless=toOrder
                        end
                    end
                end
            end
        end
    end


    for i = 1, 16, 1 do
        if i==16 then
            turtle.select(16)
            turtle.dropDown()
        else
            if i<=#order then
                turtle.select(inventory[order[2]][1])
                turtle.transferTo(i)
            elseif i<=#order+#orderless then
                local id = orderless[1]
                if orderless[2]~=nil then
                    id=orderless[2]
                end
                turtle.select(inventory[id][1])
                turtle.transferTo(i)
            end
        end
    end
    if fulness>=15 then
        return false
    end
    return true
end



local function decodeCraftingPattern(encodedPattern,materials)
    if type(materials)~= "table" then
        materials={materials}
    end
    local pattern={}
    for i = 1, #encodedPattern do
        local character = encodedPattern:sub(i,i)
        if tonumber(character)==0 then
            table.insert( pattern,nil )
        else
            table.insert( pattern,materials[tonumber(character)][1] )
        end
    end

    for i = 1, 9-#encodedPattern do
        table.insert( pattern,nil )
    end
    return pattern
end



local function craftingRecipe(name)
    local recipes = {}

    if name=='minecraft:planks' then

        local materials={{'minecraft:logs',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('1',materials)})


    elseif name=='minecraft:chest' then

        local materials={{'minecraft:planks',8}}
        table.insert( recipes, {materials,decodeCraftingPattern('111101111',materials)})


    elseif name=='minecraft:iron_ingot' then

        local materials={{'minecraft:iron_nugget',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})
        local materials={{'minecraft:iron_block',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('1',materials)})
        table.insert( recipes, {{{'minecraft:raw_iron',1}},'smelt'})


    elseif name=='computerCraft:disk_drive' then

        local materials={{'minecraft:stone',7},{'minecraft:redstone',2}}
        table.insert( recipes, {materials,decodeCraftingPattern('111121121',materials)})


    elseif name=='computerCraft:floppy_disk' then

        local materials={{'minecraft:redstone',1},{'minecraft:paper',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('010020',materials)})


    elseif name=='computerCraft:computer' then

        local materials={{'minecraft:stone',7},{'minecraft:redstone',1},{'minecraft:glass_pane',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('111121131',materials)})


    elseif name=='computerCraft:turtle' then

        local materials={{'minecraft:iron_ingot',7},{'computerCraft:computer',1},{'minecraft:chest',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('111121131',materials)})


    elseif name=='minecraft:glass_pane' then

        local materials={{'minecraft:glass',6}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111',materials)})


    elseif name=='minecraft:glass' then

        local materials={{'minecraft:sand',1}}
        table.insert( recipes, {materials,'smelt'})


    elseif name=='minecraft:paper' then

        local materials={{'minecraft:sugar_cane',3}}
        table.insert( recipes, {materials,decodeCraftingPattern('111',materials)})


    elseif name=='minecraft:charcoal' then

        local materials={{'minecraft:logs',1}}
        table.insert( recipes, {materials,'smelt'})


    elseif name=='minecraft:hopper' then

        local materials={{'minecraft:iron_ingot',5},{'minecraft:chest',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('10112101',materials)})

        
    elseif name=='minecraft:bucket' then

        local materials={{'minecraft:iron_ingot',3}}
        table.insert( recipes, {materials,decodeCraftingPattern('101010',materials)})

       
    elseif name=='minecraft:diamond_pickaxe' then

        local materials={{'minecraft:diamond',3},{'minecraft:stick',2}}
        table.insert( recipes, {materials,decodeCraftingPattern('111020020',materials)})


    elseif name=='minecraft:diamond_hoe' then

        local materials={{'minecraft:diamond',2},{'minecraft:stick',2}}
        table.insert( recipes, {materials,decodeCraftingPattern('110020020',materials)})


    elseif name=='minecraft:crafting_table' then

        local materials={{'minecraft:planks',4}}
        table.insert( recipes, {materials,decodeCraftingPattern('110110',materials)})


    elseif name=='minecraft:stick' then

        local materials={{'minecraft:planks',2}}
        table.insert( recipes, {materials,decodeCraftingPattern('100100',materials)})


    elseif name=='minecraft:stone' then

        local materials={{'minecraft:cobblestone',1}}
        table.insert( recipes, {materials,'smelt'})


    elseif name=='minecraft:furnace' then

        local materials={{'minecraft:cobblestone',8}}
        table.insert( recipes, {materials,decodeCraftingPattern('111101111',materials)})


    elseif name=='minecraft:sign' then

        local materials={{'minecraft:planks',6},{'minecraft:stick',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111020',materials)})


    elseif name=='minecraft:diamond' then

        local materials={{'minecraft:diamond_block',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('1',materials)})


    elseif name=='minecraft:coal' then

        local materials={{'minecraft:coal_block',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('1',materials)})


    elseif name=='minecraft:gold_ingot' then

        local materials={{'minecraft:gold_block',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('1',materials)})
        local materials={{'minecraft:gold_nugget',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})
        local materials={{'minecraft:raw_gold',1}}
        table.insert( recipes, {materials,'smelt'})


    elseif name=='minecraft:copper_ingot' then

        local materials={{'minecraft:copper_block',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('1',materials)})
        local materials={{'minecraft:copper_nugget',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})
        local materials={{'minecraft:raw_copper',1}}
        table.insert( recipes, {materials,'smelt'})


    elseif name=='minecraft:emerald' then

        local materials={{'minecraft:emerald_block',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('1',materials)})


    elseif name=='minecraft:lapis_lazuli' then

        local materials={{'minecraft:lapis_lazuli_block',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('1',materials)})


    elseif name=='minecraft:coal_block' then

        local materials={{'minecraft:coal',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})


    elseif name=='minecraft:copper_block' then

        local materials={{'minecraft:copper_ingot',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})


    elseif name=='minecraft:lapis_lazuli_block' then

        local materials={{'minecraft:lapis_lazuli',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})


    elseif name=='minecraft:iron_block' then

        local materials={{'minecraft:iron_ingot',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})


    elseif name=='minecraft:gold_block' then

        local materials={{'minecraft:gold_ingot',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})


    elseif name=='minecraft:diamond_block' then

        local materials={{'minecraft:diamond',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})


    elseif name=='minecraft:emerald_block' then

        local materials={{'minecraft:emerald',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})


    elseif name=='minecraft:redstone_block' then

        local materials={{'minecraft:redstone',9}}
        table.insert( recipes, {materials,decodeCraftingPattern('111111111',materials)})


    elseif name=='minecraft:redstone' then

        local materials={{'minecraft:redstone_block',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('1',materials)})


    elseif name=='minecraft:diamond_sword' then

        local materials={{'minecraft:diamond',2},{'minecraft:stick',1}}
        table.insert( recipes, {materials,decodeCraftingPattern('010010020',materials)})


    else
        return false
    end
    return recipes
end



local function getMaterialQuantity(material,searchStorage)--if searchStorage = true search all storage or int for single or list of int

    searchStorage=searchStorage or false

    local function searchStorageByNumber(searchStorage,material)
        local stowage = checkStowage(searchStorage,material[1])
        local itemCount = 0
        local stowageItems = {}--{item slots}

        for index, value in ipairs(stowage) do
            itemCount=itemCount+tonumber(value[3])
            table.insert( stowageItems, value[1] )
        end


        return {itemCount,stowageItems}--{count,{ID's}}

    end



    if type(searchStorage)=='number' then

        return searchStorageByNumber(searchStorage,material)--{count,{ID's}}

    elseif searchStorage==true then

        local stowage = checkStowage(nil,material[1])
        local stowageItemCount=0
        local stowageItemData={}

        for index, value in ipairs(stowage) do

            local itemCount = 0
            local itemID = {}

            for index, value in ipairs(value[2]) do

                itemCount=itemCount+value[3]
                table.insert(itemID,value[1])

            end
            
            stowageItemCount=stowageItemCount+itemCount
            table.insert( stowageItemData,{value[1],itemCount,itemID} )

        end


        return {stowageItemCount,stowageItemData}--{total Count,{{StowageID,count,{ID's}}}}

    elseif type(searchStorage)=="table" then
        
        local storageTotal=0
        local totalStorageStatus={}

        for index, value in ipairs(searchStorage) do
            
            local storageStatus = searchStorageByNumber(value,material)

            if storageStatus[1]>0 then

                storageTotal=storageTotal+storageStatus[1]
                table.insert(totalStorageStatus,storageStatus)

            end

        end

        return {storageTotal,totalStorageStatus}--{total Count,{{count,{ID's}}}}

    else
        return checkInventory(material)--{item count,{id's}}
    end
end



local function getBuildingStorage(buildingID)--{{id,pos,{contents}}} content={item.slot/ID,item.name,item.count,item.damage}
    local buildingStorageData = findData(structureFile..buildingID..".txt",'storage')


    local buildingStorageContent={}
    local chestID=nil
    local chestPosition={}
    local chestContent={}

    for index, line in ipairs(buildingStorageData) do
        if line[2]==nil and line[1]~='end' then
            if chestContent[1]~=nil then
                table.insert(buildingStorageContent,{chestID,chestPosition,chestContent})--{id,pos,{contents}}
            end
            chestID=line[1]
        elseif tonumber(line[1])~=nil then
            chestPosition=line
        else
            table.insert(chestContent,line)
        end
    end

    return buildingStorageContent

end



local function getMaterialQuantityByBuilding(buildingID,material)

    local buildingStorageContent = getBuildingStorage(buildingID)
    local totalMaterialQuantity
    local storedMaterials = {totalMaterialQuantity}

    for index, chestContent in ipairs(buildingStorageContent) do

        local chestMaterialQuantity = 0
        local materialID={}

        for index, item in ipairs(chestContent[3]) do
            if item[2]==material then
                chestMaterialQuantity=chestMaterialQuantity+item[3]
                table.insert(materialID,item[1])
            end
        end

        if chestMaterialQuantity>0 then
            totalMaterialQuantity=totalMaterialQuantity+chestMaterialQuantity
            table.insert(storedMaterials,{chestContent[1],chestContent[2],chestMaterialQuantity,{}})
        end

    end

    return {totalMaterialQuantity,storedMaterials}

end



local function moveItemInInventory(destiny,item,quantity,forbiddenSlotList)-- move quatitiy of items into a single slot in inventory except forbiddenSlotList
    quantity=quantity or 1
    forbiddenSlotList=forbiddenSlotList or {}

    if type(destiny)=="number" then
        local itemData = checkInventory(item)
        local itemQuantity = itemData[1]
        local itemLocations = itemData[2]

        if itemQuantity<quantity then
            print('couldn\'t find enough '..item..' lacking '..quantity-itemQuantity)
            return false
        end

        for index, Location in ipairs(itemLocations) do
            for index2, forbiddenSlot in ipairs(forbiddenSlotList) do
                if Location==forbiddenSlot then
                    table.remove( itemLocations,index )
                    table.remove( forbiddenSlotList,index2 )
                end
            end
        end

        for index, value in ipairs(itemLocations) do
            turtle.select(value)
            if turtle.getItemCount(value)>quantity then
                turtle.transferTo(destiny,quantity)
                quantity=0
                break
            else
                quantity=quantity-turtle.getItemCount(value)
                turtle.transferTo(destiny,quantity)
            end
        end

        if quantity>0 then
            return false
        else
            return true
        end
    end
end



local function moveItemIntoChest(itemSlot,recievingChest,quantity)--recievingChest=('front','back'...)

    recievingChest = recievingChest or 'front'
    quantity = quantity or 64

    Location = Location or readFile(locationFile)
    local facing=Location[2][1]

    if recievingChest ~= 'front' then
        turn(recievingChest)
    end

    turtle.select(itemSlot)

    if recievingChest=='top' then
        turtle.dropUp(quantity)
    elseif recievingChest=='bottom' then
        turtle.dropDown(quantity)
    else
        turtle.drop(quantity)
    end
end



local function emptyInventoryTo(storage_name)--storage_name=('front','back'...)

    Location = Location or readFile(locationFile)
    local facing=Location[2][1]

    turn(storage_name)

    for i = 1, 16, 1 do

        turtle.select(i)

        if storage_name=='top' then
            turtle.dropUp(64)
        elseif storage_name=='bottom' then
            turtle.dropDown(64)
        else
            turtle.drop(64)
        end
    end
end



local function suckAllFromChest(storage_name)--storage_name=('front','back'...)

    turn(storage_name)
    local size = peripheral.call(storage_name,'size')

    for i = 1, size, 1 do
        if storage_name=='top' then
            turtle.suckUp(64)
        elseif storage_name=='bottom' then
            turtle.suckDown(64)
        else
            turtle.suck(64)
        end
    end
end


local function getItemFromNeighbouringChests(item,quantity,destiny,processingChest,providerChests)--transfers items from provider chest into processing chest(on top of the turtle), and sucks into destiny slot

    providerChests=providerChests or {'front','right','left','back','top','bottom'}
    processingChest = processingChest or 'top'
    
    for index, value in ipairs(providerChests) do
        if value==processingChest then
            table.remove(providerChests,index)
        end    
    end
    

    for index, providerChest in ipairs(providerChests) do
        
        if peripheral.isPresent(providerChest) then

            local peripheralName,peripheralType = peripheral.getType(providerChest)

            if peripheralType=='inventory' then

                local list= peripheral.call(providerChest,'list')

                for providerChestItemSlot = 1, peripheral.call(providerChest,'size'), 1 do

                    if type(list[providerChestItemSlot])~="nil" then
                        if list[providerChestItemSlot].name==item then

                            if list[providerChestItemSlot].count>quantity then
                                peripheral.call(providerChest,'pushItems',processingChest,providerChestItemSlot,quantity,1)
                                turtle.select(destiny)
                                turtle.suckUp(quantity)
                            else
                                peripheral.call(providerChest,'pushItems',processingChest,providerChestItemSlot,quantity,1)
                                quantity=quantity-list[providerChestItemSlot].count
                                turtle.select(destiny)
                                turtle.suckUp(quantity)
                            end
                        end
                    end
                    if quantity<=0 then
                        return true
                    end
                end
            end
        end
    end
    return false
end



local function craft(craftings,searchStorage)--takes {{craftingName,quantity}},false - will only search for items in inventory
    local searchStorage = searchStorage or false


    local function getStorageType(searchStorage)
        
        if string.find(searchStorage,'storage')~=nil then
        
        elseif searchStorage then
    
        end
    end


    if type(searchStorage)=="table" then
        for index, storageID in ipairs(searchStorage) do
            
        end
    else

    end


    
    for index, crafting in ipairs(craftings) do

        print('.. a '..crafting[1])
        local name=crafting[1]
        local quantity=crafting[2]

        if name==nil then
            print('Failed to find crafting recipe for: nil name')
            return false
        end

        local recipes = craftingRecipe(name)

        if recipes==false then
            print('Failed to find crafting recipe for: '..name)
            return false
        else
            for index, recipe in ipairs(recipes) do
                local materials = recipe[1]
        
                for index, material in ipairs(materials) do
                    local materialData = getMaterialQuantity(material[1],searchStorage)
                    local materialQuantity = materialData[1]
                    local materialIds = materialData[2]
                    print('material '..materialQuantity)
        
                    if materialQuantity<material[2] then
                        local recipes = craftingRecipe(material[1])
    
                        if recipes~=false then
    
                            for index, value in ipairs(recipes) do
                                local materials = value[1]
                                if materials[1][1]~=name and materials[1][2]~=nil then
                                    if craft({material,material[2]-materialQuantity})==false then
                                        return false
                                    end
                                end
                            end
                        else
                            print('lacking at least '..material[2]-materialQuantity..' '..material[1]..' to craft '..name)
                            return false
                        end
                    else
                        local forbiddenSlotList = {}
                        for index, item in ipairs(recipe[2]) do
                            local slot=(index+math.floor(index/4))
    
    
                            if type(item)~= "nil" then
                                table.insert(forbiddenSlotList,slot)
                                turtle.select(slot)
    
                                if turtle.getItemCount()>0 then
    
    
                                    for index, value in ipairs({4,8,12,13,14,15,16}) do
    
                                        turtle.select(value)
    
    
                                        if turtle.getItemCount()==0 or false or nil then
    
                                            turtle.select(slot)
                                            turtle.transferTo(value,64)
                                            break
                                        end
                                    end
    
                                    turtle.select(slot)
    
    
                                    if turtle.getItemCount()>0 then
                                        moveItemIntoChest(slot,craftingChest)
                                    end
                                end
    
    
                                if checkInventory(item)[1]<quantity then
                                    moveItemInInventory(slot,item,checkInventory(item)[1],forbiddenSlotList)
                                    getItemFromNeighbouringChests(item,quantity,slot,craftingChest,providerChests)
                                else
                                    moveItemInInventory(slot,item,quantity,forbiddenSlotList)
                                end
                            end
                        end
                        for index, item in ipairs(recipe[2]) do
                            local slot=(index+math.floor(index/4))
    
                            if type(item)== "nil" then
                                moveItemIntoChest(slot,craftingChest)
                            end
                        end
                        for index, value in ipairs({4,8,12,13,14,15,16}) do
                            moveItemIntoChest(value,craftingChest)
                        end
                        turtle.craft(quantity)
                    end
                end
            end
        end
    end
end



local function avoidPath(Location,destiny,turtleRotation)
    local path = {'move'}
    if destiny==3 then
        if turtleRotation~=nil then
            if turtleRotation=="west" then
                table.insert(path,{1,0})
            elseif turtleRotation=="east" then
                table.insert(path,{1,2})
            elseif turtleRotation=="north" then
                table.insert(path,{1,-1})
            else
                table.insert(path,{1,1})
            end
        else
            table.insert(path,{1,0})
        end
        table.insert(path,{2,3})
        local target=turnFromLocation(Location[2][1],'left')
        target=turnFromLocation(target,'left')
        table.insert(path,{1,target})
    elseif destiny==-3 then
        if turtleRotation~=nil then
            if turtleRotation=="west" then
                table.insert(path,{1,2})
            elseif turtleRotation=="east" then
                table.insert(path,{1,0})
            elseif turtleRotation=="north" then
                table.insert(path,{1,1})
            else
                table.insert(path,{1,-1})
            end
        else
            table.insert(path,{1,2})
        end
        table.insert(path,{2,-3})
        local target=turnFromLocation(Location[2][1],'left')
        target=turnFromLocation(target,'left')
        table.insert(path,{1,target})
    else
        local target=turnFromLocation(Location[2][1],'left')
        table.insert(path,{1,target})
        target=turnFromLocation(target,'right')
        table.insert(path,{2,target})
        target=turnFromLocation(target,'right')
        table.insert(path,{1,target})
    end
    table.insert(path,'end')
    newData(actionFile,path)
end



local function goToPath(destiny)--{1x,1y,1z},{2x,2y,2z}
    local distance = {0,0,0}

    local path={'move'}
    for index, value in ipairs(getDirection(destiny)) do
        table.insert(path,value)
    end
    

    table.insert(path,'end')
    if path[2]~='end' then
        newData(actionFile,path)
        return true
    end
    return false
end



local function excavate(startLocation,startFacing,mode)-- mode null - for mining ores, surface for harvesting
    local mode = mode or "ores"
    Location = readFile(locationFile)
    local scanned={"excavate",startLocation,startFacing}


    if findData(actionFile,'excavate')~=false then
        scanned={}
        for index, value in ipairs(findData(actionFile,'excavate')) do
            if value~='end' then
                table.insert( scanned,value)
            end
        end
    end

    if mode=="ores" then
        local scannus = scan('all','ores')
    elseif mode=="surface" then
        local scannus = scan('all','surface')
    end

    for index, value1 in ipairs(scannus) do
        for index, value in ipairs(scanned) do
            if type(value)=="table" and type(value1[1])=="table" then
                if value[1]==value1[1][1] and value[2]==value1[1][2] and value[3]==value1[1][3] then
                    goto continue
                end
            end
        end
        table.insert( scanned,value1[1])
        ::continue::
    end


    if scanned[#scanned]~='end' then
        table.insert(scanned,'end')
    end

    
    if scanned[4]~='end' then


        for index, value in ipairs(scanned) do
            if value=='end' and index~=#scanned then
                table.remove( scanned, index )
            elseif value~='end' and index==#scanned then
                table.insert(scanned,'end')
            end
        end

        for index1, value1 in ipairs(scanned) do
            for i = index1+1, #scanned-index1, 1 do
                if type(value1)=="table" and type(scanned[i])=="table" then
                    if value1[1]==scanned[i][1] and value1[2]==scanned[i][2] and value1[3]==scanned[i][3] then
                        table.remove( scanned, i )
                    end
                end
            end
        end


        if findData(actionFile,'excavate')==false then

            newData(actionFile,scanned)--here?

        else

            editData(actionFile,'excavate',scanned)
        end

        local closestBlock={}
        for i = 4, #scanned-1, 1 do
            if type(scanned[i][1])~="nil" then

                Location = readFile(locationFile)

                local distance=math.sqrt((((scanned[i][1]-Location[1][1])^2)+((scanned[i][2]-Location[1][2])^2)+((scanned[i][3]-Location[1][3])^2)))
                
                if closestBlock[1]==nil then

                    closestBlock={i,distance}
                else

                    if closestBlock[2]>distance then

                        closestBlock={i,distance}
                    end
                end
            end
        end


        local block=scanned[closestBlock[1]]
        table.remove(scanned,closestBlock[1])
        

        for index, value in ipairs(scanned) do
            if value=='end' and index~=#scanned then
                table.remove( scanned, index )
            elseif value~='end' and index==#scanned then
                table.insert(scanned,'end')
            end
        end


        if findData(actionFile,'excavate')==false then
            newData(actionFile,scanned)
        else
            editData(actionFile,'excavate',scanned)
        end
        return {true,block}
    else
        if findData(actionFile,'excavate')~=false then
            editData(actionFile,'excavate',{})
        end
        return {false,scanned[2],scanned[3]}
    end
end


local function reachFloor()
    Location = readFile(locationFile)
    local state,datatable = turtle.inspectDown()
    while true do
        if type(datatable.tags)=="nil" or state==false or datatable.tags[ "minecraft:replaceable" ]==true then
            Location=move(-3,true)
            writeFile(locationFile,Location)
        else
            break
        end
        state,datatable = turtle.inspectDown()
    end


    local state,datatable = turtle.inspectUp()
    while true do
        if type(datatable.tags)~="nil" and state~=false and datatable.tags[ "minecraft:replaceable" ]~=true then
            Location=move(3,true)
            writeFile(locationFile,Location)
        else
            break
        end
        state,datatable = turtle.inspectUp()
    end
end



local function goTo(destiny,mode,map)-- mode excavate, to mine blocks or explore to search for resourecs or map, map -save scanned blocks

    local destiny=destiny or false
    local mode=mode or 'none'
    Location = readFile(locationFile)
    local action = {}
    local returnHome = false
    local map = map or false

    if mode=='return' then
        returnHome=true
    end

    if destiny~=false then
        if goToPath(destiny)==false then
            return false
        end
    end

    if findData(actionFile,'move')~=false then
        for index, value in ipairs(findData(actionFile,'move')) do
            table.insert(action,value)
        end
    else
        return false
    end


    while action[2]~="end" do
        Location = readFile(locationFile)


        if mode=='excavate' then
            while true do
                --[[
                if #checkInventory()>14 then
                    manageInventory("mining")
                end
                ]]
                Location = readFile(locationFile)
                local excavated=excavate(Location[1],Location[2][1])
                if excavated[1]==false then

                    if excavated[2]~=Location[1] then
                        goTo(excavated[2])
                    end

                    turnTo(excavated[3])
                    Location = readFile(locationFile)
                    break

                else
                    if excavated[2]~=Location[1] then
                        goTo(excavated[2])
                    end
                end
            end
        elseif mode=='explore' then
            reachFloor()
            while true do
                --[[
                if #checkInventory()>14 then
                    manageInventory("mining")
                end
                ]]
                Location = readFile(locationFile)
                local excavated=excavate(Location[1],Location[2][1],"surface")
                if excavated[1]==false then

                    if excavated[2]~=Location[1] then
                        goTo(excavated[2])
                    end

                    turnTo(excavated[3])
                    Location = readFile(locationFile)
                    break

                else
                    if excavated[2]~=Location[1] then
                        goTo(excavated[2])
                    end
                end
            end
        end


        if action[2][2]==3 then
            if scan('up','avoid')[1]~=nil then
                if action[2][1]>1 then
                    avoidPath(Location,action[2][2],scan('up','avoid')[1][3]) 
                    goTo(false,mode)
                    action[2][1]=action[2][1]-2
                else
                    return false
                end
            else
                move(action[2][2],true,returnHome)
                Location = readFile(locationFile)
                action[2][1]=action[2][1]-1
            end
        elseif action[2][2]==-3 then
            if scan('down','avoid')[1]~=nil then
                if action[2][1]>1 then
                    avoidPath(Location,action[2][2],scan('down','avoid')[1][3])
                    goTo(false,mode)
                    action[2][1]=action[2][1]-2
                else
                    return false
                end
            else
                move(action[2][2],true,returnHome)
                Location = readFile(locationFile)
                action[2][1]=action[2][1]-1
            end
        else
            turnTo(action[2][2])
            Location = readFile(locationFile)
            if scan('forward','avoid')[1]~=nil then
                if action[2][1]>1 then
                    avoidPath(Location,action[2][2],scan('forward','avoid')[1][3])
                    goTo(false,mode)
                    action[2][1]=action[2][1]-2
                else
                    return false
                end
            else
                move(action[2][2],true,returnHome)
                Location = readFile(locationFile)
                action[2][1]=action[2][1]-1
            end
        end



        if action[2][1]<=0 then
            table.remove(action,2)
        end


        if action[#action] ~= 'end' then
            table.insert(action,'end')
        end


        editData(actionFile,'move',action)
        writeFile(locationFile,Location)
    end
    writeFile(locationFile,Location)
    editData(actionFile,'move',{})
    return true
end



local function mineSpiral(center,step,distance)
    local distance=distance or 4
    local action={}--{name,(x,y,z)center,step,(x,y,z)move x,(x,y,z)move z,end}
    local x=center[1]
    local z=center[3]
    local rotation = 1

    if step%2==0 then
        rotation=-1
    end

    if step>1 then
        z=center[3]+(distance*(math.floor((step-1)/2)*(-rotation)))
    end

    x=center[1]+(distance*(math.floor(step/2)*rotation))
    table.insert( action,{x,center[2],z})

    z=center[3]+(distance*(math.floor(step/2)*rotation))

    table.insert( action,{x,center[2],z})
    --table.insert(action,'end')


    return action--{{move1},{move2}}
    --[[
    if findData(actionFile,'mineSpiral')==false then
        newData(actionFile,action)
    else
        editData(actionFile,'mineSpiral',action)
    end
    --]]
end



local function findHeight()
    Location = readFile(locationFile)
    if Location[3][1]==nil then
        local success,inspect=turtle.inspectDown()
        while inspect.name~='minecraft:bedrock' do
            Location = readFile(locationFile)
            local path={'move',{1,-3},'end'}
            newData(actionFile,path)
            if not(goTo(false)) then
                Location = readFile(locationFile)
                avoidPath(Location,-3,scan('down','avoid')[3])
                goTo(false)
            end
            success,inspect=turtle.inspectDown()
        end
        Location = readFile(locationFile)
        Location[3]={Location[1][2]-1,' - bedrock level'}
        writeFile(locationFile,Location)
        return true
    end
end



local function goToHeight(height,fromBedrock)
    fromBedrock = fromBedrock or false
    Location = readFile(locationFile)

    if type(Location[3][1])=="nil" then
        findHeight()
        Location = readFile(locationFile)
    end

    local bedrockLevel = Location[3][1]

    if fromBedrock then
        height=height+bedrockLevel
    end


    if height<bedrockLevel  then
        error('goToHeight: provided height lower than recorded bedrock height')
    end

    Location = readFile(locationFile)
    local path={}
    if height>Location[1][2] then
        path={'move',{height-Location[1][2],3},'end'}
    else
        path={'move',{height-Location[1][2],-3},'end'}
    end
    newData(actionFile,path)
    goTo(false)
end




local function spiral(mode,height,maxiteration,fromBedrock,iteration)-- mode excavate or explore for surface exploitation
    local fromBedrock = fromBedrock or false
    local mode = mode or "excavate"
    local height = height or false
    local maxiteration = maxiteration or 5
    local iteration =  iteration or 1


    local action = {'spiral'}
    Location = readFile(locationFile)
    local path={}

    if height~=false and fromBedrock~=false then
        goToHeight(height,fromBedrock)
        Location = readFile(locationFile)
    end

    if findData(actionFile,'spiral')~=false then

        action = {}
        for index, value in ipairs(findData(actionFile,'spiral')) do
            table.insert( action, value )
        end



        iteration=action[2]
        maxiteration = action[4]

        if type(action[3])=="table"  then

            if action[5]~='end' then


                if action[#action] ~= 'end' then
                    table.insert(action,'end')
                end


                for index, value in ipairs({5,5}) do
                    if action[value]~='end' then

                        goTo(action[value],'excavate')

                        table.remove( action, 5 )

                        editData(actionFile,'spiral',action)
                    else
                        break
                    end
                end
            end
        end
    end

    Location = readFile(locationFile)
    local center = action[3] or Location[1]

    while true do
        --action(name,iteration,starting position,maxiteration,move1,move2)
        Location = readFile(locationFile)
        action[2]=iteration
        action[4]=maxiteration

        local moves={}


        if findData(actionFile,'spiral')~=false then

            moves=mineSpiral(action[3],iteration)
            action[5]=moves[1]
            action[6]=moves[2]
            action[7]='end'

        else

            moves=mineSpiral(Location[1],iteration)
            Location = readFile(locationFile)
            action[3]=Location[1]
            action[5]=moves[1]
            action[6]=moves[2]
            action[7]='end'
        end


        if type(moves)~="nil" then
            if action[#action] ~= 'end' then
                table.insert(action,'end')
            end


            if findData(actionFile,'spiral')==false then
                newData(actionFile,action)
            end


            while action[5]~="end" do
                Location = readFile(locationFile)


                goTo(action[5],mode)


                table.remove( action,5 )

                if action[#action] ~= 'end' then
                    table.insert(action,'end')
                end

                editData(actionFile,'spiral',action)
            end
        end



        if iteration>maxiteration then
            editData(actionFile,'spiral',{})
            goTo({0,0,0},'excavate')
            return iteration
        end
        iteration=iteration+1
    end
end




local function mineForResources(mode,amount,sortMode)--provide a lost of levelsToMine {{levelFromBedrock,amount to mine, name}} or 'modename',optional amount
    amount = amount or false
    sortMode = sortMode or 'all'

--[[
    --levels from bedrock
    --diamond 5 (-59)
    --redstone 5 (-59)
    --gold 96 (32)
    --iron 79 (15)
    --copper 112 (48)
    --coal 108 (44)
--]]


    Location = readFile(locationFile)
    if Location[3][1] == nil then
        findHeight()
        Location = readFile(locationFile)
    end



    local levelsToMine = {}--{{levelFromBedrock,amount to mine, name}}


    if type(mode)=="table" then
        levelsToMine = mode
    else
        if mode=='turtle' then
            levelsToMine={{79,7,'minecraft:raw_iron'},{5,1,'minecraft:redstone'},{5,3,'minecraft:diamond'}}
            sortMode = 'mine'

        elseif mode == 'fuel' then
            levelsToMine = {{108,amount,'minecraft:coal'}}
            sortMode = 'mine'
        end
    end



    for index, value in ipairs(levelsToMine) do

        local iteration = 1
        while true do
            Location = readFile(locationFile)
            local itemAmount = checkInventory(value[3])[1] or 0

            if itemAmount>= value[2] then
                break
            end


            spiral(false,value[1],iteration,true,iteration)

            manageInventory(sortMode)
            iteration = iteration+1
        end
    end
end



local function updateFileFromGit(GitFile,fileLocation)
    local request = http.get(GitFile)


    local function writeFile(path,data)
        local file = io.open(path, 'w')
        file:write(data..'\n')
        io.close(file)
    end

    writeFile(fileLocation,request.readAll())

    request.close()
end


local function updateProgram()
    updateFileFromGit(mainGitFile,'startup.lua')
end



local function readCommandsFromFile(file,mode)-- true-delete returned command from file
    mode = mode or true

    local fileData = readFile(file)

    local iter = 1
    while iter<#fileData do

        if type(fileData[iter])=="table" and #fileData[iter]==2 then
            local command = fileData[iter][1]
            local argumentCount = fileData[iter][2]
            local arguments={command}
            if mode then
                if argumentCount>0 then
                    for i = 1, argumentCount, 1 do
                        table.insert( arguments,fileData[iter+1])
                        table.remove( fileData,iter+1 )
                    end
                end
                table.remove( fileData, iter )
                writeFile(file,fileData) 
            else
                if argumentCount>0 then
                    for i = 1, argumentCount, 1 do
                        table.insert( arguments,fileData[iter+i])
                    end
                end
            end
            return arguments
        end

        iter=iter+1
    end
    return false
end



local function getNewCommand()

    commands=readFile(commandsFile)
    local commandID = commands[1] or 1

    directive = readFile(directiveFile)
    if directive[4]==nil then
        directive[4]={0,' - command ID'}
        writeFile(directiveFile,directive)
    end

    if type(commands[2])=="nil" then

        directive[4]={commandID,' - command ID'}
        writeFile(directiveFile,directive)

        updateFileFromGit(commandsGitFile,commandsFile)
        commands=readFile(commandsFile)
        commandID = commands[1] or 1
        
        if directive[4][1] >= commandID then
            writeFile(commandsFile,{commandID,''})
            return false
        else
            commandID = commands[1]
        end
    end
    
    if type(commands[2])=="table" then
        readCommandsFromFile(commandsFile)
    end

end


local function SetupFiles()
    if not fileExists(locationFile) or type(readFile(locationFile)[1])=='nil' then
        writeFile(locationFile,Location)
    else
        Location = readFile(locationFile)
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
    end
    
    
    if not fileExists(stowageFile) or type(readFile(stowageFile)[1])=='nil' then
        writeFile(stowageFile,stowage)
    else
        stowage = readFile(stowageFile)
    end
    
    
    if not fileExists(memoryFile) or type(readFile(memoryFile)[1])=='nil' then
        writeFile(memoryFile,memory)
    else
        memory = readFile(memoryFile)
    end
    
    
    if not fileExists(commandsFile) or type(readFile(commandsFile)[1])=='nil' then
        writeFile(commandsFile,commands)
    else
        commands = readFile(commandsFile)
    end
    
    
    if not fileExists(manualOverrideFile) or type(readFile(manualOverrideFile)[1])=='nil' then
        writeFile(manualOverrideFile,{})
    else
        manualOverride = readFile(manualOverrideFile)
    end 
end


local function say(message)
    term.clear()
    term.setCursorPos(1,1)
    print(message)
end


local function reboot()
    os.reboot()
end



local function userContinue()
    read()
end



local function clearTerm()
    term.clear()
    term.setCursorPos(1,1)
end




-- Create a custom environment and add Say function 
local customEnv = {}
customEnv.say = say  -- Manually add Say to the environment
customEnv.updateFileFromGit = updateFileFromGit
customEnv.mineForResources = mineForResources
customEnv.mineForResources = mineForResources
customEnv.craftingRecipe = craftingRecipe
customEnv.getMaterialQuantity = getMaterialQuantity
customEnv.getBuildingStorage = getBuildingStorage
customEnv.getMaterialQuantityByBuilding = getMaterialQuantityByBuilding
customEnv.moveItemInInventory = moveItemInInventory
customEnv.emptyInventoryTo = emptyInventoryTo
customEnv.suckAllFromChest = suckAllFromChest
customEnv.getItemFromNeighbouringChests = getItemFromNeighbouringChests
customEnv.craft = craft
customEnv.avoidPath = avoidPath
customEnv.goToPath = goToPath
customEnv.excavate = excavate
customEnv.goTo = goTo
customEnv.mineSpiral = mineSpiral
customEnv.findHeight = findHeight
customEnv.spiral = spiral
customEnv.encodeTable = encodeTable
customEnv.decodeTable = decodeTable
customEnv.fileExists = fileExists
customEnv.deleteFile = deleteFile
customEnv.writeFile = writeFile
customEnv.readFile = readFile
customEnv.editFile = editFile
customEnv.appendFile = appendFile
customEnv.getFuelCap = getFuelCap
customEnv.refuel = refuel
customEnv.turn = turn
customEnv.turnTo = turnTo
customEnv.blockLocation = blockLocation
customEnv.scan = scan
customEnv.addToLocation = addToLocation
customEnv.turnFromLocation = turnFromLocation
customEnv.getDirection = getDirection
customEnv.move = move
customEnv.findData = findData
customEnv.editData = editData
customEnv.newData = newData
customEnv.findInTag = findInTag
customEnv.isBlockTag = isBlockTag
customEnv.checkStowage = checkStowage
customEnv.checkInventory = checkInventory
customEnv.manageInventory = manageInventory
customEnv.decodeCraftingPattern = decodeCraftingPattern
customEnv.reboot = reboot
customEnv.updateProgram = updateProgram
customEnv.userContinue = userContinue
customEnv.clearTerm = clearTerm
customEnv.mineForResources = mineForResources

--3  -command number

--say$1    -command name, number of arguments
--FINALLY FREEE!!!! -arguments
-- ...

--goTo$1
--3$1$6


--reboot&0


local function runCommand(commandData)
    if commandData==false or type(commandData)=="nil" then
        return false
    else
        if type(commandData[1])~="nil" then
            print(table.unpack(commandData))
            local result = RunMultipleProtected({commandData},customEnv)
            if result==nil then
                local home = findInMemory('home')
                RunProtected(goTo,{home[1],home[2],home[3]})
            end
        end
    end
end
customEnv.runCommand = runCommand


local function findState()
    local directive = readFile(directiveFile)
    if directive[2]=='start' then
        RunProtected(writeFile,commandsFile,{1})
        RunProtected(writeFile,actionFile,{})
        RunProtected(refuel,true)
        directive[2]='running'
        writeFile(directiveFile,directive)
    elseif directive[2]=='running' then

        local action = readFile(actionFile)
        for index, value in ipairs(action) do
            if type(value)=="string" then


                if value=='move' then


                    RunProtected(goTofalse)

                elseif value=='excavate' then


                    while true do
                        Location = readFile(locationFile)
                        local excavated=excavate(Location[1],Location[2][1])
                        if excavated[1]==false then
        
                            if excavated[2]~=Location[1] then
                                RunProtected(goTo,excavated[2])
                            end
        
                            turnTo(excavated[3])
                            Location = readFile(locationFile)
                            break
        
                        else
                            if excavated[2]~=Location[1] then
                                RunProtected(goTo,excavated[2])
                            end
                        end
                    end

                elseif value=='spiral' then

                    local spiralData = findData(actionFile,'spiral')
                    RunProtected(spiral,table.unpack(spiralData,2,#spiralData-1))

                end
            end
        end
    end
end
customEnv.findState = findState

local function inventoryFulness()
    local count = 0
    for i = 1, 16, 1 do
        turtle.select(i)
        local item = turtle.getItemCount()
        if item>0 then
            count = count+1
        end
    end
    if count>14 then
        return true
    end
    return false
end

local function override()
    if not fileExists(manualOverrideFile) or type(readFile(manualOverrideFile)[1])=='nil' then
        writeFile(manualOverrideFile,{})
    else
        while true do
            local state = readCommandsFromFile(manualOverrideFile)
            if type(state)=="boolean" then
                if state==false then
                    break
                end
            else
                runCommand(state)
            end
        end
    end
end

local function faceToward(location,destiny)
    local targetDirection = getDirection({location[1],location[2],location[3]},destiny)
    turnTo(targetDirection[1])
end

local function inventoryEmptyExcept(slot,direction)
    for i = 1, 16, 1 do
        if i ~= slot then
            turtle.select(i)
            if direction=='down' then
                turtle.dropDown()
            else
                turtle.dropUp()
            end
        end
    end
end

local function mineStripe()
    local stripeStart = readFile(commandsFile)[1]
    RunProtected(goTo,{stripeStart[1],stripeStart[2],stripeStart[3]})
    local lastLayer=stripeStart
    while true do
        if inventoryFulness() then
            RunProtected(goTo,{0,0,0})
            inventoryEmptyExcept(1,'up')
        end
        RunProtected(goTo,{lastLayer[1],lastLayer[2],lastLayer[3]})
        RunProtected(goTo,{lastLayer[1]+15,lastLayer[2],lastLayer[3]})
        lastLayer[2]=lastLayer[2]-1
        if scan('down','bedrock')[1]~=nil then
            break
        end
    end
    turtle.select(16)
    turtle.drop()
    RunProtected(goTo,{0,0,0})
    inventoryEmptyExcept(16,'up')
    local mother = scan('all','avoid')[1][1][1]
    faceToward({0,0,0},mother)
    turtle.select(16)
    turtle.drop()


end--when returning turn to mother turtle and drop all turtles is has any

local function programMiner(i)
    writeFile('disk/commands.txt',{{0,i-1,0}})
    writeFile('disk/startup.txt',{'start'})
    updateFileFromGit(minerProgramGitFile,'disk/programMiner.lua')

end


local function mineChunk()
    local home = readFile(memoryFile)[1]
    home = {home[1],home[2],home[3]}
    RunProtected(goTo,{home[1],home[2],home[3]})
    local chunkStart = readFile(commandsFile)[1]

    RunProtected(goTo,{chunkStart[1]-1,chunkStart[2]+1,chunkStart[3]+1})
    turn('left')
    turtle.select(1)
    turtle.place()
    turtle.select(2)
    turtle.drop()
    RunProtected(goTo,{chunkStart[1]-1,chunkStart[2]+1,chunkStart[3]})
    turn('right')

    --[[
    slots:
    1 - disk drive
    2 - disk
    3 - turtle
    4 - ore chest
    5 - fuel chest
    ]]

    RunProtected(goTo,{chunkStart[1]-1,chunkStart[2]+2,chunkStart[3]})
    turtle.select(4)
    turtle.place()

    RunProtected(goTo,{chunkStart[1]-1,chunkStart[2]+3,chunkStart[3]})
    turtle.select(5)
    turtle.place()

    for i = 1, 12, 1 do
        RunProtected(goTo,{chunkStart[1]-1,chunkStart[2]+3,chunkStart[3]})
        turtle.select(1)
        turtle.suckUp(64)
        RunProtected(goTo,{chunkStart[1]-1,chunkStart[2]+1,chunkStart[3]})
        RunProtected(goTo,{chunkStart[1]-1,chunkStart[2]+1,chunkStart[3]+1})
        turn('left')
        programMiner(i)
        RunProtected(goTo,{chunkStart[1]-1,chunkStart[2]+1,chunkStart[3]})
        turn('right')
        turtle.select(3)
        turtle.place()
        turtle.drop()
        sleep(2)
    end
    RunProtected(goTo,{chunkStart[1]-1,chunkStart[2]+1,chunkStart[3]})
    turtle.select(1)
    turtle.suckUp(64)
    turtle.select(2)
    turtle.drop()

    while true do
        if checkInventory('computercraft:turtle_normal')[2]==11 then
            break
        end
        turtle.dig()
        sleep(1)
    end
end

local function main()
    copyFile('disk/startup.txt','startup.lua')
    copyFile('disk/commands.txt','commands.txt')
    copyFile('disk/memory.txt','memory.txt')
    local home = readFile(memoryFile)[1]
    home = {home[1],home[2],home[3]}
    RunProtected(goTo,{home[1],home[2],home[3]})
    refuel()
    mineChunk()
    RunProtected(goTo,{home[1],home[2],home[3]})
end
