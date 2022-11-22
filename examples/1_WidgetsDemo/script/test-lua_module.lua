
require "mikstring"

function jmbl()
local count=0
if inpoot:value()~="" then
inpoot:value(string.jumble(inpoot:value()))
end
end

ww=300; wh=140
win=fltk:Fl_Window(ww,wh,"module test")
inpoot=fltk:Fl_Input(10,10,ww-20,25)
inpoot:value("This text will be jumbled")
butt=fltk:Fl_Return_Button(10,40,ww-20,25,"string.jumble()")
butt:callback(jmbl)
box=fltk:Fl_Box(10,wh-35,ww-20,25,"string.testing: "..string.testing)

win:show()
Fl:run()
