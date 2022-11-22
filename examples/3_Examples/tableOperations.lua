print "Constructing table"

myTable =
{ 
   bob   = { age = 22, sex = "male",   surname = "Smith" },
   tracy = { age = 25, sex = "female", surname = "Smith" },
   john  = { age = 32, sex = "male",   surname = "Murga" },
   tim   = { age = 44, sex = "male",   surname = "Williams" },
   anne  = { age = 44, sex = "female", surname = "Smith" }
}

murgaLua.debug.printTable(myTable, 2)

print "Searching for Murga ..."

-- Nice litle search construct
print ("Matched element was : " .. table.foreach (myTable, 
  function (myKey, myValue) if myValue.surname == "Murga" then return myKey end end ))

-- Demo of the table filter function
copyTable = murgaLua.filterTable (myTable, function (myValue) return myValue.surname == "Smith" end)

-- Then debug
print "Copied table ..."

murgaLua.debug.printTable(copyTable)
