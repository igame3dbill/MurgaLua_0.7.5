-- A MurgaLua frontend for xdesktopwaves.
-- This does not cover all options, but should provide a decent
-- amount of control for most features.
-- Note: The 'z' variables are placeholders..dunno if there's a better way
--
-- This program is free software released under the
-- Creative Commons "by-nc-sa" license, version 3.0
-- http://creativecommons.org/licenses/by-nc-sa/3.0/
--
-- Changelog
-- 2007-02-07: Custom colors persist for fl_color_chooser
--             Colors are set accurately with set_color instead of fl_color_cube
--             Tooltips added in case of too-dark color
--             More code cleanup
-- 2007-02-05: Fixed fl_color_chooser not ignoring change when cancelled
--             Code cleanup
-- 2007-02-04: Dumped Lua-FLTK
--             Added custom color controls
-- 2006-10-28: Can use either Lua-FLTK or MurgaLua
--             Removed unnecessary stuff (decoration, about, version, rc file)
-- 2005-01-28: First version (Lua-FLTK)

--program="/opt/xdesktopwaves/xdesktopwaves"
program="xdesktopwaves"

-- LAUNCH XDESKTOPWAVES
function start_waves()
if colors:value() > 0 then colscheme=" -c "..colors:value() 
elseif usemycolor:value() == 1 then colscheme=" -wc "..watercolor.." -sc "..skycolor.." -lc "..lightcolor
else colscheme="" end
if tog1:value() == 1 then stip=" -t"   else stip=""   end
if tog2:value() == 1 then opaque=" -o" else opaque="" end
if tog3:value() == 1 then win=" -w"    else win=""    end
if tog4:value() == 1 then nwm=" -nwm"  else nwm=""    end
if tog5:value() == 1 then nww=" -nww"  else nww=""    end
os.execute(program..colscheme..stip..opaque..win..nwm..nww..
" -q   "..quals:value().. 
" -rn  "..rains:value()..
" -st  "..winds:value()..
" -vs  "..viscs:value()..
" -si  "..skys:value()..
" -li  "..lights:value()..
" -lal "..alts:value()..
" -laz "..azs:value()..
" &")
end

-- MAIN WINDOW
wh = 240
ww = 480
w = fltk:Fl_Window(ww,wh, "xdesktopwaves")
        
sl = 120    -- slider left edge
sw = 190    -- slider width
sh = 18     -- slider height
st = 10     -- first slider y_position
ss = 20     -- spacing
bw=140      -- button width
bx=ww-bw-ss -- button x position

-- SLIDERS
colors = fltk:Fl_Value_Slider(sl,st,sw,sh,"color scheme ");
colors:type(fltk.FL_HORIZONTAL); colors:align(fltk.FL_ALIGN_LEFT);
colors:step(1); colors:minimum(0); colors:maximum(9); colors:value(0);
colors:tooltip("Preset color schemes ");
--
quals = fltk:Fl_Value_Slider(sl,st+ss,sw,sh,"wave quality ");
quals:type(fltk.FL_HORIZONTAL); quals:align(fltk.FL_ALIGN_LEFT);
quals:step(1); quals:minimum(0); quals:maximum(9); quals:value(5);
quals:tooltip("Overall quality of the waves. \nThe higher the quality, the \nhigher the CPU load. ");
--
rains = fltk:Fl_Value_Slider(sl,st+ss*2,sw,sh,"rain amount ");
rains:type(fltk.FL_HORIZONTAL); rains:align(fltk.FL_ALIGN_LEFT);
rains:step(1); rains:minimum(0); rains:maximum(10); rains:value(0);
rains:tooltip("Simulate raindrops falling on the water ");
--
winds = fltk:Fl_Value_Slider(sl,st+ss*3,sw,sh,"wind amount ");
winds:type(fltk.FL_HORIZONTAL); winds:align(fltk.FL_ALIGN_LEFT);
winds:step(1); winds:minimum(0); winds:maximum(10); winds:value(0);
winds:tooltip("Simulate a storm blowing on the water ");
--
viscs = fltk:Fl_Value_Slider(sl,st+ss*4,sw,sh,"viscosity ");
viscs:type(fltk.FL_HORIZONTAL); viscs:align(fltk.FL_ALIGN_LEFT);
viscs:step(1); viscs:minimum(1); viscs:maximum(5); viscs:value(3);
viscs:tooltip("The higher the viscosity, the \nshorter the lifetime of waves ");
--
skys = fltk:Fl_Value_Slider(sl,st+ss*5,sw,sh,"sky ");
skys:type(fltk.FL_HORIZONTAL); skys:align(fltk.FL_ALIGN_LEFT);
skys:step(1); skys:minimum(1); skys:maximum(10); skys:value(5);
skys:tooltip("Intensity of sky reflections ");
--
lights = fltk:Fl_Value_Slider(sl,st+ss*6,sw,sh,"light ");
lights:type(fltk.FL_HORIZONTAL); lights:align(fltk.FL_ALIGN_LEFT);
lights:step(1); lights:minimum(1); lights:maximum(10); lights:value(5);
lights:tooltip("Intensity of light reflections ");
--
alts = fltk:Fl_Value_Slider(sl,st+ss*7,sw,sh,"altitude ");
alts:type(fltk.FL_HORIZONTAL); alts:align(fltk.FL_ALIGN_LEFT);
alts:step(1); alts:minimum(0); alts:maximum(90); alts:value(30);
alts:tooltip("Altitude of light source \(degrees\) ");
--
azs = fltk:Fl_Value_Slider(sl,st+ss*8,sw,sh,"azimuth ");
azs:type(fltk.FL_HORIZONTAL); azs:align(fltk.FL_ALIGN_LEFT);
azs:step(1); azs:minimum(-360); azs:maximum(360); azs:value(-35);
azs:tooltip("Azimuth of light source \(degrees\) ");

-- CUSTOM COLORS
function get_rgbh(i)
r,g,b=Fl:get_color(i:color(),r,g,b);
h=string.format("\\#%.2X%.2X%.2X",r,g,b);
return r,g,b,h
end

function mycolor(self)
get_rgbh(self);
c_ok,r,g,b=fltk.fl_color_chooser("pick color",r,g,b);
if c_ok == 1 then
Fl:set_color(self:color(),r,g,b)
hex=string.format("\\#%.2X%.2X%.2X",r,g,b)
if self:label() == "water color" then watercolor=hex
elseif self:label() == "sky color" then skycolor=hex
else lightcolor=hex end
end
end
-- colors 15, 6, and 255 are changed dynamically
usemycolor = fltk:Fl_Round_Button(bx,st,bw,ss,"Use My Colors: ");
usemycolor:tooltip("This option is overridden by \na nonzero color scheme");
wcolor = fltk:Fl_Button(bx,st+ss,bw,ss,"water color");
wcolor:color(15); wcolor:callback(mycolor); wcolor:tooltip("water color");
scolor = fltk:Fl_Button(bx,st+ss*2,bw,ss,"sky color");
scolor:color(6); scolor:callback(mycolor); scolor:tooltip("sky color");
hcolor = fltk:Fl_Button(bx,st+ss*3,bw,ss,"light color");
hcolor:color(255); hcolor:callback(mycolor); hcolor:tooltip("light color");
-- set initial "my colors"
z,z,z,watercolor=get_rgbh(wcolor);
z,z,z,skycolor=get_rgbh(scolor);
z,z,z,lightcolor=get_rgbh(hcolor);

-- CONTROLS: start, stop
bstart = fltk:Fl_Return_Button(bx,st+ss*5,bw,ss*2, "start");
bstop = fltk:Fl_Button(bx,st+ss*7,bw,ss*2, "stop");
bstart:callback(start_waves)
function stop_waves() os.execute(program.." -end") end
bstop:callback(stop_waves);
-- TOGGLES
tog1 = fltk:Fl_Round_Button(20,wh-40,80,25, "stipple");
tog1:tooltip("Fake transparency. \nThis option is not as \"transparent\" \nas the default transparency, but \nit is easier on your cpu.");
tog2 = fltk:Fl_Round_Button(110,wh-40,80,25, "opaque");
tog2:tooltip("No transparency ");
tog3 = fltk:Fl_Round_Button(200,wh-40,80,25, "window");
tog3:tooltip("Open in its own normal window \nrather than the root window.\nSome window managers\nmay require \"opaque\" as well.");
tog4 = fltk:Fl_Round_Button(290,wh-40,80,25, "ignore\n mouse");
tog4:tooltip("Mouse cursor does not create waves ");
tog5 = fltk:Fl_Round_Button(380,wh-40,80,25, " ignore\nwindows");
tog5:tooltip("Windows do not create waves ");

w:show()