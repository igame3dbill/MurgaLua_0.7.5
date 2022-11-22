function draw_callback(eventValue)

  -- Need to look into what event 11 is ...

  if (Fl:event() == 0 or Fl:event() == 11)
  then
      -- 0 means no even I think, so we know we are requesting a draw.
      fltk.fl_color(96+counter)

      w:make_current()

      fltk.fl_rectf(20+counter,20,50,50)
      fltk.fl_draw("this is a test",20,80+counter)
      fltk.fl_loop( 20,20,80+counter,80+counter, 200,0)
      counter=counter+4
      if counter > 120 then counter=2 end
  else
      print(Fl:event())
      os.exit(0)
  end

end

counter = 0

w=fltk:Fl_Window(0,0, 210, 220, "draw demo")

w:callback(draw_callback)

w:color(55)

w:show()

while 1 do
    Fl:check()
    w:do_callback()
    murgaLua.sleep(25)
end

Fl:run()
