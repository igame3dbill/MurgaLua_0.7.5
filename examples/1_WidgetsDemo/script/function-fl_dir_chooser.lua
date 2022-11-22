-- fl_dir_chooser (function)
-- fltk.fl_dir_chooser(title,start_path,relative)
-- "relative" is a toggle. Non-zero means the filename returned will be a relative path, and zero returns absolute path. 
-- Using nil as start path will default to the previously chosen path,
-- or current directory if this is the first time the function is called

w=fltk:Fl_Double_Window(370,80,"fl_dir_chooser.lua")
dir_chooser_output=fltk:Fl_Output(10,40,350,30)
dir_chooser_button=fltk:Fl_Return_Button(10,10,200,30,"fltk.fl_dir_chooser")
dir_chooser_toggle=fltk:Fl_Light_Button(210,10,150,30,"use relative path")
dir_chooser_button:callback(function(fc_cb)
 local dirname=fltk.fl_dir_chooser("pick a dir...",nil,dir_chooser_toggle:value())
 if dirname then dir_chooser_output:value(dirname) end
end
)
w:show()
Fl:run()
