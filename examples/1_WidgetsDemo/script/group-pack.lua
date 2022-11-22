w=fltk:Fl_Double_Window(430,210,"pack.lua")

fl_pack=fltk:Fl_Pack(10,20,100,0,"pack 1") -- height is dynamic
fl_pack:box(fltk.FL_THIN_DOWN_FRAME)
fltk:Fl_End()

fl_pack2=fltk:Fl_Pack(120,20,0,30,"pack 2 (fltk.FL_HORIZONTAL)") --width is dynamic
fl_pack2:box(fltk.FL_THIN_DOWN_FRAME)
fl_pack2:type(fltk.FL_HORIZONTAL)
fltk:Fl_End()

pack_boxes={}
pack2_boxes={}
for i=0,5 do
pack_boxes[i]=fltk:Fl_Box(0,0,100,30,"box "..i)
pack2_boxes[i]=fltk:Fl_Box(0,0,50,30,"box "..i)
fl_pack:add(pack_boxes[i])
fl_pack2:add(pack2_boxes[i])
end

w:show()
Fl:run()
