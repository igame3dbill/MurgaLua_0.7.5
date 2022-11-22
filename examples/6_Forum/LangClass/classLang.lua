-- Classify languages according to letter frequency using FANN
-- Needs : 3 languages with some sample fragments for each one, and a sample to be classified.
--
if not (arg[1] and lfs.attributes(arg[1])) then -- Check for the file to be present.
	error("Need to specify an existing file!")
end

net = fann.Net.create_from_file("language_clas.net") -- open the previously trained neural net from this file

function generateFreqs(file) -- generates letter frequencies for a file
	local freqs={}
	-- initialize counts array
	for k,v in ipairs({"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}) do
		freqs[v]=0
	end

	local fh,err = io.open(file,"r") -- open the file to be considered

	if err then error(err) end

	local letter=fh:read(1) -- read first letter
	local total = 0
	repeat
		if type(letter)== "string" then --if we actually read a letter
			if freqs[letter] then -- is it a letter in the alphabet?
				total = total + 1 -- add to total
				freqs[letter]=freqs[letter]+1 -- add to the count of the letter read
			end
		end
		letter=fh:read(1) -- read next
	until letter==nil -- stop when finished
	fh:close()

	for k,v in pairs(freqs) do -- Convert to relative frequencies
		freqs[k]=v/total
	end
	return freqs
end

freqs=generateFreqs(arg[1])

local input={}
for num=97,122 do -- construct an input for the neural net
		input[num-96]=string.format("%03.3f",freqs[string.char(num)])
end

output={net:run(unpack(input))} -- run the net on the input

langs={"French","Polish","English"} -- array containing the considered languages
for	k,v in ipairs(langs) do -- print the probabilities for the sample being language X.
	print(v,string.format("%02.1f %%",output[k]*100))
end

