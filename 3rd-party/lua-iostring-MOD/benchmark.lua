require "iostring"
require "ciostring"

require "ioxmlgen"
require "concatxmlgen"

--[[
Benchmark various strategies for outputting XML.

iostr is the iostring implementation in pure Lua.
concat is a traditional "return a string" implementation
file uses a temporary file and io.write; then reading in the result
nullio uses a pure Lua iostring implementation that doesn't actually append anything
ciostr uses the iostring interface implemented in C.

]]


function squares_table(n)
  local sq = {name="squares"}
  for i=1,n do
    local entry = {name="entry", 
      {name="x", tostring(i)}, {name="y", tostring(i*i)}}
    table.insert(sq, entry)
  end
  return sq
end

function cpu(f)
  local count = cpucount or 1
  collectgarbage()
  local start = os.clock()
  for i=1,count do
    f()
  end
  return os.clock()-start
end

function time_file(sq)
  return cpu(function ()
               local file = assert(io.open("test.xml", "w"))
               ioxmlgen.write_xml(file, sq)
               file:close()
               file = assert(io.open("test.xml"))
               local s = file:read("*a")
               file:close()
               assert(os.remove("test.xml"))
             end)
end

function time_iostring(sq)
  return cpu(function ()
      local st = iostring.newoutput()
      ioxmlgen.write_xml(st, sq)
      st:getstring()
    end)
end

function time_ciostring(sq)
  return cpu(function ()
      local st = ciostring.newoutput()
      ioxmlgen.write_xml(st, sq)
      st:getstring()
    end)
end

function time_nullio(sq)
  local nullio = {write=function(...) end}
  return cpu(function ()
      ioxmlgen.write_xml(nullio, sq)
    end)
end

function time_concat(sq)
  return cpu(function ()
      concatxmlgen.return_xml(sq)
    end)
end

-- Round string
function rs(n)
  return string.format("%0.3g", n)
end

function run_one_bench(sqsizes)
  print("squares", "iostr", "concat", "file", "nullio", "ciostr")
  for _,i in sqsizes do
    local sq = squares_table(i)
    print(i, rs(time_iostring(sq)), rs(time_concat(sq)), rs(time_file(sq)),
        rs(time_nullio(sq)), rs(time_ciostring(sq)))
  end
  print()
end

function runbenches()
  cpucount = 1
  print("1 run")
  run_one_bench({1,10,100,1000,10000})

  cpucount = 100
  print("100 runs")
  run_one_bench({1,10,100,1000})

  cpucount = 10000
  print("10000 runs")
  run_one_bench({1,10})
end

runbenches()

--[[ sample output:

1 run
squares	iostr	concat	file	nullio	ciostr
1	0	0	0	0	0
10	0	0	0	0	0
100	0.02	0.01	0	0.01	0.01
1000	0.27	0.35	0.06	0.08	0.06
10000	2.74	49.8	0.66	0.89	0.62

100 runs
squares	iostr	concat	file	nullio	ciostr
1	0.03	0.01	0.02	0.01	0
10	0.23	0.05	0.07	0.07	0.06
100	2.44	0.62	0.62	0.73	0.58
1000	26.6	34.7	6.47	9.3	6.05

10000 runs
squares	iostr	concat	file	nullio	ciostr
1	2.94	0.52	1.73	0.83	0.72
10	23.8	4.64	7	6.98	5.72

Rough analysis:

The "concat as we go" approach is quite efficient for small amounts of
output, but becomes catastrophic once a certain size is reached.  It
may be too risky for a general purpose function.

The pure Lua iostring implementation does not suffer catastrophic
collapse in the face of large output, but has a roughly 4x overhead
for small amounts of output.

The file-based implementation is quite competitive, at least on Linux.

nullio is mysteriously slower than the file and ciostring implementations.

ciostring wins except for the smallest output, where setup costs
dominate.
]]
