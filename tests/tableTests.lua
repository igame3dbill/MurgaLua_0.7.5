--
-- Test adapted from : http://lua-users.org/wiki/TableSerialization
--

print("Running table test")

x={ 1 }
x[2] = x
x[x] = 3
x[3]={ 'indirect recursion', [x]=x }
y = { x, x }
x.y = y
assert (y[1] == y[2])
s = murgaLua.serialize (x)
z = loadstring (s)()
assert (z.y[1] == z.y[2])

print("Passed ...")

print(s)
