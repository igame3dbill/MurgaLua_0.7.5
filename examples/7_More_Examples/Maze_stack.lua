-- from https://stackoverflow.com/questions/28052404/my-lua-maze-builder-that-is-braiding

os.execute("cls")
maze={}
height = 30
width = 30

r =""
c =""
for i = 1, height do
    maze[i] = {}

    for j = 1, width do
        maze[i][j]= {} -- Fill the values here
		c = c.."0"
		
    end
	r = r..c.."\n"
c=""
end
--print(r)
local function buildMazeInternal(x,y,maze)

    local stack = {}
    local directions = {'North','East','South','West'}
	--local maze={{}}
    table.insert(stack,{x=x,y=y})

    while #stack > 0 do
        local index = 1
        local nextX = x
        local nextY = y
        local braid = false 

        for i = #directions, 2, -1 do -- backwards
            local r = math.random(1,i) -- select a random number between 1 and i
            directions[i], directions[r] = directions[r], directions[i] -- swap the randomly selected item to position i
        end
	--print((y+1).." "..(x-1))
        while index <= #directions and nextX == x and nextY == y do
            if directions[index] == 'North' and y > 1 and not maze[y-1][x].Visited then
                maze[y][x].North = true
                maze[y-1][x].South = true
                nextY = y-1
            elseif directions[index] == 'East' and x < width and not maze[y][x+1].Visited then
                maze[y][x].East = true
                maze[y][x+1].West = true
                nextX = x+1
            elseif directions[index] == 'South' and y < height and not maze[y+1][x].Visited then
                maze[y][x].South = true
                maze[y+1][x].North = true
                nextY = y+1
			
            elseif directions[index] == 'West' and x > 1 and not maze[y][x-1].Visited then
                maze[y][x].West = true
                maze[y][x-1].East = true
                nextX = x-1
            else
                index = index + 1
            end
        end

        if nextX ~= x or nextY ~= y then
            x = nextX
            y = nextY
            maze[y][x].Visited = true
            table.insert(stack,{x=x,y=y})
        else    
            x = stack[#stack].x
            y = stack[#stack].y
            table.remove(stack)
        end
    end
end
grid ={}
buildMazeInternal(30,30,maze)
r =""
c =""
count = 1
block = string.char(178)
gap = string.char(249)
	for index, data in ipairs(maze) do
   --print(index)

		for key, value in ipairs(data) do
        --print('\t', key, value)
		
			for i,k in pairs(value) do
		--print('\t\t', index,key,i,k)	
			if i == "Visited" then 
				c = c..block
				else
				c=c.." "
				end	
			end 
			count = count + 1
			if count > 30 then
				r = r..c.."\n"	
				count = 1		
				c=""
				end
		end
		
    end
	print(r)
