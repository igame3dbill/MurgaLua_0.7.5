
grav=1 -- distance the potato falls on each loop
ps=32 -- image size
splat=3 -- determines whether or not the animation has completed
wait=0.02 -- timer interval

w=fltk:Fl_Double_Window(ps*6,ps*12,"tater salad")
function drag_loop()
  -- following line doesn't seem to work with Windows
  --if Fl:event() == fltk.FL_PUSH and splat==3 then
  if Fl:event_buttons()>0 and Fl:event_button()==1 and splat==3 then
    -- put the potato where the mouse is
    drag_box:position(Fl:event_x()-ps/2,Fl:event_y()-ps/2)
    drag_box:image(pot)
    grav=1
    splat=0
  -- if it has reached the bottom
  elseif drag_box:y()>=w:h()-ps and splat<3 then
    wait=0.05 -- increase the timer interval for more defined animation
    -- chose which splat image to display
    if splat==0 then drag_box:image(s1); splat=1
    elseif splat==1 then drag_box:image(s2); splat=2
    elseif splat==2 then drag_box:position(drag_box:x(),w:h()+ps); splat=3; wait=0.02
    end
    w:redraw()
  elseif drag_box:y()<w:h() then drag_box:position(drag_box:x(),drag_box:y()+grav)
    grav=grav+0.5 -- increase the distance the potato drops on each loop
    w:redraw()
  end
  drag_timer:doWait(wait)
end

-- background tile
tile = {
"32 32 16 1",
"0      c #000044",
"1      c #5C7B87",
"2      c #7F95B0",
"3      c #7FBDD3",
"4      c #0000FF",
"5      c #FF00FF",
"6      c #00FFFF",
"7      c #FFFFFF",
"8      c #DBDBDB",
"9      c #B6B6B6",
"A      c #929292",
"B      c #6D6D6D",
"C      c #494949",
"D      c #242424",
"E      c #DB0000",
"F      c #B60000",
"33333333333333333333333333333331",
"23333333333333333333333333333311",
"22111111111111111111111111111111",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22100000000000000000000000000211",
"22133333333333333333333333333311",
"22111111111111111111111111111111",
"21111111111111111111111111111111"
};
bg=fltk:Fl_Box(0,0,w:w(),w:h())
bgimg=fltk:Fl_Pixmap(tile)
bg:image(fltk:Fl_Tiled_Image(bgimg,w:w(),w:h()))

-- potato
drag_box=fltk:Fl_Box(0,w:h()+ps,ps,ps)
drag_box:box(fltk.FL_NO_BOX) -- transparent box
tater={
"32 32 16 1",
"0      c #000100",
"1      c #383937",
"2      c #442E00",
"3      c #60625F",
"4      c #996800",
"5      c #BA7D00",
"6      c #D79300",
"7      c #FECE6E",
"8      c #DB9C49",
"9      c #00699A",
"A      c #00ABF2",
"B      c #4C9C99",
"C      c #B4FDFE",
"D      c #FDFEFB",
"E      c #C9CBC8",
"       c None",
"                    0000000     ",
"                 0004444570000  ",
"             000044224667667500 ",
"            0DDDD06646677666750 ",
"          00DDDDDD0664444666640 ",
"         0DDDDDDDDD0646666646650",
"        0DAAAADDDDD0644664676740",
"        0DAA3DDDDDD0644474476840",
"       0DA10DDADDDD0646446677740",
"     0 0DA0000AADD1010000066760 ",
"    0000DA0100AADD01DDDDDD06760 ",
"   0D040DDABAAAAD00DDDDDDDD0650 ",
"   0D0440DAAAAAD00DAAADDDDD2220 ",
"  0DD00440DDDD000DAA9ADDDDDD000 ",
"  0DDD05440000060DA32DDDDDDD00  ",
"  0D0DD054456460DA211DBADDD20   ",
"  0D0DD065646660DA1000BADDD00   ",
"  00DDDD065646600DA901AACD0     ",
"  00DD0DD06564650DAAAAADD00     ",
" 0050DD0DD00556600DDCCDD00      ",
" 0040DDD0DDD0066620000020       ",
" 04440DDD0DDD000666666540       ",
" 0464400DDD0DDD0000000040       ",
"0046466000DD00DDDDDDDDD00       ",
"00446666000DDDDDDDDDD0000       ",
"0046666666600000000000          ",
"0044666656656622220             ",
" 0044666665644420               ",
"  00446666444000                ",
"   0014444440                   ",
"    00000000                    ",
"      000                       "
};
pot=fltk:Fl_Pixmap(tater) -- create an image with the pixmap data

splat1 = {
"32 32 10 1",
"0      c #000100",
"1      c #383937",
"2      c #442E00",
"3      c #60625F",
"4      c #986800",
"5      c #D69200",
"6      c #00AAF1",
"7      c #4C9B98",
"8      c #FCFDFA",
"       c None",
"                                ",
"            555                 ",
"            55555               ",
"             5555           5   ",
"       4444   555     55  255   ",
"       4444          5555222    ",
"    04 44444       5555552255   ",
"     0 44000001    55555  5     ",
"     0  08888100 44 555         ",
"     0 0888888800 4444 22       ",
"2222  088888888800444  222      ",
"22222 088888866680445500  5555  ",
"  222 0888886666600555055555 5  ",
"      08886880066805500555      ",
"       088638006680000000       ",
"        0866001768008888004 555 ",
" 555 444486610066808888880445555",
" 55 44444088666880888866800 444 ",
"55544444  008888048608668844444 ",
" 5555544    000040860006880444  ",
"            444440060066880     ",
"         0     444066688800     ",
"       0000      40000000       ",
"       0000                     ",
"       2200                     ",
"      2220                      ",
"      22                        ",
"                                ",
"                                ",
"                                ",
"                                ",
"                                "
};
s1=fltk:Fl_Pixmap(splat1)
splat2 = {
"32 32 7 1",
"0      c #000100",
"1      c #383937",
"2      c #442E00",
"3      c #986800",
"4      c #D69200",
"5      c #FCFDFA",
"       c None",
"               4                ",
"   3333      4 4                ",
"   33  33    4444        44     ",
"   333  3      4       44 4 4   ",
"   3    33              4  44   ",
"        33                 2    ",
"    0  3           4        4   ",
"     0                          ",
"     0   5555           22      ",
"     0   55  5         222      ",
"222   0 55              22      ",
"22                 344     444  ",
"                     4       4  ",
"                         4      ",
"                                ",
"        55                    4 ",
"        5   1                 44",
"      3355                  3 3 ",
"4  33                  555 3 33 ",
"44   433               5    3   ",
"   33                           ",
" 3333                           ",
"  33          3  3              ",
"  3          333      555       ",
"        2    333      555       ",
"      2  0             55       ",
"       2                5       ",
"    22                          ",
"    22                          ",
"    2                           ",
"                                ",
"                                "
};
s2=fltk:Fl_Pixmap(splat2)

drag_timer = murgaLua.createFltkTimer()
drag_timer:callback(drag_loop)
drag_timer:do_callback()
w:show()
Fl:run()
