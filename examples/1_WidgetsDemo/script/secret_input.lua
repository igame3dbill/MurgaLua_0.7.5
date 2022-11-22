w=fltk:Fl_Double_Window(450,80,"secret_input.lua")

fl_input=fltk:Fl_Secret_Input(100,10,250,30,"input")
fl_input:callback(
function(fl_input_cb)
fl_input_output:value(fl_input:value())
end
)
fl_input_output=fltk:Fl_Output(100,40,250,30,"output")
w:show()
Fl:run()
