-- roller widget

w=fltk:Fl_Double_Window(300,240,"roller.lua")

roller_output = fltk:Fl_Value_Output(50,20,60,20)
roller_link = fltk:Fl_Round_Button(150,20,60,20,"link")
roller_link:type(fltk.FL_TOGGLE_BUTTON)

roller_roll = fltk:Fl_Roller(50,60,200,60,"drag down to increase value")
roller_roll:step(1)
roller_roll:minimum(-100)
roller_roll:maximum(100)
roller_roll:callback(function(roll_cb)
roller_output:value(roller_roll:value())
if roller_link:value() == 1 then roller_hroll:value(roller_roll:value()) end
end
)

roller_hroll = fltk:Fl_Roller(80,150,140,40,"drag right to increase value")
roller_hroll:step(1)
roller_hroll:minimum(-100)
roller_hroll:maximum(100)
roller_hroll:type(fltk.FL_HORIZONTAL)
roller_hroll:callback(function(hroll_cb)
roller_output:value(roller_hroll:value())
if roller_link:value() == 1 then roller_roll:value(roller_hroll:value()) end
end
)

w:show()
Fl:run()
