TestObj = {}

function TestObj:new()
  local objectInstance = {}   -- create object if user does not provide one
  setmetatable(objectInstance, self)
  self.__index = self
  return objectInstance
end

function TestObj:print()
	-- assert(self.name, "Name hasn't been set yet")
	print(self.name)
end

function TestObj:set(name)
	self.name = name
end

a = TestObj:new()

a:set("bob")
a:print()
TestObj:print()
