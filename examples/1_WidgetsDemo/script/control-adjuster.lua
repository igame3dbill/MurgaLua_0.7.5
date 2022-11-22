w=fltk:Fl_Double_Window(300,100,"adjuster.lua")
-- adjuster widget

adj_output = fltk:Fl_Value_Output(50,10,60,20,"@<-  Fl_Value_Output")
adj_output:align(fltk.FL_ALIGN_RIGHT)

adj = fltk:Fl_Adjuster(50,35,200,30,"Fl_Adjuster")
adj:selection_color(fltk.FL_RED) -- color of arrows
adj:align(fltk.FL_ALIGN_BOTTOM) -- position of text label
adj:callback(function(adj_cb)
adj_output:value(adj:value())
end
)

Fl:focus(adj)

w:show()
Fl:run()
