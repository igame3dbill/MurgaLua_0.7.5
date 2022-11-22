delay = 0.1 -- Delay is rounded up to closest 0.2 of a second.
counter = 0

function draw_callback(eventValue)

      -- Linux will SOMETIMES segfault unless we set the display
      -- BEFORE doing any drawing related stuff ...
      w:make_current()
      fltk.fl_color(96+counter)

      -- Linux will segfault unless we set the font before using fl_draw
      fltk.fl_font(fltk.FL_COURIER, 20)
      fltk.fl_draw("this is a test",20,80+counter)

      fltk.fl_rectf(20+counter,20,50,50)
      fltk.fl_loop( 20,20,80+counter,80+counter, 200,0)

      counter=counter+4
      if counter > 120 then counter=2 end

      print(os.time())
      io.flush()
      
      timer:value(delay)
end

w=fltk:Fl_Window(0,0, 210, 220, "draw demo")

timer = fltk:Fl_Timer(FL_HIDDEN_TIMER, 0,0,0,0,"0")
timer:callback(draw_callback)

w:color(55)
w:show()

timer:value(delay)

Fl:run(