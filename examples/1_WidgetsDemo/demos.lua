#!/usr/bin/murgaLua

--[[

  MurgaLua demos of FLTK widgets and functions
  mikshaw 2007-2008
  Requires MurgaLua version 0.6.0 or greater
 
  This program is free software released under the
  Creative Commons "by-nc-sa" license, version 3.0
  http://creativecommons.org/licenses/by-nc-sa/3.0/

  These scripts are much more heavily commented than a typical
  script should be, due to the fact that their purpose is to
  help teach the language itself.
 
--]]

--ext_editor="aterm -e vim"
--ext_editor="notepad"
-- Change the above to your favorite text editor. An alternative to
-- editing the variable is to run the script with this command:
--    murgaLua -e "ext_editor=[[my_editor]]" widgets.lua

-- this will work only if it needs to be murgaLua 0.6+
-- I temporarily replaced the original function with this
-- only because it's less complex
if not murgaLua_Version then --introduced in 0.6.0
  err="This program requires murgaLua 0.6 or newer.\nhttp://www.murga-projects.com/murgaLua/index.html"
  print(arg[0]..": "..err) -- print error in case it's tried in regular Lua
  if fltk then fltk.fl_alert(err) end -- popup error
  os.exit(1)
end

-- this part is used for the progress bar
-- it is run each time a widget demo is displayed
widgets_seen={} -- table of demos that have been shown
progress=0 -- initialize the global progress variable
function check_progress(widget)
  local isit=0 -- initialize a local variable to use as the search result
  for i=1,table.getn(widgets_seen) do
    -- check if the chosen demo is in the "seen" table
    if widget==widgets_seen[i] then
      isit=1
      break
    else
      isit=0
    end
  end
  -- after going through the loop, isit should be 0 if widget wasn't found
  -- in that case, add it to the table
  if isit==0 then table.insert(widgets_seen,widget) end
  local progress=table.getn(widgets_seen)/table.getn(widget_files)*100 -- % viewed of total widgets
  progress=math.floor(progress) -- round it off to an integer for the global variable
  if progress==100 then progbar:selection_color(fltk.FL_GREEN) end -- change color when you've seen them all
  -- progress bar label: <percent>% (<number_of_demos_seen> of <total_number_of_demos>)
  progbar:label(progress.."% ("..table.getn(widgets_seen).." of "..table.getn(widget_files)..")")
  progbar:value(progress)
end

function show_readme()
  list:deselect()
  readme:deactivate()
  save:deactivate()
  editor_buffer:loadfile(arg[0])
  text_buffer:loadfile(appdir..sep.."README")
  text_buffer:append(murgaLua_About) -- note to self: make sure to leave an empty line
  tabs:value(text_tab) -- show the info tab
end

-- expand/collapse browser sections
function toggle(b) -- b is name of browser
local count,open,one,two=1
-- me is the browser index, label is the text of that index
local me,label=b:value(),b:text(b:value())
-- check whether the section is expanded (-) or collapsed (+)
if string.find(label,"%+%s*") then
  open,one,two=0,"%+  ","%-  "
else
  open,one,two=1,"%-  ","%+  "
end
b:text(me,string.gsub(label,one,two)) -- swap + and -
-- while there is text in the vurrnt index and it's not a separator
while b:text(me+count) and not string.match(b:text(me+count),list_sep) do
  -- hide or show the current line
  if open==1 then b:hide(me+count)
  else b:show(me+count)
  end
  count=count+1
end
end

function show_demo()
if list:value()>0 then
  -- if it's a separator
  if string.find(list:text(list:value()),list_sep) then
    -- toggle the list section only with Enter key
    if Fl:event()~=fltk.FL_RELEASE then toggle(list) end
  else
    -- export the code display to a temp file
    editor_buffer:savefile(tempfile)
    -- murgaLua needs to know where images are
    -- io.popen allows the demo to run in a separate process
    -- NOTE: be very careful with the quotes when coding for Windows

	-- Nasty MSYS hack

	-- On Windows popen doesn't work when invoked from some shells
	runResult = io.popen(murgaLua_ExePath.." "..tempfile)

	if murgaLua.getHostOsName() == "windows" and runResult == nil then
		local fdi, fdo = sys.handle(), sys.handle()
		assert(fdi:pipe(fdo))
		local sys_tempfile = string.gsub(tempfile, "^\\","c:\\")
		sys.spawn(murgaLua_ExePath, {sys_tempfile}, pid, nil, fdo, nil, false)
		-- If we close the handles before exit the spawned program will eat CPU
	    -- fdo:close()
		-- fdi:close()
	end

	-- End of nasty hack
    check_progress(list:text(list:value()))
  end
end
end

-- loads the *.lua and *.lua.txt files into text buffers
function showfiles()
  local me=list:text(list:value()) -- text of the selected item
  if me then -- make sure you didn't click on empty space
    if not string.find(me,list_sep) then -- make sure it's not a separator
      readme:activate()
      save:activate()
      editor_buffer:loadfile(scripts..me..".lua")
      text_buffer:loadfile(scripts..me..".lua.txt")
      editor_buffer:insert(0,"images=\[\["..images.."\]\]\n\n") -- just in case images are needed
      -- demos inherit the chosen scheme if it's set
      if Fl:scheme() then editor_buffer:insert(0,"Fl:scheme(\""..Fl:scheme().."\")\n") end
      if string.find(me,"^test%-lua_module") then -- special treatment for module test(s)
        editor_buffer:insert(0,"package.path=\[\["..appdir..sep.."module"..sep.."?.lua;\]\]..package.path\n")
        text_buffer:appendfile(appdir..sep.."module"..sep.."mikstring.lua")
      end
      tabs:value(text_tab) -- show the info tab
      -- show demo on double-click
      if Fl:event() == fltk.FL_RELEASE and Fl:event_clicks() > 0 then show_demo() end
    else -- if it's a separator
      if Fl:event() == fltk.FL_RELEASE then
        toggle(list)
      end
    end
  end
end

-- temp file for demo display
tempfile=os.tmpname()..".lua"
-- set directory separator according to operating system
if murgaLua.getHostOsName() == "windows" then sep="\\" else sep="/" end
-- Get the dirname and basename of the current script
if string.find(arg[0],sep) then
  appdir=string.gsub(arg[0],"(.*)"..sep..".*","%1") -- data directory
  title=string.gsub(arg[0],".*"..sep.."(.*)","%1")
else
  appdir="."
  title=arg[0]
end
-- data directories
scripts=appdir..sep.."script"..sep
images=appdir..sep.."images"..sep

-------------------------------------
---------- BEGIN INTERFACE ----------
-------------------------------------

-- inherit a user-specified FLTK scheme, if it exists
Fl:scheme(NULL)
-- apply user-specified colors (Xdefaults, for example), if they exist
Fl:get_system_colors()
-- inital font size of text viewer and editor
text_size=12
-- load filetype icons for Fl_File_Browser()
Fl_File_Icon:load_system_icons()
-- set a special icon for lua files
lua_icon=fltk:Fl_File_Icon("*.lua",1)
lua_icon:load(images.."greenguy.xpm")
-- change the popup message icon (kinda messy because of the embedded text label)
message_icon=fltk.fl_message_icon() -- create a pointer to message icon
message_icon:image(fltk:Fl_PNG_Image(images.."smiles.png"))
message_icon:align(85) -- set the above image inside top left of icon area (hides the text label)
list_sep="@b@B50@u" -- format string for list separators

ww=640; wh=480 -- window dimensions
col=ww/4; col2=ww-col -- column widths
bh=25 -- button height

w=fltk:Fl_Double_Window(ww,wh,"MurgaLua Demos") -- main window
w:callback(
-- this will run when Esc key or "close" button is pressed
function()
  local confirm=fltk.fl_choice("sure you want to quit?","stay","quit",NULL)
  if confirm == 1 then
    os.remove(tempfile) -- destroy temp file before exiting
    os.exit(0)
  else w:show() end -- cancel
end
)

tiles=fltk:Fl_Tile(0,0,ww,wh) -- resizable columns
tiles:callback(function() w:redraw() end) -- cleans up tab display while dragging
-- grouping the left column gives more control of w:resizable()
listgroup=fltk:Fl_Group(0,0,col,wh)
-- progress bar displays the number of demos that have been viewed
progbar=fltk:Fl_Progress(0,0,col,bh,"murgaLua demos")
progbar:minimum(0)
progbar:maximum(100) -- percent, used in check_progress()

-- list of available widgets
list=fltk:Fl_Hold_Browser(0,bh,col,wh-bh*2)
list:textsize(text_size) -- initial size of text
list:selection_color(8) -- a more neutral color
list:scrollbar_left() -- scrollbar on the left
list:has_scrollbar(2) -- vertical only
list:callback(showfiles)
demo=fltk:Fl_Return_Button(0,wh-bh,col,bh,"show demo")
demo:callback(show_demo)
fltk:Fl_End() -- end of left column

tabw=col2-4 -- width of tabs (2px buffer on each side of tab group)
qtr=tabw/4 -- for sizing/positioning 4 buttons within tabw

tabs=fltk:Fl_Tabs(col,0,col2,wh)
text_tab=fltk:Fl_Group(col,bh,col2,wh-bh,"&Info   ")
text_buffer=fltk:Fl_Text_Buffer()
text_display=fltk:Fl_Text_Display(col+2,bh+2,tabw,wh-bh*2-4)
text_display:buffer(text_buffer)
text_display:textsize(text_size) -- initial size of text
text_display:selection_color(fltk.FL_BLACK)
readme=fltk:Fl_Button(col,wh-bh,col2,bh,"show &readme and main script source")
readme:callback(show_readme)
fltk:Fl_End() -- end of info tab

source_tab=fltk:Fl_Group(col,bh,col2,wh-bh,"&Source   ")
editor_buffer=fltk:Fl_Text_Buffer()
editor=fltk:Fl_Text_Editor(col+2,bh+2,tabw,wh-bh*2-4)
editor:textfont(fltk.FL_SCREEN) -- reading code SUCKS with a variable-width font
editor:textsize(text_size) -- initial size of text
editor:buffer(editor_buffer)
exted=fltk:Fl_Button(col,wh-bh,col,bh,"&external editor")
if not ext_editor then exted:deactivate() end
exted:callback(
function()
if list:value()>0 then
    editor_buffer:savefile(tempfile)
    os.execute(ext_editor.." "..tempfile)
    editor_buffer:loadfile(tempfile)
    os.remove(tempfile)
end
end
)
save=fltk:Fl_Button(col*3,wh-bh,col,bh,"save &as...")
save:callback(
function()
  local filename=fltk.fl_file_chooser("save code as...","*.lua","."..sep..list:text(list:value())..".lua",0)
  if filename then
    local output=io.open(filename,"w+")
    if output then
      output:close()
      editor_buffer:savefile(filename)
    end
  end
end
)
fltk:Fl_End() -- end of source tab

man_tab=fltk:Fl_Group(col,bh,col2,wh-bh,"&Documentation  ")
help=fltk:Fl_Help_View(col+2,bh+2,tabw,wh-bh*2-4)
help:textsize(text_size) -- initial size of text
help:textfont(0) -- serif looks crappy in Help_View
man=fltk:Fl_Button(col,wh-bh,col,bh,"Lua &manual")
man:callback( function() help:load(appdir..sep.."doc"..sep.."lua"..sep.."index.html"); help:take_focus() end)
snip=fltk:Fl_Button(col*2,wh-bh,col,bh,"&code snippets")
snip:callback(function() help:load(appdir..sep.."doc"..sep.."snippets.html"); help:take_focus() end )
snew=fltk:Fl_Button(col*3,wh-bh,col,bh,"&what's new")
snew:callback(function() help:load(appdir..sep.."doc"..sep.."whatsnew.html"); help:take_focus() end )
fltk:Fl_End() -- end of manual tab

options_tab=fltk:Fl_Group(col,bh,col2,wh-bh,"&Options  ")
slug=fltk:Fl_Box(col+2,wh-bh*3,tabw,bh*2) -- prevents other widgets from stretching
-- DEBUGGING: keep the slug border while adding options for visual alignment
--slug:box(fltk.FL_BORDER_BOX)
fsizer=fltk:Fl_Hor_Value_Slider(col+2,bh*2,tabw,bh,"font size")
fsizer:align(5)
fsizer:minimum(8)
fsizer:maximum(24)
fsizer:step(1)
fsizer:value(text_size)
fsizer:callback(
function()
  list:textsize(fsizer:value())
  text_display:textsize(fsizer:value())
  editor:textsize(fsizer:value())
  help:textsize(fsizer:value())
  list:redraw()
end
)
scheme_label=fltk:Fl_Box(col,bh*3.5,qtr,bh,"scheme:")
scheme_label:align(20)
scheme_p=fltk:Fl_Radio_Round_Button(col+qtr,bh*3.5,qtr,bh,"Plastic")
scheme_g=fltk:Fl_Radio_Round_Button(col+qtr*2,bh*3.5,qtr,bh,"Gtk+")
scheme_n=fltk:Fl_Radio_Round_Button(col+qtr*3,bh*3.5,qtr,bh,"None")
scheme_p:callback(function() Fl:scheme("plastic") end)
scheme_g:callback(function() Fl:scheme("gtk+") end)
scheme_n:callback(function() Fl:scheme("none") end)
fltk:Fl_End() -- end of options tab
fltk:Fl_End() -- end of tab group
fltk:Fl_End() -- end of tiles

-------------------------------------
----------  END INTERFACE  ----------
-------------------------------------

cat={} -- holds the list index of each header
list:add(list_sep.."-  1: widgets"); cat[1]=list:size() -- add the first separator
-- a new table is created for the sole purpose of making the
-- files display alphabetically
widget_files={} -- all *.lua filenames in the script directory
prop_temp={} -- properties files
funk_temp={} -- function files
test_temp={} -- testing files
for i in lfs.dir(scripts) do
  if string.find(i,"%.lua$") then table.insert(widget_files,i) end
end
table.sort(widget_files) -- alphabetize the file list
for i,v in ipairs(widget_files) do -- add filenames to list (no extension)
  -- categorize the demos
  if string.find(v,"^test-") then
    table.insert(test_temp,v)
  elseif string.find(v,"^prop-") then
    table.insert(prop_temp,v)
  elseif string.find(v,"^function-") then
    table.insert(funk_temp,v)
  else
    list:add(string.gsub(v,"%.lua$","")) -- widgets only
  end
end
-- add all the non-widget demos
-- "n" is used to associate the list header with a list index
function organize(table,label,n)
list:add(list_sep..label); cat[n]=list:size()
  for i,v in ipairs(table) do
    list:add(string.gsub(v,"%.lua$","")) -- cut off the filename extension
    list:hide(list:size()) -- collapse (optional)
  end
end
organize(prop_temp,"+  2: properties",2)
organize(funk_temp,"+  3: functions",3)
organize(test_temp,"+  4: testing",4)

-- offscreen buttons for global keyboard control
-- there may be a better way to make buttons global, but I don't know it
head={} -- buttons to select list headers
-- selected by the number key associated with its index in the cat table
for i=1,table.getn(cat) do
  head[i]=fltk:Fl_Button(ww,wh,0,0,"&"..i)
  head[i]:callback(function()
  local n=string.sub(head[i]:label(),2) -- strip off "&"
  list:value(cat[tonumber(n)]) -- select the separator with index n
  list:take_focus()
  end)
end
list_focus=fltk:Fl_Button(ww,wh,0,0,"&l")
list_focus:callback(function() list:take_focus() end)
text_focus=fltk:Fl_Button(ww,wh,0,0,"&i")
text_focus:callback(function() tabs:value(text_tab); text_display:take_focus() end)
source_focus=fltk:Fl_Button(ww,wh,0,0,"&s")
source_focus:callback(function() tabs:value(source_tab); editor:take_focus() end)
doc_focus=fltk:Fl_Button(ww,wh,0,0,"&d")
doc_focus:callback(function() tabs:value(man_tab); help:take_focus() end)
opt_focus=fltk:Fl_Button(ww,wh,0,0,"&o")
opt_focus:callback(function() tabs:value(options_tab); fsizer:take_focus() end)
man_focus=fltk:Fl_Button(ww,wh,0,0,"&m")
man_focus:callback(function() tabs:value(man_tab); man:do_callback() end)
snip_focus=fltk:Fl_Button(ww,wh,0,0,"&c")
snip_focus:callback(function() tabs:value(man_tab); snip:do_callback() end)
snew_focus=fltk:Fl_Button(ww,wh,0,0,"&w")
snew_focus:callback(function() tabs:value(man_tab); snew:do_callback() end)
readme_focus=fltk:Fl_Button(ww,wh,0,0,"&r")
readme_focus:callback(show_readme)

show_readme()
-- precise control of resize can be tedious
w:resizable(listgroup)
w:resizable(tabs)
listgroup:resizable(list)
tabs:resizable(text_tab)
tabs:resizable(source_tab)
tabs:resizable(man_tab)
tabs:resizable(options_tab)
text_tab:resizable(text_display)
source_tab:resizable(editor)
man_tab:resizable(help)
options_tab:resizable(slug)
w:show() -- show the main interface
Fl:run()
