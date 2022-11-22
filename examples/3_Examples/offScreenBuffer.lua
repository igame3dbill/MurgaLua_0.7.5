
  function offScreenDraw(w)
  collectgarbage()
  offScreenBuffer = murgaLua.createOffscreenBuffer(150, 150)
  
  offScreenBuffer:startOffScreenDrawing()
  
  -- On Linux we have to clear the buffer (not on Mac or Win32)
  fltk.fl_color(0)
  fltk.fl_polygon(0,0,150,0,150,150,0,150)
  
  fltk.fl_color(math.random(1,255))  
  -- Linux will segfault unless we set the font before using fl_draw
  fltk.fl_font(fltk.FL_HELVETICA_BOLD,14)
  fltk.fl_draw("OffScreen Drawing",10,20)

  fltk.fl_polygon(10,20,120,30,76,120,120,77)

  getOffScreen_Button:image(offScreenBuffer:getOffScreenImage())
  getOffScreen_Button:redraw()
  offScreenBuffer:endOffScreenDrawing()
  
  end
  
  do local object = fltk:Fl_Double_Window(210, 210, "OffScreen drawing");
    window = object;
    do getOffScreen_Button = fltk:Fl_Button(5, 5, 200, 200, "Get off screen image");
    end -- Fl_Button* getOffScreen
  end
  
  
  getOffScreen_Button:callback(offScreenDraw);
  
  window:show();
  Fl:run();
