
function draw_bar(x,y,w,h,c,v)
win:make_current()
fltk.fl_color(c)
if v==1 then -- vertical
  -- triangle, rectangle, triangle <===>
  fltk.fl_polygon(x+w/2,y, x+w,y+w/2, x,y+w/2)
  fltk.fl_polygon(x,y+w/2, x+w,y+w/2, x+w,y+h-w/2, x,y+h-w/2)
  fltk.fl_polygon(x,y+h-w/2, x+w,y+h-w/2, x+w/2,y+h)
else -- horizontal
  fltk.fl_polygon(x,y+h/2, x+h/2,y, x+h/2,y+h)
  fltk.fl_polygon(x+h/2,y, x+w-h/2,y, x+w-h/2,y+h, x+h/2,y+h)
  fltk.fl_polygon(x+w-h/2,y, x+w,y+h/2, x+w-h/2,y+h)
end
end

-- looks redundant, but it's the only way I know to start at 0
digits={}                 -- ten digits, 0-9
digits[0]={1,0,1,1,1,1,1} -- 7 bars in each digit
digits[1]={0,0,0,0,1,0,1} -- 0=gray, 1=black
digits[2]={1,1,1,0,1,1,0}
digits[3]={1,1,1,0,1,0,1}
digits[4]={0,1,0,1,1,0,1}
digits[5]={1,1,1,1,0,0,1}
digits[6]={1,1,1,1,0,1,1}
digits[7]={1,0,0,0,1,0,1}
digits[8]={1,1,1,1,1,1,1}
digits[9]={1,1,1,1,1,0,1}

-- digit width and bar thickness
-- dw affects the size of the interface
-- even numbers seem to look best
dw=140; bw=30
b=20 -- window border width

function refresh_values()
-- this needs to be done each time the slider is dragged
-- length of bars, height of digit
bl=dw-bw*1.5; dh=bl*2+bw*1.5
ww=dw+b*2; wh=dh+bw*4 -- window dimensions
hc=ww/2-bl/2 -- horizontal center (for bars)
vc=b+dh/2-bw/2 -- vertical center

-- bar layout:
--    1
--  4   5
--    2
--  6   7
--    3

-- x,y,w,h of each bar of the LCD display
coords={ -- bars 1-7 as shown in the bar layout
{hc,b,bl,bw},
{hc,vc,bl,bw},
{hc,b+dh-bw,bl,bw},
{b,b+bw/1.5,bw,bl},
{ww-b-bw,b+bw/1.5,bw,bl},
{b,vc+bw/1.5,bw,bl},
{b+dw-bw,vc+bw/1.5,bw,bl}
}
end

-- num represents the index of the active button
function shownum(num)
thisnum=num
for i,v in ipairs(digits[num]) do
local color,vert
  if i > 3 then vert=1 else vert=0 end   -- first 3 bars are horizontal
  if v==0 then color=48 else color=0 end -- light gray or black
  draw_bar(coords[i][1],coords[i][2],coords[i][3],coords[i][4],color,vert)
end
fattener:take_focus()
end

refresh_values()
buttwidth=ww/10
win=fltk:Fl_Window(ww,wh,"LCD Digits")

button_group=fltk:Fl_Pack(0,wh-40,ww,20)
button_group:type(fltk.FL_HORIZONTAL)
button={}
for i=0,9 do
  button[i]=fltk:Fl_Button(0,0,ww/10,20,"&"..i)
-- each button sends its table index to shownum()
  button[i]:callback(function() shownum(i) end)
end
fltk:Fl_End()

fattener=fltk:Fl_Hor_Slider(0,wh-20,ww,20)
fattener:minimum(5); fattener:maximum(80)
fattener:step(1); fattener:value(bw)
fattener:callback(
function()
  win:redraw()
  refresh_values()
  bw=fattener:value()
  Fl:check()
  shownum(thisnum)
end)

win:show()
Fl:flush() -- these two lines are necessary to draw before run() is called
Fl:check()
shownum(0) -- display a zero
Fl:run()
