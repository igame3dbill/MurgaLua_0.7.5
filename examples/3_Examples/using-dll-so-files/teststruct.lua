
print ("Warning, these tests will run for a while ...")
io.flush()

-- load library
local lib = alien.struct

local a,b,c,d,e,f,x

assert(lib.pack('b', 10) == string.char(10))
assert(lib.pack('bbb', 10, 20, 30) == string.char(10, 20, 30))

assert(lib.pack('<h', 10) == string.char(10, 0))
assert(lib.pack('>h', 10) == string.char(0, 10))
assert(lib.pack('<h', -10) == string.char(256-10, 256-1))

assert(lib.pack('<l', 10) == string.char(10, 0, 0, 0))
assert(lib.pack('>l', 10) == string.char(0, 0, 0, 10))
assert(lib.pack('<l', -10) == string.char(256-10, 256-1, 256-1, 256-1))

assert(lib.unpack('<h', string.char(10, 0)) == 10)
assert(lib.unpack('>h', string.char(0, 10)) == 10)
assert(lib.unpack('<h', string.char(256-10, 256-1)) == -10)

assert(lib.unpack('<l', string.char(10, 0, 0, 1)) == 10 + 2^(3*8))
assert(lib.unpack('>l', string.char(0, 1, 0, 10)) == 10 + 2^(2*8))
assert(lib.unpack('<l', string.char(256-10, 256-1, 256-1, 256-1)) == -10)

for i=1,4 do
  x = lib.pack('<i'..i, -3)
  assert(string.len(x) == i)
  assert(x == string.char(256-3) .. string.rep(string.char(256-1), i-1))
  assert(lib.unpack('<i'..i, x) == -3)
end

assert(lib.pack("<lhbxxH", -2, 10, -10, 250) ==
  string.char(254, 255, 255, 255, 10, 0, 246, 0, 0, 250, 0))

a,b,c,d = lib.unpack("<lhbxxH",
  string.char(254, 255, 255, 255, 10, 0, 246, 0, 0, 250, 0))
assert(a == -2 and b == 10 and c == -10 and d == 250)

assert(lib.pack(">lBxxH", -20, 10, 250) ==
                string.char(255, 255, 255, 236, 10, 0, 0, 0, 250))

a, b, c = lib.unpack(">lBxxH",
                 string.char(255, 255, 255, 236, 10, 0, 0, 0, 250))
assert(a == -20 and b == 10 and c == 250)

a,b,c,d = lib.unpack(">fdfH",
                  '000'..lib.pack(">fdfH", 3.5, -24e-5, 200.5, 30000),
                  4)
assert(a == 3.5 and b == -24e-5 and c == 200.5 and d == 30000)

a,b,c,d,e = lib.unpack("<fdxxfH",
                  '000'..lib.pack("<fdxxfH", -13.5, 24e5, 200.5, 300),
                  4)
assert(a == -13.5 and b == 24e5 and c == 200.5 and d == 300 and e == 24)

x = lib.pack(">i2fi4i3", 10, 20, -30, 4000001)
assert(string.len(x) == 2+4+4+3)
assert(lib.unpack(">f", x, 3) == 20)
a,b,c,d = lib.unpack(">i2fi4i3", x)
assert(a == 10 and b == 20 and c == -30 and d == 4000001)

local s = "hello hello"
x = lib.pack("bc0", string.len(s), s)
assert(lib.unpack("bc0", x) == s)
x = lib.pack("Lc0", string.len(s), s)
assert(lib.unpack("Lc0", x) == s)
x = lib.pack("cc3b", s, s, 0)
assert(x == "hhel\0")
assert(lib.unpack("xxxxb", x) == 0)

assert(lib.pack("<!l", 3) == string.char(3, 0, 0, 0))
assert(lib.pack("<!xl", 3) == string.char(0, 0, 0, 0, 3, 0, 0, 0))
assert(lib.pack("<!xxl", 3) == string.char(0, 0, 0, 0, 3, 0, 0, 0))
assert(lib.pack("<!xxxl", 3) == string.char(0, 0, 0, 0, 3, 0, 0, 0))

assert(lib.unpack("<!l", string.char(3, 0, 0, 0)) == 3)
assert(lib.unpack("<!xl", string.char(0, 0, 0, 0, 3, 0, 0, 0)) == 3)
assert(lib.unpack("<!xxl", string.char(0, 0, 0, 0, 3, 0, 0, 0)) == 3)
assert(lib.unpack("<!xxxl", string.char(0, 0, 0, 0, 3, 0, 0, 0)) == 3)

assert(lib.pack("<!2blh", 2, 3, 5) == string.char(2, 0, 3, 0, 0, 0, 5, 0))
a,b,c = lib.unpack("<!2blh", string.char(2, 0, 3, 0, 0, 0, 5, 0))
assert(a == 2 and b == 3 and c == 5)

assert(lib.pack("<!8blh", 2, 3, 5) == string.char(2, 0, 0, 0, 3, 0, 0, 0, 5, 0))
a,b,c = lib.unpack("<!8blh", string.char(2, 0, 0, 0, 3, 0, 0, 0, 5, 0))
assert(a == 2 and b == 3 and c == 5)

assert(lib.pack(">sh", "aloi", 3) == "aloi\0\0\3")
assert(lib.pack(">!sh", "aloi", 3) == "aloi\0\0\0\3")
x = "aloi\0\0\0\0\3\2\0\0"
a, b, c = lib.unpack("<!si4", x)
assert(a == "aloi" and b == 2*256+3 and c == string.len(x)+1)

x = lib.pack("!4sss", "hi", "hello", "bye")
a,b,c = lib.unpack("sss", x)
assert(a == "hi" and b == "hello" and c == "bye")
a, i = lib.unpack("s", x, 1)
assert(a == "hi")
a, i = lib.unpack("s", x, i)
assert(a == "hello")
a, i = lib.unpack("s", x, i)
assert(a == "bye")


assert(lib.size("i4") == 4)
assert(lib.size(">!4i4i2i4") == 12)
assert(lib.size("c1bc") == 3)
assert(lib.size("<!ddd") == 3*lib.size("d"))
assert(lib.size("h") == lib.size("H"))
assert(lib.size("l") == lib.size("L"))
assert(lib.size("b") <= lib.size("h") and lib.size("h") <= lib.size("i") and
lib.size("i") <= lib.size("l"))


local options =
    {"b", "s", "l", "c2", "s", "f", "d", "i", "i1", "i2", "i4"}
for _, l in pairs ({1,2,4,8}) do
  for _, a1 in pairs (options) do
    for _, a2 in pairs (options) do
      for _, a3 in pairs (options) do
        for _, a4 in pairs (options) do
          for _, d in pairs ({"<", "", ">"}) do
            local s = d .. "!" .. l .. a1 .. a2 .. a3 .. a4
            local x = lib.pack(s, 10, -2, 99, -9)
            local a,b,c,d = lib.unpack(s, x)
            a = tonumber(a); b = tonumber(b); c = tonumber(c); d = tonumber(d)
            assert(a == 10 and b == -2 and c == 99 and d == -9)
          end
        end
      end
    end
  end
end


-- test for errors and strange situations
assert(not pcall(lib.pack, "!>"))
assert(not pcall(lib.unpack, ">>"))
assert(not pcall(lib.unpack, "!!"))
assert(not pcall(lib.pack, "!3l", 10))
assert(pcall(lib.pack, "i3", 4))
assert(lib.pack("") == "")
assert(not pcall(lib.size, "s"))
assert(not pcall(lib.size, "c0"))

print("All tests OK!")
