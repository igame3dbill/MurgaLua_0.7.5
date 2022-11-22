w=fltk:Fl_Double_Window(500,400,"draggable_box.lua")

--[[ This version is terribly unreliable. You must drag very slowly
function drag_loop()
  if Fl:event() == fltk.FL_DRAG and Fl:event_inside(drag_box) ~= 0 then
    drag_box:position(Fl:event_x()-16,Fl:event_y()-16)
    w:redraw()
  end
  drag_timer:doWait(.002)
end
]]

-- This version is much faster, but with limited behavior
function drag_loop()
  if Fl:event() == fltk.FL_DRAG then
    drag_box:position(Fl:event_x()-16,Fl:event_y()-16)
    w:redraw()
  end
  drag_timer:doWait(.02)
end

drag_box=fltk:Fl_Box(40,40,32,32)
drag_box:box(fltk.FL_THIN_UP_BOX)

drag_timer = murgaLua.createFltkTimer()
drag_timer:callback(drag_loop)
drag_timer:do_callback()
w:show()
Fl:run()
