-- tracking userInput with a global available anywhere else in the program
userInput=""


function entertocontinue ()
	-- make a line across 80 columns of text
	print(string.rep('_', 80))
	
	--Write to console, how is it different than Print? Maybe doesn't auto linefeed.
	  io.write('\tHit [enter] to continue.\n\t Hit [q] to quit.\n\t')
	  
  -- wait for user input
  userInput = io.read()
  
   -- clear the console window
  os.execute("cls")
  
  return userInput
end

function run()
-- loop until we choose to quit
while userInput ~= "q" do entertocontinue() end

-- quit 
if userInput == "q" then 
print("Exiting...\n");
userInput = ""
end 
end

run()