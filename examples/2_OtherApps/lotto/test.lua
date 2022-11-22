-- http://lua-users.org/wiki/SplitJoin
function split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

-- http://lua-users.org/lists/lua-l/2003-06/msg00558.html
function table.find(t, value)
	result = {}
    for k,v in pairs(t) do
        if v == value then table.insert(result, k) end
    end
	return result
end


if (not arg[1]) then
   print("\n" ..
         "post-replace.lua usage:\n" ..
	 "post-replace.lua BINDING.cxx > newBinding")
   return
end

startProcessing = false
lotteryResults = {}

for currentLine in io.lines(arg[1]) do

	if string.find(currentLine, '<br>$') then
		startProcessing = false
	end
	
	if (startProcessing) then
	    currentLine = string.gsub(currentLine, '<br> ', '')
	    currentLine = string.gsub(currentLine, ':', '')

		currentDate = split(currentLine, " ", 3)
		currentLine = string.gsub(currentLine, table.concat(currentDate, " ") .. " ", '')
		currentNumbers = split(currentLine, " ")
		
		table.insert(lotteryResults, {date = currentDate, numbers = currentNumbers})
	end
	
	if (arg[2] and startProcessing) then
		foundNumber = 0
		
		for i=2,7 do
			for k, v in pairs(table.find(currentNumbers, arg[i])) do
				if k < 7 then foundNumber = foundNumber+1 end
			end
		end
		if (foundNumber > 2) then
			print(foundNumber .. " Matches ! - " ..
				table.concat(currentDate, "/") .. " -- " .. table.concat(currentNumbers, " "))
		end
    end

	if string.find(currentLine, '^<br>%-%-%- Date') then
		startProcessing = true
	end

end

-- murgaLua.debug.printTable(lotteryResults)