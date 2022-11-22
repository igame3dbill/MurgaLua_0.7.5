w=fltk:Fl_Double_Window(360,400,"buttons.lua")

presses = 0 -- used for the repeat button
function button_press(self)
if self == butts[5] or self == butts[6] or self == butts[7] or self == butts[8] then
if self:value() == 1 then status="activated" else status="deactivated" end
out:value("\""..self:label().."\" was "..status)
presses = 0
elseif self == butts[4] then
presses = presses+1
out:value("\""..self:label().."\" was pressed "..presses.." times")
else
out:value("\""..self:label().."\" was pressed")
presses = 0
end
end

butts={}
butts[1]=fltk:Fl_Button(10,10,340,25,"Fl_Button default")
butts[2]=fltk:Fl_Button(10,40,340,25,"Fl_Button down"); butts[2]:box(fltk.FL_DOWN_BOX)
butts[3]=fltk:Fl_Return_Button(10,70,340,25,"Fl_Return_Button")
butts[4]=fltk:Fl_Repeat_Button(10,100,340,25,"Fl_Repeat_Button")
butts[5]=fltk:Fl_Toggle_Button(10,130,340,25,"Fl_Toggle_Button")
butts[6]=fltk:Fl_Light_Button(10,160,340,25,"Fl_Light_Button (Alt+b)")
butts[7]=fltk:Fl_Light_Button(10,190,340,25,"Fl_Light_Button (rounded box)")
butts[8]=fltk:Fl_Round_Button(10,220,340,25,"Fl_Round_Button")
butts[9]=fltk:Fl_Check_Button(10,250,340,25,"Fl_Check_Button")

for i = 1,9 do
butts[i]:callback(button_press)
end
out=fltk:Fl_Output(10,280,340,25)

-- shortcut doesn't do the callback with the default when(fltk.FL_WHEN_RELEASE)
butts[6]:shortcut(fltk.FL_ALT+string.byte("b"))
butts[6]:when(fltk.FL_WHEN_CHANGED)

-- selection_color, color2 and down_color all seem to
-- have the same affect when applied to buttons
butts[4]:selection_color(fltk.FL_RED)
butts[5]:down_color(fltk.FL_BLUE)
butts[7]:color2(fltk.FL_RED)
fltk.fl_define_FL_ROUNDED_BOX() -- needed for next line
butts[7]:down_box(23)

w:show()
Fl:run()
