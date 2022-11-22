--function make_window()
-- globals_and_functions_codeblock
function input_cb(w)
print(w:value())
end
do aWindow= fltk:Fl_Double_Window(0,0,0,0,"")
aWindow:resize(574,320,329,262)
aWindow:when(6)
--aWindow:show()
do widget= fltk:Fl_Input(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "input:")
widget:label(gLabelTable[#gLabelTable])
widget:callback(input_cb)
widget:resize(100,25,165,17)
widget:labelsize(11)
widget:when(8)
widget:textsize(11)
end
end
aWindow:show()

aWindow:show();
--end
Fl:run()
