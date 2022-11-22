w=fltk:Fl_Double_Window(380,400,"buttons_radio.lua")

rbutt1=fltk:Fl_Button(10,10,360,30,"Fl_Button (type FL_RADIO_BUTTON)")
rbutt2=fltk:Fl_Radio_Button(10,50,360,30,"Fl_Radio_Button")
rbutt3=fltk:Fl_Round_Button(10,90,360,30,"Fl_Round_Button (type FL_RADIO_BUTTON)")
rbutt4=fltk:Fl_Radio_Round_Button(10,130,360,30,"Fl_Radio_Round_Button")
rbutt5=fltk:Fl_Light_Button(10,170,360,30,"Fl_Light_Button (type FL_RADIO_BUTTON)")
rbutt6=fltk:Fl_Radio_Light_Button(10,210,360,30,"Fl_Radio_Light_Button")

rbutt1:type(fltk.FL_RADIO_BUTTON)
rbutt3:type(fltk.FL_RADIO_BUTTON)
rbutt5:type(fltk.FL_RADIO_BUTTON)
w:show()
Fl:run()
