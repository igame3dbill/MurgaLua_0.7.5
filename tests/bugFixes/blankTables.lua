local testTable = {a={}, b={}, c={"text"}}
testTable["\nNasty Example@#$%\""]="Nasty text\nMore\tHere"

murgaLua.debug.printTable(testTable)
murgaLua.saveToXml("empty-table-from-xml.xml", testTable)
print("\n")
local loadedTable = murgaLua.loadFromXml("empty-table-from-xml.xml")
murgaLua.debug.printTable(loadedTable)
testString = murgaLua.dumpToXml(testTable)
print(testString)
murgaLua.debug.printTable(murgaLua.parseFromXml(testString))
print(murgaLua.debug.dumpTableAsLua(loadedTable, "xmlTestData"))