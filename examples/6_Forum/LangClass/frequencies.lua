-- Counts frequencies in files a text, and outputs to a format useful for training fann.

filename="train.data"
fh,err =io.open("train.data","w")
if err then error(err) end

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

function writeFreqs(freqs,code) -- Write frequencies to standard output.
	for num=97,122 do
		fh:write(string.format("%03.3f",freqs[string.char(num)])," ")
	end
	fh:write("\n\n",code,"\n\n")
end

filelist={ -- Files containing language snips as keys, their code (the expected output from the ANN) as value.
	["fr-1"]="1 0 0",
	["fr-2"]="1 0 0",
	["fr-3"]="1 0 0",
	["fr-4"]="1 0 0",

	["po-1"]="0 1 0",
	["po-2"]="0 1 0",
	["po-3"]="0 1 0",
	["po-4"]="0 1 0",

	["en-1"]="0 0 1",
	["en-2"]="0 0 1",
	["en-3"]="0 0 1",
	["en-4"]="0 0 1"
}
 -- header containing:
 -- 12 : number of samples
 -- 26 : number of input neurons
 -- 3  : number of output neurons
fh:write("12 26 3 \n\n")

for file,code in pairs(filelist) do
	writeFreqs(generateFreqs(file..'.txt'),code)
end
