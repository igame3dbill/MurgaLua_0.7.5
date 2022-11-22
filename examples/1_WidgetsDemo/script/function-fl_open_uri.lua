-- fl_file_chooser (function)
-- fltk.fl_file_chooser(title,filename_filter,start_path,relative)
-- "relative" is a toggle. Non-zero means the filename returned will be a relative path, and zero returns absolute path. 

w=fltk:Fl_Double_Window(420,80,"fl_open_uri.lua")
open_uri_output=fltk:Fl_Input(10,40,350,30,"@<- URL")
open_uri_output:align(fltk.FL_ALIGN_RIGHT)
open_uri_button=fltk:Fl_Return_Button(10,10,200,30,"fltk.fl_open_uri")
open_uri_button:callback(function(fc_cb)
    fltk.fl_open_uri(open_uri_output:value())
end
)
w:show()
Fl:run()
