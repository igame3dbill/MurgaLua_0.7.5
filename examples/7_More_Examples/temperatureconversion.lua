function chk()
box:label("")
for k,v in pairs(temps) do
if math.floor(sk:value())==k then box:label(v) end
end
end

temps={
[0]="absolute zero",
[159]="freezing point of pure ethanol",
[184]="coldest air temperature recorded on Earth (Vostok, Antarctica, 1983)",
[273]="freezing point of water",
[309]="average human body temperature",
[331]="Highest air temperature recorded on Earth (El Azizia, Libya, 1922)";
[351]="boiling point of ethanol",
[373]="boiling point of water",
[516]="Ignition temperature of sulfur",
[553]="Ignition temperature of gasoline",
[622]="Ignition temperature of charcoal",
[672]="Ignition temperature of isopropyl alcohol",
[673]="Ignition temperature of petroleum",
[693]="Ignition temperature of butane",
[753]="Ignition temperature of propane",
[773]="Ignition temperature of hydrogen",
[973]="Ignition temperature of carbon",
[1670]="The hottest (blue) part of a candle flame";
[5800]="estimated temperature of the sun's surface"
}

ww=600; sh=30
w=fltk:Fl_Double_Window(ww,sh*5,"Temperature Conversion")

sf=fltk:Fl_Hor_Value_Slider(20,10,ww-30,sh,"F")
sf:align(4); --sf:when(fltk.FL_WHEN_RELEASE)
sf:minimum(-459); sf:maximum(212); sf:value(32); sf:step(1)
sf:callback(function()
sc:value((sf:value() - 32) * 5/9)
sk:value(sc:value()+273)
chk()
end)

sc=fltk:Fl_Hor_Value_Slider(20,10+sh,ww-30,sh,"C")
sc:align(4); --sc:when(fltk.FL_WHEN_RELEASE)
sc:minimum(-273); sc:maximum(420); sc:step(1)
sc:callback(function()
sf:value(sc:value() * 9/5 + 32)
sk:value(sc:value() + 273)
chk()
end)

sk=fltk:Fl_Hor_Value_Slider(20,10+sh*2,ww-30,sh,"K")
sk:align(4); --sk:when(fltk.FL_WHEN_RELEASE)
sk:minimum(0); sk:maximum(5800); sk:value(273); sk:step(1)
sk:callback(function()
sf:value((sk:value() - 273) * 9/5 + 32 )
sc:value(sk:value() - 273)
chk()
end)

box=fltk:Fl_Box(20,10+sh*3,ww-30,sh)
box:box(fltk.FL_DOWN_BOX)
sc:do_callback()

w:show()
Fl:run()