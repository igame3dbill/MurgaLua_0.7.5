--lua io.popen get result of executable
-- as alternative to os.execute() 
mycmd = io.popen("dir")
myoutput = mycmd:read("*a")
mycmd:close()
print(myoutput)