-- Color map
-- Code by mikshaw (http://damnsmalllinux.org/cgi-bin/forums/ikonboard.cgi)

ww=220 --window width
wh=200 --window height

function cmap()
-- open the color map with the 'pop' button's color selected
newcolor=fltk.fl_show_colormap(pop:color())
-- set button's color and label from the new color
pop:color(newcolor);pop:label("FLTK Color "..newcolor)
end

w=fltk:Fl_Window(ww,wh,"murgaLua Colormap Demo")

pop=fltk:Fl_Button(20,20,ww-40,ww-80,"push for colors")
pop:align(fltk.FL_ALIGN_BOTTOM)
pop:callback(cmap)

w:show()
Fl:run()
