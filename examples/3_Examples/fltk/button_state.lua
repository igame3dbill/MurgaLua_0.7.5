ww=180 --window dims
wh=50

w=fltk:Fl_Window(ww,wh,"Button State")
w:color(55)

but = fltk:Fl_Button(10,14,80,22,"a button"); 
but:when(1);
--[[
    FL_WHEN_NEVER             {0;}
    FL_WHEN_CHANGED           {1;}
    FL_WHEN_RELEASE           {4;}
    FL_WHEN_RELEASE_ALWAYS    {6;}
    FL_WHEN_ENTER_KEY         {8;}
    FL_WHEN_ENTER_KEY_ALWAYS  {10;}
    FL_WHEN_ENTER_KEY_CHANGED {11;}
    FL_WHEN_NOT_CHANGED       {2;}
]]
but:callback(function(self)
  message = "down"
  if (Fl:event() == 2) then message ="up" end
  out:value(message)
end)

  out=fltk:Fl_Output(95,14,70,22)


w:show()
Fl:run()

