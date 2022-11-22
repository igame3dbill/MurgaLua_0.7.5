w=fltk:Fl_Double_Window(500,400,"browser_filebrowser.lua")

-- set directory separator according to operating system
if murgaLua.getHostOsName() == "windows" then sep="\\" else sep="/" end

Fl_File_Icon:load_system_icons() -- load system icons for Fl_File_Browser()
lua_icon=fltk:Fl_File_Icon("*.lua",1)
lua_icon:load(images.."greenguy.xpm")

this_dir="."

function fb_load_dir()
  Fl:focus(file_browser)
  file_browser:load(this_dir)
  file_browser:value(1)
end

file_browser=fltk:Fl_File_Browser(10,20,350,200,"fltk:Fl_File_Browser\(x,y,w,h,\"label\"\)")
file_browser:align(fltk.FL_ALIGN_TOP)
--file_browser:filter("*.txt")
fb_load_dir(file_browser:label())
file_browser_output=fltk:Fl_Output(10,220,350,30)
file_browser_output:set_output(1)

dir_reload=fltk:Fl_Button(360,20,100,30,"refresh")
dir_reload:callback( function()
  local this_item=0
  if file_browser:value() > 0 then this_item=file_browser:value() end
  file_browser:load(this_dir)
  if this_item > 0 then file_browser:value(this_item) end
end )

dirtoggle=fltk:Fl_Round_Button(360,50,100,40,"directories\nonly")
dirtoggle:callback(
function()
  if dirtoggle:value()==1 then file_browser:filetype(Fl_File_Browser.DIRECTORIES)
  else file_browser:filetype(Fl_File_Browser.FILES) end
end
)

go_up=fltk:Fl_Repeat_Button(360,90,30,30,"@2<")
go_up:shortcut(fltk.FL_Up)
go_up:callback(function(up_cb)
if file_browser:value() > 1 then file_browser:value(file_browser:value()-1) end
file_browser_output:value(file_browser:text(file_browser:value()))
-- keeps arrow keys from jumping from one widget to the next
-- but doesn't always work =op
Fl:focus(file_browser)
end
)
go_dn=fltk:Fl_Repeat_Button(360,120,30,30,"@2>")
go_dn:shortcut(fltk.FL_Down)
go_dn:callback(function(up_cb)
if file_browser:value() < file_browser:size() then file_browser:value(file_browser:value()+1) end
file_browser_output:value(file_browser:text(file_browser:value()))
Fl:focus(file_browser)
end
)

go_button=fltk:Fl_Return_Button(360,220,30,30)
go_button:callback(
function()
  local filename=this_dir..sep..file_browser:text(file_browser:value())
  if fltk.fl_filename_isdir(filename) > 0 then -- if selected item is a directory
  this_dir=filename
  fb_load_dir()
  else file_browser_output:value(file_browser_output:value().." ("..lfs.attributes(filename).mode..")")
  end
end
)
w:show()
Fl:run()
