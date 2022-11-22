-- murgalua write to file
my_output=io.open("filename.txt","w+")
if my_output then my_output:write("some stuff")
my_output:close()
end