--[[

iostring: a file-flavored interface to strings

Sometimes you to reuse code designed for the "io" interface to files
as a processing stage.  For example, you may want to read the result
of writing to a file back into a string for further processing.
Creating and deleting a temporary file to hold the data is complicated
(and potentially risky in security-sensitive software.)

iostring provides objects that behave like Lua filehandles but are
implemented on strings.  Currently, only write-only, non-seeking
iostrings are implemented.  (Feel free to implement more, of course.)

iostring.newoutput() returns an object with the following methods:

out = iostring.newoutput()

Returns a write-only, non-seekable iostring object.  Internally, it is
implemented such that repeated appends do not consume time
proportional to the size of the existing contents, using the code from
LTN 9.  Note that this is substantially faster than repeatedly using
the ".." operator to append to a string.

out:write(value1, ...)

Appends each of the arguments to the iostring.  The arguments must be
strings or numbers.

out:getstring()

Returns a current copy of the string built by previous calls to
out:write().

out:flush()

Ensures the string is up to date with all written data.  Note that
out:getstring() implicitly flushes, so for the current output-only
implementation, flush is never necessary.

out:close()

Closes the iostring object.  It is an error to call anything but
getstring on a closed iostring object.

out:lines(), out:read(...), out:seek(...)

These functions raise an error, as they are not implemented.

Example:

function write_squares_table(file)
  for i = 1,10 do
    file:write(i, " ", i*i, "\n")
  end
end

-- write to file:

diskfile = io.open("squares", "w")
write_squares_table(diskfile)
diskfile:close()

-- write to string:

stringfile = iostring.newoutput()
write_squares_table(stringfile)
print(stringfile:getstring())



See ioxmlgen.lua for an XML example.
]]


local Public = {}
iostring = Public

-- From LTN 9

local function newBuffer ()
  return {}
end

local function addString (stack, s)
  table.insert(stack, s)       -- push 's' into the top of the stack
  for i=#stack-1, 1, -1 do
    if string.len(stack[i]) > string.len(stack[i+1]) then break end
    stack[i] = stack[i]..table.remove(stack)
  end
end

-- Note that this function will return nil if there's noting on 
local function toString (stack)
  for i=#stack-1, 1, -1 do
    stack[i] = stack[i]..table.remove(stack)
  end
  return stack[1]
end

local methods = {}

local function errclosed()
  error("attempt to use a closed iostring")
end

function methods:close()
  if self.closed then errclosed() end
  self.closed=true
  return true
end

function methods:flush()
  if self.closed then errclosed() end
  toString(self) -- side effect of compressing
  return true
end

function methods:lines()
  error("iostring is write-only")
end

function methods:read(...)
  error("iostring is write-only")
end

function methods:seek(...)
  error("iostring does not support seeking")
end

function methods:write(...)
  if self.closed then errclosed() end
  for i,s in ipairs(arg) do
    addString(self, s)
  end
  return true
end

function methods:getstring()
  return toString(self) or ""
end

local metatable = {__index=methods}

function Public.newoutput()
  local t = {closed=false}
  setmetatable(t, metatable)
  return t
end
