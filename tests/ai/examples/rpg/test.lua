local classes = {
	"Fighter", "Paladin", "Druid", "Cleric", "Monk",
	"Thief", "Sorceress", "Mage", "Bard"
}

-- Load the network from a file
local net = fann.Net.create_from_file("rpg.net")
math.randomseed(os.time())

while true do
	print("Enter the character attributes or: -1 to exit, -2 to generate:")
	
	local input = {}
	local aux = io.read("*n")
	
	if not aux or aux == -1 then
		-- Quit
		break 
	elseif aux == -2 then
		-- Random
		
		for i = 1, 6 do
			local d = {}
			for i = 1, 4 do table.insert(d, math.random(1, 6)) end
			table.sort(d)
			table.insert(input, d[2] + d[3] + d[4])
		end
		
		print("Generated attributes:")
		print(table.concat(input, " "))
	else
		-- Read the attributes from stdin
		table.insert(input, aux)
		
		for i = 2, 6 do
			aux = io.read("*n")
			table.insert(input, aux)
		end
	end
	
	-- Get the result and calculate suggest the character class
	local output = net:run(input)
	local maxClass, maxValue = -1, -1
	
	-- Get the max value
	for class, value in ipairs(output) do
		if value > maxValue then
			maxClass = class
			maxValue = value
		end
	end
	
	-- Only check if there's a class with at least 0.6 fitting
	if maxValue < 0.4 then
		print("-> The attributes are too low to suggest a class")
	else
		-- Calculate the diff using the maxValue
		local diff = maxValue / 6
		diff = math.max(diff, 0.1)
		
		-- Get the suggestions
		local suggestions = {}
		
		for class, value in ipairs(output) do
			if value > maxValue - diff then
				table.insert(suggestions, {["class"] = class, ["value"] = value})
			end
		end
		
		-- Sort the suggestions according to the fitness
		table.sort(suggestions, function(a, b) return a.value > b.value end)
		
		-- Inform the user about the suggestions
		print("\nClass suggestions:")
		
		for i, tbl in ipairs(suggestions) do
			print(string.format("-> %s (%d%%)", classes[tbl.class], tbl.value * 100))
		end
	end
	
	print()
end
