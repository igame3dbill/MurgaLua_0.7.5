
w=fltk:Fl_Double_Window(500,430,"draw-freehand.lua")

function draw_lines()
  -- do it only if you're dragging within the display box
  --if Fl:event() == fltk.FL_DRAG and Fl:event_inside(0,demo_bh,500,400) == 1 then
  if Fl:event() == fltk.FL_DRAG and Fl:event_inside(lines_display) == 1 then
    w:make_current() -- needed for all drawing functions
    fltk.fl_color(fltk.FL_BLACK)
    fltk.fl_font(fltk.FL_HELVETICA_BOLD,20)
    if not x1 and not x2 then x1,y1=Fl:event_x(),Fl:event_y() else
      x2,y2=Fl:event_x(),Fl:event_y()
      fltk.fl_line(x1,y1,x2,y2)
      x1,y1=x2,y2
    end
  else
    x1,y1,x2,y2=nil,nil,nil,nil
  end
end

function draw_loop(data)
  draw_lines()
  Fl:check()
  timer:doWait(0.001)
end

-- a white box over which to draw
lines_display=fltk:Fl_Box(0,0,500,400)
lines_display:color(fltk.FL_WHITE)
lines_display:box(fltk.FL_FLAT_BOX)

saveas=fltk:Fl_Button(0,400,500,30,"save as png (murgaLua 0.6.4+)")
saveas:callback(
-- modification of another John Murga function
function()
  local imageString = fltk.fl_read_image(0,0,500,400)
  local image2 = fltk:Fl_RGB_Image(imageString,500,400,3)
  lines_display:image(image2) -- keep image from vanishing
  local fileName = fltk.fl_file_chooser("Save as", "Image Files (*.{xpm,gif,bmp,gif,jpg,png,pnm,xbm})", "my_scribble.png", nil)
  if fileName then
    -- make sure you can write to fileName
    local testwrite=io.open(fileName,"w")
    if testwrite then
      testwrite:close()
      image2:saveAsPng(fileName)
    else fltk.fl_alert("can't write to "..fileName)
    end
  end
end
)
-- needs 0.6.4 or newer
if not Fl_RGB_Image.saveAsPng then saveas:deactivate() end

timer = murgaLua.createFltkTimer()
timer:callback(draw_loop)
timer:do_callback()
w:show()
Fl:run()
