-- fl_file_chooser (function)
-- fltk.fl_file_chooser(title,filename_filter,start_path,relative)
-- "relative" is a toggle. Non-zero means the filename returned will be a relative path, and zero returns absolute path. 

w=fltk:Fl_Double_Window(370,80,"fl_file_chooser.lua")
fltk.fl_file_chooser_ok_label("GIMME!") -- optional
file_chooser_output=fltk:Fl_Output(10,40,350,30)
file_chooser_button=fltk:Fl_Return_Button(10,10,200,30,"fltk.fl_file_chooser")
file_chooser_toggle=fltk:Fl_Light_Button(210,10,150,30,"use relative path")
file_chooser_button:callback(function(fc_cb)
 local filename=fltk.fl_file_chooser("pick a file...","*.*",".",file_chooser_toggle:value())
 if filename then file_chooser_output:value(filename) end
end
)
w:show()
Fl:run()
