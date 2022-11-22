-- fl_input (function)
-- fltk.fl_intput(prompt_text,initial_input_text)

w=fltk:Fl_Double_Window(370,80,"fl_input.lua")
fl_input_output=fltk:Fl_Output(10,40,350,30)
fl_input_button=fltk:Fl_Return_Button(10,10,200,30,"fltk.fl_input")
fl_input_button:callback(function(fc_cb)
 local inpoot=fltk.fl_input("input...",fl_input_output:value())
 if inpoot then fl_input_output:value(inpoot) end
end
)
w:show()
Fl:run()
