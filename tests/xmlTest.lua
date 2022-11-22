local table_1 = {firstVar=1; secondVar=2; thirdVar="abc"}
local myVar = "This is a string"
local table_2 = {myVar, "Test String", true, table_1}

local myTable = {firstKey="simpleItem"; secondKey=table_2}

print( "Created LUA table" )

murgaLua.saveToXml("foo.xml", myTable)

print( "Saved LUA table as LUA XML" )

local loadedTable = murgaLua.loadFromXml("foo.xml")

print( "Loaded LUA table from LUA XML" )

if loadedTable ~= nil then
     print( "Loaded LUA table OK, try re-saving" )
     murgaLua.saveToXml("foo2.xml", loadedTable)
end

print( "Import LUA XML as RAW XML to parse" )

local xmlTable = murgaLua.importXmlFile("foo.xml")

print( "Imported XML dump" )
print( "Root Element Name" .. xmlTable[1].name )
print( "Root Element Attribute ( " .. next(xmlTable[1].attr) .." )")

print( "\nNow for some nasty lazy debug ...\n")

print( xmlTable[1][1].name )
print( xmlTable[1][1].attr )
print( xmlTable[1][1][1].name )
print( xmlTable[1][1][1].attr )
print( xmlTable[1][1][1][1].name )
print( xmlTable[1][1][1][1].attr )
print( xmlTable[1][1][1][1] )
print( next(xmlTable[1][1][1]) )

print( "\nNo errors ... All done !!")
