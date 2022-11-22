w=fltk:Fl_Double_Window(420,320,"boxtype.lua")

-- these functions must run before the associated box types will work
fltk.fl_define_FL_PLASTIC_UP_BOX()
fltk.fl_define_FL_OVAL_BOX()
fltk.fl_define_FL_RFLAT_BOX()
fltk.fl_define_FL_SHADOW_BOX()
fltk.fl_define_FL_ROUND_UP_BOX()
fltk.fl_define_FL_RSHADOW_BOX()
fltk.fl_define_FL_DIAMOND_BOX()
fltk.fl_define_FL_ROUNDED_BOX()
fltk.fl_define_FL_GTK_UP_BOX()

boxtypes={
FL_NO_BOX = fltk.FL_NO_BOX,
FL_FLAT_BOX = fltk.FL_FLAT_BOX,
FL_UP_BOX = fltk.FL_UP_BOX,
FL_DOWN_BOX = fltk.FL_DOWN_BOX,
FL_THIN_UP_BOX = fltk.FL_THIN_UP_BOX,
FL_THIN_DOWN_BOX = fltk.FL_THIN_DOWN_BOX,
FL_ENGRAVED_BOX = fltk.FL_ENGRAVED_BOX,
FL_EMBOSSED_BOX = fltk.FL_EMBOSSED_BOX,
FL_BORDER_BOX = fltk.FL_BORDER_BOX,
FL_SHADOW_BOX = fltk.FL_SHADOW_BOX,
FL_ROUNDED_BOX = fltk.FL_ROUNDED_BOX,
FL_RSHADOW_BOX = fltk.FL_RSHADOW_BOX,
FL_RFLAT_BOX = fltk.FL_RFLAT_BOX,
FL_ROUND_UP_BOX = fltk.FL_ROUND_UP_BOX,
FL_ROUND_DOWN_BOX = fltk.FL_ROUND_DOWN_BOX,
FL_DIAMOND_UP_BOX = fltk.FL_DIAMOND_UP_BOX,
FL_DIAMOND_DOWN_BOX = fltk.FL_DIAMOND_DOWN_BOX,
FL_OVAL_BOX = fltk.FL_OVAL_BOX,
FL_OSHADOW_BOX = fltk.FL_OSHADOW_BOX,
FL_OFLAT_BOX = fltk.FL_OFLAT_BOX,
FL_PLASTIC_UP_BOX = fltk.FL_PLASTIC_UP_BOX,
FL_PLASTIC_DOWN_BOX = fltk.FL_PLASTIC_DOWN_BOX,
FL_PLASTIC_THIN_UP_BOX = fltk.FL_PLASTIC_THIN_UP_BOX,
FL_PLASTIC_THIN_DOWN_BOX = fltk.FL_PLASTIC_THIN_DOWN_BOX,
FL_PLASTIC_ROUND_UP_BOX = fltk.FL_PLASTIC_ROUND_UP_BOX,
FL_PLASTIC_ROUND_DOWN_BOX = fltk.FL_PLASTIC_ROUND_DOWN_BOX,
FL_GTK_UP_BOX = fltk.FL_GTK_UP_BOX,
FL_GTK_DOWN_BOX = fltk.FL_GTK_DOWN_BOX,
FL_GTK_THIN_UP_BOX = fltk.FL_GTK_THIN_UP_BOX,
FL_GTK_THIN_DOWN_BOX = fltk.FL_GTK_THIN_DOWN_BOX,
FL_GTK_ROUND_UP_BOX = fltk.FL_GTK_ROUND_UP_BOX,
FL_GTK_ROUND_DOWN_BOX = fltk.FL_GTK_ROUND_DOWN_BOX,
FL_UP_FRAME = fltk.FL_UP_FRAME,
FL_DOWN_FRAME = fltk.FL_DOWN_FRAME,
FL_THIN_UP_FRAME = fltk.FL_THIN_UP_FRAME,
FL_THIN_DOWN_FRAME = fltk.FL_THIN_DOWN_FRAME,
FL_ENGRAVED_FRAME = fltk.FL_ENGRAVED_FRAME,
FL_EMBOSSED_FRAME = fltk.FL_EMBOSSED_FRAME,
FL_BORDER_FRAME = fltk.FL_BORDER_FRAME,
FL_SHADOW_FRAME = fltk.FL_SHADOW_FRAME,
FL_ROUNDED_FRAME = fltk.FL_ROUNDED_FRAME,
FL_OVAL_FRAME = fltk.FL_OVAL_FRAME,
FL_PLASTIC_UP_FRAME = fltk.FL_PLASTIC_UP_FRAME,
FL_PLASTIC_DOWN_FRAME = fltk.FL_PLASTIC_DOWN_FRAME,
}

my_scroll=fltk:Fl_Scroll(10,10,400,300)
fltk:Fl_End()
my_scroll:color(fltk.FL_WHITE)
my_scroll:box(15)
cnt=20
type_butts={}
for k,v in pairs(boxtypes) do
type_butts[v] = fltk:Fl_Button(20,cnt,80,25,k.." ("..v..")")
type_butts[v]:box(v)
type_butts[v]:align(fltk.FL_ALIGN_RIGHT)
my_scroll:add(type_butts[v])
cnt=cnt+40
end

w:show()
Fl:run()