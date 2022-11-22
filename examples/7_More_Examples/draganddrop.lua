------------
ww=350 --window (width and height)
wh=400 
fw = ww-20 -- frame
fh = ww-20
dw = fw-10 -- drag and drop area
dh = fw-10
sw = 10 -- square width
------------
square = {}
square_selected = {}

-- :Square object
-- Constucts a little square on the screen that can be drag and dropped within a given display area.
-- @param x the x position of the square
-- @param y the y position of the square
-- @param c the color of the square
function square_create(x,y,c)
  sq = fltk:Fl_Button(x,y,sw,sw); 
  sq:box(fltk.FL_BORDER_BOX)
  sq:color(c);
  sq:callback(square_cb)
  return sq
end

-- Callbacks
function crosshair_cb()
  x = crosshair:xvalue()
  y = crosshair:yvalue()
  -- The crosshair area needs to be larger than the drag area, otherwise, a box that is on the far
  -- right or far bottom of the screen cannot be moved anymore.
  xpos=math.floor(x*dw*(dw/fw)) 
  ypos=math.floor(y*dh*(dh/fh))
  square_selected:position(xpos+15,ypos+15)
  out:value("X: ".. xpos .."  Y: ".. ypos)
  out2:value("X: ".. string.format("%.2f",x) .."  Y: ".. string.format("%.2f",y))
  crosshair:hide()
  -- out:value("X: "..crosshair:xvalue() * ww .."  Y: "..crosshair:yvalue() * wh)
  w:redraw()
end

function square_cb(self)
  square_selected = self
  crosshair:show()
  w:redraw()
end 

-- GUI / Interface

w=fltk:Fl_Window(ww,wh,"murgaLua Drag and Drop Demo")

frame=fltk:Fl_Box(10,10,fw,fh); 
frame:box(fltk.FL_BORDER_BOX)
frame:color(36);

display = fltk:Fl_Group(10,10,fw,fh)

  square[1] = square_create(15,15,80)
  square[2] = square_create(200,200,60)

  crosshair=fltk:Fl_Positioner(10,10,fw,fh); 
  crosshair:box(fltk.FL_NO_BOX)
  crosshair:selection_color(36) -- same color as frame background
  -- crosshair:selection_color(72)
  crosshair:callback(crosshair_cb)
fltk:Fl_End()

-- outputs, display the x and y values during drag and drop
out=fltk:Fl_Output(5,wh-30,ww/2-10,25)
out2=fltk:Fl_Output(ww/2+5,wh-30,ww/2-10,25)

-- required as button 1 is active by default and clicking anywhere on the screen
-- other than one of the two buttons crashes the app.
square_selected = square[1]

w:show()
Fl:run()

