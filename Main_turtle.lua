local locationFile='location.txt'
local directiveFile='directive.txt'
local actionFile='action.txt'
local stowageFile='stowage.txt'
local memoryFile = 'memory.txt'


local location={{0,0,0},{0,' - facing Z'},{nil,' - bedrockLevel'},{100,' - fuelcap'}}
local directive={{"Inquisitor"},{"start"}}
local action={}
local avoidedBlocks={"computercraft:turtle","forge:chests"}
local blockTags={{"minecraft:logs",{'minecraft:oak_log'}},"minecraft:sand","forge:ores"}
local blockNames={"minecraft:stone"}
local stowage = {}
local memory={"locations",{0,0,0,'home'},"end"}



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



local function getFuelCap(refuel)
    local refuel = refuel or false
    local location = readFile(directiveFile)
    local fuelCap = location[4][1] or 100

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
                location[4][1]=fuelCap+usedFuel
                writeFile(locationFile,location)
                return true
            else
                turtle.refuel()
                usedFuel=usedFuel+fuelValue/2
                location[4][1]=fuelCap+usedFuel
                writeFile(locationFile,location)
                return false
            end
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
            print('Refueling: '..turtle.getFuelLevel() ' / '..getFuelCap())
            turtle.select(i)
            if getFuelCap(true) then
                turtle.select(1)
                term.clear()
                print('Done refueling, current fuel level: '..turtle.getFuelLevel() ' / '..getFuelCap())
                return true
            end
        end
        if start~=true then
            return false
        end
        print('Failed to refuel, please insert more fuel: '..turtle.getFuelLevel() ' / '..getFuelCap())
        os.sleep(2)
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
    if math.sqrt(direction^2)==2 then
        direction=2
    end
    if math.sqrt(location[2][1]^2)==2 then
        location[2][1]=2
    end
    while location[2][1]~=direction do
        if (location[2][1]==2 and direction==-1) or (direction>location[2][1]) then
            location = turn(location,'right')
        else
            location = turn(location,'left')
        end
    end
    return location
end



local function blockLocation(location)
    local blockLocation={location[1][1],location[1][2],location[1][3]}
    local destiny=location[2][1]
    if destiny==3 then
        blockLocation[2]=location[1][2]+1
    elseif destiny==-3 then
        blockLocation[2]=location[1][2]-1
    else
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



local function scan(mode,bable)
    local bable = bable or 'ores'
    local tags = {}
    if bable=='avoid' then
        tags=avoidedBlocks
    else
        tags=blockTags
    end
    local scanned={}

    if mode=="forward" then
        local success, data = turtle.inspect()
        if success then
            if type(data.tags)~="nil" then
                for index, value in ipairs(tags) do
                    if data.tags[value] then
                        location = readFile(locationFile)
                        local blockLocation=blockLocation(location)
                        if data.tags[ "computercraft:turtle" ] then
                            table.insert(scanned,{blockLocation,value,data.state.facing})
                        else
                            table.insert(scanned,{blockLocation,value})
                        end
                        break
                    end
                end
            end
        end
    end


    if mode=="around" or mode=='all' then
        for i = 1,4, 1 do
            location=turn(location,'left')
            local success, data = turtle.inspect()
            if success then
                if type(data.tags)~="nil" then
                    for index, value in ipairs(tags) do
                        if data.tags[value] then
                            location = readFile(locationFile)
                            local blockLocation=blockLocation(location)
                            if data.tags[ "computercraft:turtle" ] then
                                table.insert(scanned,{blockLocation,value,data.state.facing})
                            else
                                table.insert(scanned,{blockLocation,value})
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
                    if data.tags[value] then
                        location = readFile(locationFile)
                        if data.tags[ "computercraft:turtle" ] then
                            table.insert(scanned,{{location[1][1],location[1][2]+1,location[1][3]},value,data.state.facing})
                        else
                            table.insert(scanned,{{location[1][1],location[1][2]+1,location[1][3]},value})
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
                    if data.tags[value] then
                        location = readFile(locationFile)
                        if data.tags[ "computercraft:turtle" ] then
                            table.insert(scanned,{{location[1][1],location[1][2]-1,location[1][3]},value,data.state.facing})
                        else
                            table.insert(scanned,{{location[1][1],location[1][2]-1,location[1][3]},value})
                        end
                        break
                    end
                end
            end
        end
    end
    return scanned
end



local function addToLocation(location,destiny)
    if destiny==1 then
        location[1][1]=location[1][1]+1
    elseif destiny==-1 then
        location[1][1]=location[1][1]-1
    elseif destiny==0 then
        location[1][3]=location[1][3]+1
    elseif destiny==2 then
        location[1][3]=location[1][3]-1
    elseif destiny==3 then
        location[1][2]=location[1][2]+1
    else
        location[1][2]=location[1][2]-1
    end
    return location
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
    local location = readFile(locationFile)
    local distance = {0,0,0}
    local path={}

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

    return path
end




local function move(destiny,mine)
    local location = readFile(locationFile)
    local mine = mine or false
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
        location=addToLocation(location,destiny)
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



local function findData(fileName,name)
    local actionData = readFile(fileName)
    local found=false
    local action={}
    for index, value in ipairs(actionData) do
        if value[1]==name then
            found=true
            table.insert(action,value)
        elseif found==true then
            if value[1]=='end' then
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



local function checkStowage(stowageID,item)--{{slot,item.name,item.count,item.damage}}==stowageData if no stowageID {stowageID,stowageData}
    local stowageID = stowageID or nil
    local item = item or nil
    local stowageData={}

    if stowageID~=nil then
        stowageID=tonumber(stowageID)

        local stowage=findData(stowageFile,stowageID)--{{stowageID,location,{slot,item.name,item.count,item.damage},"end"}}

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



local function checkInventory(item)--item == str or int  returns {item.name,item.count,item.damage} or {item count,{id's}}
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
                    if value[2]==name then
                        items[1]=items[1]+value[3]
                        table.insert( items[2],value[1])
                    end
                end
            else
                if value[2]==item then
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



local function manageInventory()
    local directive=readFile(directiveFile)
    local reservedSlots={}
    if directive[2]=="mining" then
        reservedSlots={{'fuel',0},{'minecraft:raw_iron',1},{'minecraft:redstone',1},{'minecraft:diamond',0},{'minecraft:stone',1}}
    elseif directive[2]=="gathering" then
        reservedSlots={{'fuel',0},{'minecraft:raw_iron',1},{'minecraft:redstone',1},{'minecraft:diamond',1},{'minecraft:stone'}}
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
        if character==0 then
            table.insert( pattern,nil )
        else
            table.insert( pattern,materials[tonumber(character)][1] )
        end
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



local function craft(crafting,quantity,searchStorage)--if searchStorage = true search all storage or int for single
    local searchStorage = searchStorage or false
    local name=''
    
    if type(crafting)=="table" then
        name=crafting[1]
    else
        name=crafting
    end

    local recipes = craftingRecipe(name)


    local function searchMaterial(material)
        local items = checkInventory(material[1])


        local function searchStorageByNumber(searchStorage,material)
            local stowage = checkStowage(searchStorage,material[1])
            local itemCount = 0
            local stowageItems = {}--{item slots}

            for index, value in ipairs(stowage) do
                itemCount=itemCount+tonumber(value[3])
                table.insert( stowageItems, value[1] )
            end


            if itemCount>=material[2]*quantity then
                return true
            else
                return itemCount
            end
        end



        if type(searchStorage)=='number' then

            return searchStorageByNumber(searchStorage,material)

        elseif searchStorage==true then

            local stowage = checkStowage(nil,material[1])
            local stowageItemCount={}

            for index, value in ipairs(stowage) do

                local itemCount = 0

                for index, value in ipairs(value[2]) do

                    itemCount=itemCount+value[3]

                end
                
                table.insert( stowageItemCount,{value[1],itemCount} )

            end


            if stowageItemCount[1]>=material[2]*quantity then
                
            end

            return stowageItemCount--{{stowageId,itemCount}}

        elseif type(searchStorage)=="table" then
            
            local storageTotal=0
            for index, value in ipairs(searchStorage) do
                local storageStatus searchStorageByNumber(value,material)
                if storageStatus==true or storageTotal>=material[2]*quantity then
                    return true
                else
                    storageTotal=storageTotal+storageStatus
                end
            end


        elseif items[1]>=material[2]*quantity then
            return true
        else
            return items[1]
        end
    end


    for index, recipe in ipairs(recipes) do
        local materials = recipe[1]

        for index, material in ipairs(materials) do
            local materialLocation = searchMaterial(material)

            if materialLocation==false then
                local recipes = craftingRecipe(material)
                
                if recipes~=false then
                    
                    for index, value in ipairs(recipes) do
                        local materials = value[1]
                    end

                    if materials[1]~=name and materials[2]~=nil then
                        craft(material)
                    end
                end
            else

            end
        end
    end
end



local function avoidPath(location,destiny,turtleRotation)
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
        local target=turnFromLocation(location[2][1],'left')
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
        local target=turnFromLocation(location[2][1],'left')
        target=turnFromLocation(target,'left')
        table.insert(path,{1,target})
    else
        local target=turnFromLocation(location[2][1],'left')
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
end



local function excavate(start)
    local location = readFile(locationFile)
    local scanned={"excavate",start}

    location = readFile(locationFile)
    if findData(actionFile,'excavate')~=false then
        scanned={}
        for index, value in ipairs(findData(actionFile,'excavate')) do
            table.insert( scanned,value)
        end
    end

    for index, value in ipairs(scan('all','ores')) do
        table.insert( scanned,value)
    end


    if #scanned~='end' then
        table.insert(scanned,'end')
    end

    
    if scanned[3]~='end' then
        if findData(actionFile,'excavate')==false then
            newData(actionFile,scanned)
        else
            editData(actionFile,'excavate',scanned)
        end

        local closestBlock={}
        for i = 3, #scanned-1, 1 do
            location = readFile(locationFile)
            local distance=math.sqrt((((scanned[i][1]-location[1][1])^2)+((scanned[i][2]-location[1][2])^2)+((scanned[i][3]-location[1][3])^2)))
            if closestBlock[1]==nil then
                closestBlock={i,distance}
            else
                if closestBlock[2]>distance then
                    closestBlock={i,distance}
                end
            end
        end


        local block=scanned[closestBlock[1]]
        table.remove(scanned,closestBlock[1])
        location = readFile(locationFile)
        
        if findData(actionFile'excavate')==false then
            newData(actionFile,scanned)
        else
            editData(actionFile,'excavate',scanned)
        end
        return {true,block}
    else
        if findData(actionFile,'excavate')~=false then
            editData(actionFile,'excavate',{})
        end
        return {false,scanned[2]}
    end
end



local function goTo(destiny,mode)
    local destiny=destiny or false
    local mode=mode or 'none'
    location = readFile(locationFile)
    local action = {}

    if destiny~=false then
        goToPath(destiny)
    end

    for index, value in ipairs(findData(actionFile,'move')) do
        table.insert(action,value)
    end

    while action[2]~="end" do
        location = readFile(locationFile)


        if mode=='excavate' then
            while true do
                local excavated=excavate(location)
                goTo(excavated[2])
                if excavated[1]==false then
                    break
                end
                if manageInventory()==false or refuel()==false then
                    local locations = findData(memoryFile,'locations')
                    local home={0,0,0}
                    for index, value in ipairs(locations) do
                        if value[4]=='home' then
                            home={value[1],value[2],value[3]}
                            break
                        end
                    end
                    goTo(home)
                    return false
                end
            end
        end


        if action[2][2]==3 then
            if scan('up','avoid')[1]~=nil then
                if action[2][1]>1 then
                    avoidPath(location,action[2][2],scan('up','avoid')[1][3])
                    goTo(false,mode)
                    action[2][1]=action[2][1]-2
                else
                    return false
                end
            else
                location=move(action[2][2],true)
                action[2][1]=action[2][1]-1
            end
        elseif action[2][2]==-3 then
            if scan('down','avoid')[1]~=nil then
                if action[2][1]>1 then
                    avoidPath(location,action[2][2],scan('down','avoid')[1][3])
                    goTo(false,mode)
                    action[2][1]=action[2][1]-2
                else
                    return false
                end
            else
                location=move(action[2][2],true)
                action[2][1]=action[2][1]-1
            end
        else
            location=turnTo(location,action[2][2])
            if scan('forward','avoid')[1]~=nil then
                if action[2][1]>1 then
                    avoidPath(location,action[2][2],scan('forward','avoid')[1][3])
                    goTo(false,mode)
                    action[2][1]=action[2][1]-2
                else
                    return false
                end
            else
                location=move(action[2][2],true)
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
        writeFile(locationFile,location)
    end
    writeFile(locationFile,location)
    editData(actionFile,'move',{})
    return true
end



local function mineSpiral(center,step,distance)
    local distance=distance or 4
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
        z=center[3]+(distance*(math.floor((step-1)/2)*(-rotation)))
    end

    x=center[1]+(distance*(math.floor(step/2)*rotation))

    table.insert( action,{x,center[2],z})

    z=center[3]+(distance*(math.floor(step/2)*rotation))


    table.insert( action,{x,center[2],z})
    table.insert(action,'end')

    if findData(actionFile,'mineSpiral')==false then
        newData(actionFile,action)
    else
        editData(actionFile,'mineSpiral',action)
    end
end


--levels from bedrock
--diamond,redstone 5 
--iron 80
--copper,coal? 112
--coal 160


local function findHeight()
    local location = readFile(locationFile)
    if location[3][1]==nil then
        local success,inspect=turtle.inspectDown()
        while inspect.name~='minecraft:bedrock' do
            location = readFile(locationFile)
            local path={'mine',{1,-3},'end'}
            newData(actionFile,path)
            if not(goTo(false)) then
                location = readFile(locationFile)
                avoidPath(location,-3,scan('down','avoid')[3])
            end
            success,inspect=turtle.inspectDown()
        end
        location = readFile(locationFile)
        location[3][1]=location[1][2]-1
        writeFile(locationFile,location)
    end
end




local function spiral(mode)

    local mode = mode or false


    local function reachFloor()
        local location = readFile(locationFile)
        local state,datatable = turtle.inspectDown()
        while true do
            if type(datatable.tags)=="nil" or state==false or datatable.tags[ "minecraft:replaceable" ]==true then
                location=move(-3,true)
                writeFile(locationFile,location)
            else
                break
            end
            state,datatable = turtle.inspectDown()
        end


        local state,datatable = turtle.inspectUp()
        while true do
            if type(datatable.tags)~="nil" and state~=false and datatable.tags[ "minecraft:replaceable" ]~=true then
                location=move(3,true)
                writeFile(locationFile,location)
            else
                break
            end
            state,datatable = turtle.inspectUp()
        end
    end



    local action = {'spiral'}
    local location = readFile(locationFile)
    local path={}
    local iteration= 1

    if findData(actionFile,'spiral')~=false then
        action = {}
        for index, value in ipairs(findData(actionFile,'spiral')) do
            table.insert( action, value )
            iteration=action[2]
        end
    end


    while true do
        action[2]=iteration

        if findData(actionFile,'spiral')~=false then
            mineSpiral(action[3],iteration)
        else
            mineSpiral(location[1],iteration)
            action[3]=location[1]
        end


        if findData(actionFile,'mineSpiral')~=false then

            if action[4]==nil then
                for i = 3, 4, 1 do
                    table.insert( action,findData(actionFile,'mineSpiral')[i])
                end
            end


            if action[#action] ~= 'end' then
                table.insert(action,'end')
            end


            if findData(actionFile,'spiral')==false then
                newData(actionFile,action)
            end



            while action[4]~="end" do

                location = readFile(locationFile)

                if mode then
                    goTo({action[4][1],location[1][2],action[4][3]},'excavate_wood')
                    reachFloor()
                else
                    goTo(action[4],'excavate')
                end
                table.remove( action,4 )

                if action[#action] ~= 'end' then
                    table.insert(action,'end')
                end

                editData(actionFile,'spiral',action)
            end
        end
        if iteration>20 then
            break
        end
        iteration=iteration+1
    end
end



local function calculateRequiredResource(item)
    
end



local function mineForResources()

    location = readFile(locationFile)
    if location[3][1] == nil then
        findHeight()
        location = readFile(locationFile)
    end

    local bedrock = location[3][1]
    local resources={}


    if checkInventory() then
        
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
        goTo(false,'excavate')
    end
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



refuel()
while true do
    local item = turtle.getItemDetail(1)
    if item~=nil then
        writeFile('testData.txt',{item.name,item.count,item.damage})
    end
    os.sleep(1)
end
--[[

local item = turtle.getItemDetail(1)
    if item~=nil then
        writeFile('testData.txt',{item.name,item.count,item.damage})
    end

local state,datatable = turtle.inspect()
writeFile('testData.txt',{state,textutils.serialise(datatable)})
--]]
