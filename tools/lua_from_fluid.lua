-- murgaLua generator from FLUID project
-- Usage:  
--   murgaLua  lua_from_fluid.lua  input.fl  [output.lua]

-- Copyright (c) 2008 Patrick Rapin by Olivetti Engineering SA
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- Configuration variables. Change the fields of the configuration table to 
-- match your preferences. You can also override them on the command line.
local default_configuration = {
	-- If 'shebang' is defined as a file path to the Lua interpreter, a Unix shebang will
	-- be added at top of the file. If the string contains backslashes or end in .exe,
	-- a batch header is added to turn the script into a valid Windows .BAT file.
	shebang = nil,
	
	-- Indentation parameter. If it is a number, that number of spaces will be used 
	-- for each level. If it is a string, it is places once for each level.
	indentation = 2,
	
	-- Current widget variable name. FLUID normally uses "o" when generating code.
	currentvar = "o",
	
	-- Internationalization text function. If defined to a function name, every 
	-- text label will be passed to that function. If not defined, the parameter in
	-- "Project Settings... Internationalization... GNU gettext... Function" will be used.
	textfilter = nil,
	
	-- If set to "syntax", the syntax of the generated file is checked at the end.
	-- If set to "run", the generated script is run
	check = "none",
}

-- Global variables
local Grammar, source_file, configuration
-- Forward declaration of functions
local DecodeOption, ReadFile, BuildGrammar, GetItem, ParseItem, ParseGroup, ParseAttributes
-- Table of functions for rendering
local Write, FindMembers = {}, {}
-- Functions to output data into a file or stdout
local Output, OpenOutput, WriteScript, WriteVariables, GetAccessMode

-- In this function are concentrated most of the bugs... The list try to enumerate all
-- 
function BuildGrammar()
	local fields = { name = 'string', body = 'group', attr = 'widget'  }
	local types = { { 'name', 'attr' }, { 'name', 'attr', 'body' }, { 'name' } }
	local list1 = {  'comment', 'code', 'decl', 'MenuItem', 'Fl_' }
	local list2 = { 'class', 'codeblock', 'declblock', 'Fl_Window', 'Fl_Group', 'widget_class',
		'Fl_Choice', 'Fl_Input_Choice', 'Submenu', 'Function', 'Fl_Scroll', 'Fl_Menu_Bar', 
		'Fl_Tabs', 'Fl_Menu_Button', 'Fl_Wizard', 'Fl_Pack', 'Fl_Tile' }
	local list3 = { 'version', 'header_name', 'code_name', 'gridx', 'gridy', 'snap', 
		'i18n_type', 'i18n_include', 'i18n_function', 'i18n_file', 'i18n_set' }
	local str_methods = { 'tooltip', 'type', 'box', 'down_box', 'xclass' }
	local str_ext_methods = { 'label', 'callback', 'after', 'image', 'user_data', 'class',
		'code0', 'code1', 'code2', 'code3', ':' }
	local number_methods = { 'labelsize', 'align', 'value', 'textcolor', 'selection_color',
		'labelcolor', 'color', 'labelfont', 'textfont', 'when', 'textsize', 'step', 
		'maximum', 'minimum' }
	local img_list = { 'GIF', 'BMP', 'JPEG', 'XBM', 'XPM', 'PNG' }
	local composed_list = { 'Fl_Window', 'Fl_Browser', 'Fl_Input', 'Fl_Output' }
	local group_list = { 'Fl_Group', 'Fl_Browser', 'Fl_Color_Chooser', 'Fl_Help_View', 
		'Fl_Input_Choice', 'Fl_Pack', 'Fl_Scroll', 'Fl_Tabs', 'Fl_Spinner', 
		'Fl_Text_Display', 'Fl_Tile', 'Fl_Window', 'Fl_Wizard' }
	local images = { BM='BMP', PPM='PNM', PGM='PNM', PBM='PNM', JPG='JPEG' }
	local FLUID = {Normal=0, Vertical=0, Dot=0, Integer=0, normal=0, No_Select=0, BOTH=0, 
		Toggle=1, Horizontal=1, Simple=1, Line=1, Float=1, popup1=1, Select=1, HORIZONTAL=1, Vert_Fill=2,
		Fill=2, Int=2, popup2=2, Hold=2, VERTICAL=2, Horz_Fill=3, popup3=3, Multi=3,
		Vert_Knob=4, Multiline=4, popup12=4, Horz_Knob=5, Secret=5, popup23=5, Radio=102,
		HORIZONTAL_ALWAYS=5, popup13=6, VERTICAL_ALWAYS=6, popup123=7, BOTH_ALWAYS=7,
		['Vert Fill']=2, ['Horz Fill']=3, ['Vert Knob']=4, ['Horz Knob']=5 }
	local menu_const = { Toggle = 2, Radio = 8 }
	local attr = { xywh = 'list', size_range = 'list' }
	local methods, composed, groups = {}, {}, {}
	local grammar = { attr = attr, const = FLUID, images = images, groups = groups,
		methods = methods, composed = composed, menu_const = menu_const }
	
	for k,v in pairs(fields) do fields[k] = { k, v } end
	for _,i in pairs(types) do for j=1,#i do i[j] = fields[i[j]] end end
	for _,k in pairs(list1) do grammar[k] = types[1] end
	for _,k in pairs(list2) do grammar[k] = types[2] end
	for _,k in pairs(list3) do grammar[k] = types[3] end
	for _,k in pairs(str_methods) do attr[k] = 'string' end
	for _,k in pairs(str_ext_methods) do attr[k] = 'string' end
	for _,k in pairs(number_methods) do attr[k] = 'number' end
	for _,k in pairs(img_list) do images[k] = k end
	for _,k in pairs(str_methods) do methods[k] = true end
	for _,k in pairs(number_methods) do methods[k] = true end
	for _,k in pairs(composed_list) do composed[k] = true end
	for _,k in pairs(group_list) do groups[k] = true end
	return grammar
end

function ReadFile(filename)
	local file = assert(io.open(filename, 'rt'))
	local data = file:read("*a")
	file:close()
	-- Replace escaped characters to simplify parsing
	data = data:gsub("\\([^%d])", function(c) return string.format("\\%03d", string.byte(c)) end)
	return data
end

function GetItem(pos, type, parent)
	local p1, p2, item = source_file:find("^%s*([%w_%.%-<>:]+)%s+", pos)
	if p1 then 
		if type == 'number' then
			return tonumber(item), p2+1
		end
		assert(type == 'string', type)
		return item, p2+1
	end
	p1, p2, item = source_file:find("^%s*(%b{})%s+", pos)
	assert(p1)
	local content = item:sub(2,-2)
	if type == 'string' then
		item = content:gsub("\\(%-?%d%d%d)", function(val) return string.char(val) end)
	elseif type == 'list' then
		item = {}
		for k in content:gmatch("%-?%d+") do
			item[#item+1] = tonumber(k)
		end
	elseif type == 'group' then
		item = ParseGroup(pos+1, pos+#content, parent)
	elseif type == 'widget' then
		item = ParseAttributes(pos+1, pos+#content)
	end
	return item, p2+1
end

function ParseItem(pos, parent)
	local item, key = {}
	key, pos = GetItem(pos, 'string', item)
	item.key = key
	local modes = Grammar[key]
	if not modes and key:match("Fl_") then
		modes = Grammar.Fl_
	end
	assert(modes, key)
	for _,mode in pairs(modes) do
		local name, type = mode[1], mode[2]
		key, pos = GetItem(pos, type, item)
		item[name] = key
	end
	return item, pos
end

function ParseGroup(pos, endpos, parent)
	local item
	local group = {}
	while pos < endpos do
		item, pos = ParseItem(pos, group)
		item.parent = parent
		group[#group+1] = item
	end
	return group
end

function ParseAttributes(pos, endpos)
	local item, key
	local attr = {}
	while pos < endpos do
		key, pos = GetItem(pos, 'string')
		local type = Grammar.attr[key]
		if type then
			item, pos = GetItem(pos, type)
			attr[key] = item
		else
			attr[key] = true
		end
	end
	return attr
end

function OpenOutput(out)
	if type(configuration.indentation) == 'number' then
		configuration.indentation = string.rep(" ", configuration.indentation)
	end
	local indstr = setmetatable({}, {__index = function(t, k)
		t[k] = string.rep(configuration.indentation, k)
		return t[k]
	end})
	local fended = true
	function Output(ind, ...)
		if fended then 
			out[#out+1] = indstr[ind]
		end
		local str = string.format(...)
		-- Indent all code, except multi-line strings
		if not str:match("[^%-]%[=*%[.*\n.*%]=*%]") then
			str = str:gsub("([^\\\n]\n)(.)", "%1"..indstr[ind].."%2")
		end
		out[#out+1] = str
		fended = str:match("\n$")
	end
end

function Write.Function(t, ind)
	Output(ind, "function %s\n", t.name)
	t.varname = "res"
	Write.group(t.body, ind+1)
	local names = {}
	for _,i in ipairs(t.body) do
		names[#names+1] = i.varname
	end
	if #names > 0 then
		Output(ind+1, "return %s\n", table.concat(names, ", "))
	end
	Output(ind, "end\n\n")
end

function Write.widget(t, ind)
	local fgroup = Grammar.groups[t.key]
	if Grammar.composed[t.key] and t.attr.type then
		t.key = t.key:sub(1,3)..t.attr.type..t.key:sub(3,-1)
		t.attr.type = nil
	end
	local class = t.attr.class or t.key
	if class:match("^Fl_") then class = "fltk:"..class end
	local x, y, w, h = unpack(t.attr.xywh)
	local name = configuration.currentvar
	t.xoffset = t.parent.xoffset
	t.yoffset = t.parent.yoffset
	Output(ind, "local %s = %s(%s%d, %s%d, %d, %d", name, 
		class, t.xoffset or "", x, t.yoffset or "", y, w, h)
	if t.attr.label then Output(ind, ", %s%q", configuration.textfilter, t.attr.label) end
	Output(ind, ")\n")

	t.varname = name
	if #t.name > 0 then 
		Output(ind, "%s = %s\n", t.name, name)
		t.varname = t.name
	end
	for k,v in pairs(t.attr) do
		if Grammar.methods[k] then
			Output(ind, "%s:%s(", name, k)
			if type(v) == 'number' then Output(ind, "%d", v)
			elseif Grammar.const[v] then Output(ind, "%d", Grammar.const[v])
			elseif v:match("^[A-Z_]+$") then Output(ind, "fltk.FL_%s", v)
			else Output(ind, "%q", v)
			end
			Output(ind, ")\n")
		end			
	end
	local img = t.attr.image
	if img then
		local ext = img:match("%.(%a+)$"):upper()
		Output(ind, "%s:image(fltk:Fl_%s_Image(%q))\n", name, Grammar.images[ext], img)
	end
	if t.attr.modal then Output(ind, "%s:set_modal()\n", name) end
	if t.attr.non_modal then Output(ind, "%s:set_non_modal()\n", name) end
	for i=0,3 do
		local l = t.attr['code'..i]
		if l then Output(ind, "%s\n", l) end
	end
	if t.attr.noborder then Output(ind, "%s:clear_border()\n", name) end
	if t.attr.size_range then Output(ind, "%s:size_range(%s)\n", name, table.concat(t.attr.size_range, ", ")) end
	local cb = t.attr.callback
	if cb then
		if cb:match("^[%w_]+$") then
			Output(ind, "%s:callback(%s)\n", name, cb)
		else
			Output(ind, "%s:callback(function(self)\n", name)
			Output(ind+1, "%s\n", cb)
			Output(ind, "end)\n")
		end
	end
	if t.body and #t.body>0 then
		Output(ind, "do\n")
		Write.group(t.body, ind+1)
		Output(ind, "end\n")
	end
	if fgroup then Output(ind, "%s['endd'](%s)\n", name, name) end
	if t.attr.resizable then 
		if t.parent.key ~= "Function" then
			Output(ind, "Fl_Group.current():resizable(%s)\n", name) 
			t.parent.resized = true
		elseif not t.resized then
			Output(ind, "%s:resizable(%s)\n", name, name) 
		end
	end
end

function Write.Submenu(t, ind)
	if t.parent.path then
		t.path = t.parent.path.."/"..t.attr.label
	else
		t.path = t.attr.label
	end
	Write.group(t.body, ind)
end

function Write.MenuItem(t, ind)
	if t.parent.path then
		t.path = t.parent.path.."/"..t.attr.label
	else
		t.path = t.attr.label
	end
	local w = t
	while not w.varname do
		w = w.parent
	end
	local cb = t.attr.callback
	Output(ind, "%s:add(%q", w.varname, t.path)
	if cb then
		if cb:match("^[%w_]+$") then
			Output(ind, ", nil, %s", cb)
		else
			Output(ind, ", nil, function(self)\n")
			Output(ind+1, "%s\n", cb)
			Output(ind, "end")
		end
	end
	local type = Grammar.menu_const[t.attr.type]
	if type then
		Output(ind, string.rep(", nil", cb and 1 or 3))
		Output(ind, ", %s", type)
	end
	Output(ind, ")\n")
end

function Write.group(t, ind)
	for _,i in ipairs(t) do
		if Write[i.key] then
			Write[i.key](i, ind)
		elseif i.key:match("^Fl_") then
			Write.widget(i, ind)
		end
	end
end

function Write.comment(t, ind)
	local text = "\n"..t.name
	text = text:gsub("(\n%s*)//", "%1--")
	text = text:gsub("(\n%s*)([^-][^-])", "%1-- %2")
	Output(ind, "%s\n", text:sub(2,-1))
end

function Write.codeblock(t, ind)
	Output(ind, "%s\n", t.name)
	Write.group(t.body, ind+1)
	Output(ind, "%s\n", t.attr.after or "end")
end

function Write.code(t, ind)
	Output(ind, "%s\n", t.name)
end

function Write.decl(t, ind)
end

function Write.declblock(t, ind)
	Output(ind, "%s\n", t.name)
	Write.group(t.body, ind+1)
	Output(ind, "%s\n", t.attr.after or "end")
end

function Write.class(t, ind)
	Output(ind, "function %s(arg)\n", t.name)
	Output(ind+1, "local %s = {}\n", t.name)
	Output(ind+1, "-- copy arguments and set environment\n")
	Output(ind+1, "for k,v in pairs(arg or {}) do %s[k] = v end\n", t.name)
	Output(ind+1, "setfenv(1, setmetatable(%s, {__index = getfenv(1)}))\n\n",	t.name, t.name)
	local vars = {}
	FindMembers.group(t.body, vars)
	WriteVariables(ind+1, vars, "class members")	
	Output(ind+1, "-- Create member functions\n"	)
	Write.group(t.body, ind+1)
	if t.constructor then 
		Output(ind+1, "for _,i in ipairs {%s} do i:show() end\n", t.constructor)
	end
	Output(ind+1, "return %s\n", t.name)
	Output(ind, "end\n\n")
end

function Write.widget_class(t, ind)
	local vars = {}
	Output(ind, "function %s(...)\n", t.name)
	Output(ind+1, "-- create base widget and modify its metatable\n")
	if not (t.attr.class or ""):match("_Window$") then
		t.xoffset = "_x + "
		t.yoffset = "_y + "
		Output(ind+1, "local _x, _y = ...\n")
	end
	Output(ind+1, "local %s = fltk:%s(...)\n", t.name, t.attr.class or "Fl_Group")
	Output(ind+1, "local m = getmetatable(%s)\n", t.name)
	Output(ind+1, "local _G = _G\n")	
	Output(ind+1, "if not m.__members then\n")
	Output(ind+2, "m.__members = {}\n")
	Output(ind+2, "m.__newindex = function(u,k,v) (m.__members[u] or m)[k]=v end\n")
	Output(ind+2, "m.__index = function(u,k) return (m.__members[u] or m)[k] end\n")
	Output(ind+1, "end\n")
	Output(ind+1, "m.__members[%s] = setmetatable({}, {__index = function(t,k)\n", t.name)
	Output(ind+2, "return m[k] or _G[k]\n")
	Output(ind+1, "end})\n")
	Output(ind+1, "setfenv(1, m.__members[%s])\n\n", t.name)

	FindMembers.group(t.body, vars)
	WriteVariables(ind+1, vars, "class members")	
	Output(ind+1, "-- Create member functions and widgets\n"	)
	Write.group(t.body, ind+1)

	Output(ind+1, "-- Patch member functions to accept both . and : syntax\n"	)
	Output(ind+1, "local t = m.__members[%s]\n", t.name)
	Output(ind+1, "for k,v in pairs(t) do\n")
	Output(ind+2, "if _G.type(v) == 'function' then\n")
	Output(ind+3, "t[k] = function(self, ...)\n")
	Output(ind+4, "if self == %s then return v(...)\n", t.name)
	Output(ind+4, "else return v(self, ...) end\n")
	Output(ind+3, "end\n")
	Output(ind+2, "end\n")
	Output(ind+1, "end\n")
	
	Output(ind+1, "return %s\n", t.name)
	Output(ind, "end\n\n")
end

function FindMembers.group(t, list)
	for _,i in ipairs(t) do
		if FindMembers[i.key] then
			FindMembers[i.key](i, list)
		elseif i.key:match("^Fl_") then
			FindMembers.widget(i, list)
		end
	end
end

function GetAccessMode(t, mode)
	for _,i in ipairs {'private', 'protected', 'public'} do
		if t.attr[i] then mode = i end
	end
	return mode
end

function FindMembers.Function(t, list)
	if t.name == "" then t.name = "make_window()" end
	local name = t.name:match("[%w_]+")
	if t.parent.name == name then -- constructor
		t.name = "__constructor()"
		t.parent.constructor = t.name
	else
		list[#list+1] = { name, GetAccessMode(t, 'public') }
	end
	FindMembers.group(t.body, list)
end

function FindMembers.class(t, list)
	list[#list+1] = { t.name, 'public' }
end
FindMembers.widget_class = FindMembers.class

function FindMembers.widget(t, list)
	if t.name:match("^[%w_]+[%.%[]") then
		list[#list+1] = { t.name:match("^[%w_]+"), GetAccessMode(t, 'public'), "{}" }
	elseif t.name:match("^[%w_]+$") then
		list[#list+1] = { t.name, GetAccessMode(t, 'public') }
	end
	if t.body then
		FindMembers.group(t.body, list)
	end
end

function FindMembers.decl(t, list)
	list[#list+1] = { t.name, GetAccessMode(t, 'private') }
end

function WriteVariables(ind, vars, type)
	if #vars == 0 then return end
	local defined = {}
	Output(ind, "-- Declaration of %s\n", type)
	for _,i in pairs(vars) do
		if defined[i[1]] then
		elseif i[2] == 'public' then
			Output(ind, "%s = %s or %s\n", i[1], i[1], i[3] or "nil")
		else
			Output(ind, "local %s = %s\n", i[1], i[3] or "nil")
		end
		defined[i[1]] = true
	end
	Output(ind, "\n")
end

function WriteScript(tree)
	local vars = {}
	local ind = 0
	local fct = configuration.textfilter
	for _,k in pairs(tree) do
		if k.key == 'i18n_function' then fct = fct or k.name end
	end
	configuration.textfilter = fct and fct.." " or ""
	if configuration.shebang then
		if configuration.shebang:match("\\") or configuration.shebang:match("%.[eE][xX][eE]") then
			Output(ind, "rem=[[ Start Lua script\n")
			Output(ind, "@echo off\n")
			Output(ind, "%s %%0 %%*\n", configuration.shebang)
			Output(ind, "exit /B\n]]\n\n")
		else
			Output(ind, "#! %s\n", configuration.shebang)
		end
	end
	FindMembers.group(tree, vars)
	WriteVariables(ind, vars, "global variables")
	Write.group(tree, ind)
	for _,i in ipairs(vars) do
		if i[1] == 'main' then
			Output(ind, "main(...)\n")
		elseif i[1] == 'make_window' then
			Output(ind, "for _,i in ipairs {make_window()} do i:show() end\nFl:run()\n")
		end
	end
end

function DecodeOption(arg)
	local config = {}
	for i=1,#arg,2 do
		if arg[i]:sub(1,1) ~= "-" then
			return config, unpack(arg, i)
		end
		local val = arg[i+1]
		if tonumber(val) then val = tonumber(val) end
		config[arg[i]:sub(2)] = val
	end
end

-- Main global function
function LuaFromFluid(infile, outfile, config)
	configuration = {}
	for k,v in pairs(default_configuration) do configuration[k] = v end
	for k,v in pairs(config or {}) do configuration[k] = v end
	Grammar = BuildGrammar()
	source_file = ReadFile(infile)
	local tree = ParseGroup(source_file:find("\n")+1, #source_file, {})
	local outdata = {}
	OpenOutput(outdata)
	WriteScript(tree)
	outdata = table.concat(outdata)
	if outfile == '-' then
		print(outdata)
	elseif outfile then
		local file = io.open(outfile, "wt")
		file:write(outdata)
		file:close()
	end
	if configuration.check == 'syntax' then
		assert(loadstring(outdata, "@"..(outfile or infile)))
	elseif configuration.check == 'run' then
		assert(loadstring(outdata, "@"..(outfile or infile)))()
	end
	return outdata
end

if arg and #arg > 0 then 
	local config, infile, outfile = DecodeOption(arg)
	LuaFromFluid(infile, outfile, config)
end
