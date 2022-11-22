window = fltk:Fl_Window(505, 145, "My first little app")

button1=fltk:Fl_Button(5, 5, 310, 135, "My First Button")

group = fltk:Fl_Group(320, 5, 180, 135, "")

nothing=fltk:Fl_Box(320, 5, 180, 35, "")
button2=fltk:Fl_Button(320, 65, 180, 35, "Load a picture")
button3=fltk:Fl_Button(320, 105, 180, 35, "Quittin Time")

group:add(nothing)
group:add(button2)
group:add(button3)

group:resizable(nothing)
window:resizable(button1)

window:show()
Fl:run()