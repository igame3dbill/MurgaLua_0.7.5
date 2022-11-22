local file = io.open("test.xml","w")

file:write("<?xml version=\"1.0\"?>")
file:write("<exampleA docType=\"Example XML\"/>\n")
file:write("<example docType=\"Example XML\">\n")
file:write("    <tree height=\"25\" weight='30\&quot;<>&amp;&apos;'/>\n")
file:write("    <exampleText>\n")
file:write("<![CDATA[Here we have some text,\n")
file:write("Look how nice]]>\n")
file:write("    </exampleText>\n")
file:write("    <subStruct>\n")
file:write("       <tree height=\"25\" weight=\"30\"/>\n")
file:write("       <moreText>This is more text</moreText>\n")
file:write("       <moreText>And another instance with test chars\n")
file:write("                 &quot;&gt;&lt;&amp;&apos;</moreText>\n")
file:write("    </subStruct>\n")
file:write("</example>\n")

file:close()

local xmlTable = murgaLua.importXmlFile("test.xml")

print( "Imported XML dump : \n" )
murgaLua.debug.printTable(xmlTable)
diskfile = io.open("test.txt", "w")
murgaLua.exportXml(xmlTable, diskfile)
diskfile:close()

local xmlTable2 = murgaLua.importXmlFile("test.txt")

diskfile = io.open("test2.txt", "w")
murgaLua.exportXml(xmlTable2, diskfile)
diskfile:close()

stringfile = murgaLua.newIoString()
stringfile:write("<?xml version=\"1.0\"?>\n")
murgaLua.exportXml(xmlTable2, stringfile)
print(stringfile:getstring())

murgaLua.debug.printTable(xmlTable2)

subStruct = murgaLua.findXmlNode(xmlTable2, "/example/subStruct")

moreText = murgaLua.findNextXmlNode(subStruct, "moreText")

counter  = 2
repeat
  print(moreText[1])
  moreText = murgaLua.findNextXmlNode(subStruct, "moreText",counter)
  counter = counter + 1
until(not moreText)

print("OK, now memory importing\n")

lastXml = murgaLua.importXmlString(stringfile:getstring())

murgaLua.debug.printTable(lastXml)
