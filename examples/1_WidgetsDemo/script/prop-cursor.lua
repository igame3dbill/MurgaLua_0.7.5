w=fltk:Fl_Double_Window(340,260,"cursors.lua")

cur_scroll=fltk:Fl_Scroll(10,10,320,210)
fltk:Fl_End()
cur_pack=fltk:Fl_Pack(10,10,300,210)
fltk:Fl_End()
cur_scroll:add(cur_pack)

function cur_callback(self)
  local witch=string.gsub(self:label(),".*%s(%d+)$","%1")
  w:cursor(witch)
end

cur_butts={}
for i=0,20 do
  cur_butts[i]=fltk:Fl_Button(0,0,300,30)
  cur_butts[i]:callback(cur_callback)
  cur_pack:add(cur_butts[i])
end

cur_reset=fltk:Fl_Button(10,220,320,30,"&reset cursor")
cur_reset:callback(function(cur_reset_cb)
  w:cursor(0) -- set cursor to FL_CURSOR_DEFAULT
end)

-- standard cursors:
cur_butts[0]:label("fltk.FL_CURSOR_DEFAULT = 0")
cur_butts[1]:label("fltk.FL_CURSOR_ARROW = 35")
cur_butts[2]:label("fltk.FL_CURSOR_CROSS = 66")
cur_butts[3]:label("fltk.FL_CURSOR_WAIT = 76")
cur_butts[4]:label("fltk.FL_CURSOR_INSERT = 77")
cur_butts[5]:label("fltk.FL_CURSOR_HAND = 31")
cur_butts[6]:label("fltk.FL_CURSOR_HELP = 47")
cur_butts[7]:label("fltk.FL_CURSOR_MOVE = 27")
-- fltk provides bitmaps for these:
cur_butts[8]:label("fltk.FL_CURSOR_NS = 78")
cur_butts[9]:label("fltk.FL_CURSOR_WE = 79")
cur_butts[10]:label("fltk.FL_CURSOR_NWSE = 80")
cur_butts[11]:label("fltk.FL_CURSOR_NESW = 81")
cur_butts[12]:label("fltk.FL_CURSOR_NONE = 255")
-- for back compatability (non MSWindows ones):
cur_butts[13]:label("fltk.FL_CURSOR_N = 70")
cur_butts[14]:label("fltk.FL_CURSOR_NE = 69")
cur_butts[15]:label("fltk.FL_CURSOR_E = 49")
cur_butts[16]:label("fltk.FL_CURSOR_SE = 8")
cur_butts[17]:label("fltk.FL_CURSOR_S = 9")
cur_butts[18]:label("fltk.FL_CURSOR_SW = 7")
cur_butts[19]:label("fltk.FL_CURSOR_W = 36")
cur_butts[20]:label("fltk.FL_CURSOR_NW = 68")
w:show()
Fl:run()
