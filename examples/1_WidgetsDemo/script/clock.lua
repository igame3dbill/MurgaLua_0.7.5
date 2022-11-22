w=fltk:Fl_Double_Window(420,420,"clock.lua")
-- Demonstration of skinned clock widget
-- Original code by Marielle Lange (http://www.widged.com)
--
-- changes by mikshaw:
-- Modified redraw function to use the improved murgaLua.createFltkTimer in murgaLua 0.5
-- Replaced image to insure redistribution rights
-- Added other clock types and update interval slider

clock_timer = murgaLua.createFltkTimer()

function clock_callback(data) -- redrawing prevents overlap with FL_NO_BOX
  clock_group:redraw()
  clock_timer:doWait(clock_slider:value())
  clock_output:label("from widget: "..clock:hour()..":"..clock:minute()..":"..clock:second().."\nos.date(): "..os.date("%H:%M:%S"))
end

--fltk.fl_register_images()
--img_back = Fl_Shared_Image.get(demo_images.."clock.png")
img_back = fltk:Fl_PNG_Image(images.."clock.png")

clock_group = fltk:Fl_Group(10,10,200,200)

  clock_back = fltk:Fl_Box(10,10,200,200);
  clock_back:box(fltk.FL_FLAT_BOX);

  clock=fltk:Fl_Clock(20,20,180,180,"fltk.Fl_Clock")
  clock:box(fltk.FL_NO_BOX);
  clock_back:image(img_back);

fltk:Fl_End()

clock2=fltk:Fl_Round_Clock(220,20,180,180,"fltk:Fl_Round_Clock")
clock3=fltk:Fl_Clock(20,220,180,180)
clock_output=fltk:Fl_Box(220,220,180,120)
clock_output:align(20)

clock_slider=fltk:Fl_Hor_Value_Slider(220,350,180,30,"update interval (seconds)")
clock_slider:minimum(1)
clock_slider:maximum(10)
clock_slider:step(1)
clock_slider:value(1)

clock_timer:callback(clock_callback)
clock_timer:do_callback()
w:show()
Fl:run()
