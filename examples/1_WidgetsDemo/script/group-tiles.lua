w=fltk:Fl_Double_Window(480,400,"tiles.lua")
-- tiles

tiles = fltk:Fl_Tile(0,0,320,350,"@<- 320x350 group")
tiles:align(fltk.FL_ALIGN_RIGHT)
fltk:Fl_End()
tile = {}
for i = 0,3 do
tile[i]=fltk:Fl_Button(0,80*i,160,80,"button"..i)
tile[i+4] = fltk:Fl_Button(160,80*i,160,80,"button"..i+4)
tiles:add(tile[i])
tiles:add(tile[i+4])
end
tile_special=fltk:Fl_Input(0,320,320,30,"@<- this tiles, too")
tile_special:align(fltk.FL_ALIGN_RIGHT)
tile_special:value("drag the button borders")
tiles:add(tile_special)
w:show()
Fl:run()
