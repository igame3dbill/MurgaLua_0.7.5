-- Demonstration of clock widget
-- Code by mikshaw (http://damnsmalllinux.org/cgi-bin/forums/ikonboard.cgi)

ww=180 --window width
wh=160
gw=ww-20 -- group
gh=wh-50
fltk.fl_register_images()
img_back = Fl_Shared_Image.get("clock.png")

function clock_callback()
  local tCount = 1
  repeat
    Fl:wait()
    murgaLua.sleep(50)

    if (Fl:first_window() == nil) then tCount = 99999999 end
    w:redraw()
    tCount = tCount + 1
  until tCount >= 6000
end


w=fltk:Fl_Double_Window(ww,wh,"Clock Demo")
--  blue = fltk.set_color(255,0,0)
w:color(55)

group = fltk:Fl_Group(10,10,gw,gh)

  clock_back = fltk:Fl_Box(30, 20, gw-40,gw-40);
  clock_back:box(fltk.FL_FLAT_BOX);
  clock_back:image(img_back);
  clock_back:color(55);

  clock=fltk:Fl_Clock(36,22,gw-50,gw-50)
  clock:box(fltk.FL_NO_BOX);

fltk:Fl_End()
group:box(fltk.FL_NO_BOX)

--[[
  w:when(1);
  w:callback(function()
    out:value("changed")
  end)
]]

w:show()
loop=clock_callback()
Fl:wait(0)
