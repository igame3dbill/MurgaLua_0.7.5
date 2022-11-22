--[[

  murgaLua
  Copyright (C) 2006-12 John Murga
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the :
  
    Free Software Foundation, Inc.
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
  
]]

--
-- Quick override to the FLTK functions
--

local base = _G

murgaLua__global = {}

function getMenu(self)
	if (murgaLua__global[self:serial()]) then
		return murgaLua__global[self:serial()].menu
	else
		return nil
	end
end

bind_lua_addtovtable(Fl_Menu_Item, 'getMenu', getMenu)

function setMenu(self, parentMenu)
	if (murgaLua__global[self:serial()]) then
		murgaLua__global[self:serial()].menu = parentMenu
	else
		murgaLua__global[self:serial()] = {menu = parentMenu}
	end
end

bind_lua_addtovtable(Fl_Menu_Item, 'setMenu', setMenu)

function getUserData(self, userData)
	key = self:serial()
	if (userData) then -- Set userdata
		if (murgaLua__global[key]) then
			murgaLua__global[key].user_data = userData
		else
			murgaLua__global[key] = {user_data = userData}
		end
	else -- Get userdata
		if (murgaLua__global[key]) then
			return murgaLua__global[key].user_data
		else
			return nil
		end
	end
end

bind_lua_addtovtable(Fl_Widget, 'user_data', getUserData)
bind_lua_addtovtable(Fl_Menu_Item, 'user_data', getUserData)

function add(self, label, shortcut, callback, userdata, flags)
	base.assert(label, "bad arguments in function call")
	menuItemIndex = self:add_overriden(label)
	menuItemInstance = self:menu(menuItemIndex)
	menuItemInstance:setMenu(self)
	if (shortcut) then self:shortcut(menuItemIndex, shortcut) end
	if (callback) then menuItemInstance:callback(callback) end
	if (userdata) then menuItemInstance:user_data(userdata) end
	if (flags) then self:mode(menuItemIndex, flags) end
	return menuItemIndex
end

bind_lua_addtovtable(Fl_Menu_, 'add', add)


module("murgaLua.debug", package.seeall)

-- Table browsing code

-- everything is local so it won't show up in the Global environment
local w,outpoot,title,backbutt,current_table
local my_depth=0
local my_level={}
local my_title={}
local my_line={}

-- text colors
local col_tab="@b"
local col_func="@C1"
local col_str="@C4"
local col_num="@C13"
local col_usr="@C8@B17"

local function lookittable()
  outpoot:clear()
  local my_value,my_string
  local tmptab={} -- temporary table for alphabetizing the list of my_string's
  for k,v in pairs(current_table) do
    if type(v)=="string" then
      my_value=col_str..tostring(k).."\t"..string.gsub(tostring(v),"\n.*","")
      table.insert(tmptab,my_value)
      my_string=string.gsub(tostring(v),".-\n(.*)","%1")
      my_value=0
      for line in string.gmatch(my_string,".-\n") do
        my_value=1+my_value
        -- for multiline strings, pad numbers with zeros for proper sorting.
        table.insert(tmptab,col_str..tostring(k)..string.format('%03d',my_value).."\t"..line)
      end
    else
      my_value=tostring(k).."\t"..tostring(v)
      if     type(v)=="table" then my_string=col_tab..tostring(k)
      elseif type(v)=="function" then my_string=col_func..my_value
      elseif type(v)=="number" then my_string=col_num..my_value
      elseif type(v)=="userdata" then my_string=col_usr..my_value
      else my_string=tostring(k)
      end
      table.insert(tmptab,my_string)
    end --if
  end
  table.sort(tmptab) -- alphabetize
  for i,v in ipairs(tmptab) do outpoot:add(v) end -- add the sorted list to the browser
  title:label(my_title[my_depth])
  if my_depth==0 then backbutt:deactivate() else backbutt:activate() end
  outpoot:middleline(my_line[my_depth])
end

local function move_forward(k,v)
  my_depth=my_depth+1 -- move up a level
  my_level[my_depth]=current_table
  my_title[my_depth]=tostring(k).." ("..type(v)..")"
  my_line[my_depth]=1
  lookittable()
end

local function move_back()
if my_depth > 0 then
  current_table=my_level[my_depth-1]
  my_depth=my_depth-1
  lookittable()
end
end

local function which_is_it()
  local this_text=outpoot:text(outpoot:value())
  if outpoot:value() > 0 and type(current_table) == "table" then
    my_line[my_depth]=outpoot:value()
    -- Compare the browser text with each key in current_table until a match is found
    -- This could probably be streamlined
    for k,v in pairs(current_table) do
      -- it's a table
      if this_text == col_tab..tostring(k) then
        my_level[my_depth]=current_table --set a table to return to with "back"
        current_table=v
    move_forward(k,v)
        break
      end
      -- it's userdata
      if string.find(this_text,"^"..col_usr..tostring(k)) then
        my_level[my_depth]=current_table
        current_table=getmetatable(v)
    move_forward(k,v)
        break
      end
      -- it's a function
      if string.find(this_text,"^"..col_func..tostring(k))  then
        my_level[my_depth]=current_table
        -- is there a way to get more useful info?
        current_table=debug.getinfo(v,"nSlufL")
    move_forward(k,v)
        break
      end
    end
  end
end

function showTable(tbl)
	local ww=400
	local wh=360

	local win=fltk:Fl_Double_Window(ww,wh,"DEBUG : Show table contents")

	outpoot=fltk:Fl_Select_Browser(10,40,ww-20,wh-50)
	if Fl_Browser.column_widths then outpoot:column_widths({(ww-20)/2,0}) end
	outpoot:selection_color(0)
	outpoot:callback(which_is_it)

	title=fltk:Fl_Box(90,10,ww-100,30)
	title:box(fltk.FL_THIN_UP_BOX)

	backbutt=fltk:Fl_Button(10,10,80,30,"@<- back")
	backbutt:callback(move_back)

	win:resizable(outpoot)
	--current_table=_G
	current_table=tbl
	-----------------
	my_title[my_depth]="Top Table"
	my_line[my_depth]=1
	lookittable()
	win:show()
	Fl:run()
end

