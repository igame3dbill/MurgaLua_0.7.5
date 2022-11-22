-- add to murgaLua program to accept command line arguments for fullscreen
for i=1,table.getn(arg) do
if arg[i] == "-f" then w:fullscreen() end
if arg[i] == "-c" then w:color(arg[i+1]) end
end