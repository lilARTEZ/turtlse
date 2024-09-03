local request = http.get("https://github.com/lilARTEZ/turtlse/raw/main/Main_turtle.lua")


local function writeFile(path,data)
    local file = io.open(path, 'w')
    file:write(data..'\n')
    io.close(file)
end

writeFile('startup.lua',request.readAll())

request.close()
