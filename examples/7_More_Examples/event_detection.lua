-- Demonstration of clock widget
-- Code by mikshaw (http://damnsmalllinux.org/cgi-bin/forums/ikonboard.cgi)

ww=264 --window width
wh=150
gw=ww-20 -- group
gh=wh-50

anImage="/background.gif"
pathToMurgaLua = string.gsub(murgaLua_ExePath,"(.*)/.*","%1")
AppPathImage = pathToMurgaLua..anImage
CurDirImage = lfs.currentdir() ..anImage
fltk.fl_register_images()
if lfs.attributes(AppPathImage) ~= nil then  img_back = Fl_Shared_Image.get(AppPathImage) end
if lfs.attributes(CurDirImage) ~= nil  then img_back = Fl_Shared_Image.get(CurDirImage) end



event_constants = {	["0"]="FL_NO_EVENT",
	["1"]="FL_PUSH",
	["2"]="FL_RELEASE",
	["3"]="FL_ENTER",
	["4"]="FL_LEAVE",
	["5"]="FL_DRAG",
	["6"]="FL_FOCUS",
	["7"]="FL_UNFOCUS",
	["8"]="FL_KEY",
	["9"]="FL_KEYUP",
	["10"]="FL_MOVE",
	["11"]="FL_SHORTCUT",
	["12"]="FL_ACTIVATE",
	["13"]="FL_DEACTIVATE",
	["14"]="FL_SHOW",
	["15"]="FL_HIDE",
	["16"]="FL_VIEWCHANGE",
	["17"]="FL_PASTE",
	["18"]="FL_DND_ENTER",
	["19"]="FL_DND_DRAG",
	["20"]="FL_DND_LEAVE",
	["21"]="FL_DND_RELEASE"
  }

function event_callback()
  local tCount = 1
  repeat
    Fl:wait(1)
    evt = Fl:event()
    out:value(evt .. "   " .. event_constants["" .. evt])
    if (evt == 7) then tCount = 99999999 end
    tCount = tCount + 1
    w:redraw()
  until tCount >= 5000
end


w=fltk:Fl_Window(ww,wh,"Event Detection")
--  blue = fltk.set_color(255,0,0)
w:color(55)

group = fltk:Fl_Group(10,10,gw,gh)

  action_area = fltk:Fl_Box(0, 0, 264,wh-50,"Execute an action here");
  action_area:box(fltk.FL_FLAT_BOX);
  action_area:color(215)

  out_back = fltk:Fl_Box(0, wh-50, 264,50);
  out_back:box(fltk.FL_FLAT_BOX);
  out_back:image(img_back);
  out_back:color(55);

  out=fltk:Fl_Output(50,wh-40,200,25)
  out:box(fltk.FL_NO_BOX);

fltk:Fl_End()
group:box(fltk.FL_NO_BOX)

--[[
  w:when(1);
  w:callback(function()
    out:value("changed")
  end)
]]

w:show()
loop=event_callback()
while (Fl:event_key() ~= fltk.FL_Escape)  do
   Fl:wait(0);
  
end


