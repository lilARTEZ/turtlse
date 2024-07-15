local locationFile='location.txt'


local function fileExists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end



local function deleteFile(path)
    os.remove(path)
end



local function writeFile(path,data)--list of rows to write
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



local function move(direction)
    if direction=='left' then
        turtle.turnLeft()
    elseif direction=='right' then
        turtle.turnRight()
    elseif direction=='back' then
        turtle.turnLeft()
        turtle.turnLeft()
    else
        print("wrong move direction")
    end
end
