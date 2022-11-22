math.randomseed(os.time())
bvx=math.random(1,2)
bvy=math.random(1,2)-1
leftscore=0
rightscore=0
ballspeed=2
maxballspeed=9
ballspeedinc=0.2
playGame=true
oldTime=os.time()
--total distance per second
tdx,tdy= 0,0
--inrect
function inrect(x,y,xx,yy,xxx,yyy)
if x>=xx and x<=xxx and y>=yy and y<=yyy then return true end
return false
end
--ballspeedup
function ballspeedup()
if ballspeed < maxballspeed then ballspeed=ballspeed+ballspeedinc end
end
--borderball detects border hit
function borderball()
bx,by=Ball:x(),Ball:y()
bxx,byy=bx+16,by+16
borderhit=false


-- if the ball exits  the gamefield then reset to center
if inrect(bx,by,fx,fy,fxx,fyy) ~= true and inrect(bxx,byy,fx,fy,fxx,fyy) ~= true then
bx,by = (FIELDBOX:w()/2)+1,(FIELDBOX:h()/2)+1
Ball:resize(bx,by,16,16)
end

--if the ball is beyond the left side of the field, reverse x direction
    if bx <=fx then
    bvx=1
    borderhit=true
    rightscore=rightscore+1
    SCORERIGHT:value(rightscore) 
    ballspeedup()
    end
--if the ball is beyond the right side of the field, reverse x direction
    if bxx >= fxx then
    bvx=-1
    
    leftscore=leftscore+1
    SCORELEFT:value(leftscore)
    ballspeedup()
    end
    
--if the ball hits the top of the field then reverse direction
        if by <=fy then
        bvy=1
        ballspeedup()
        Ball:labelcolor(95)
        end
        
--if the ball hits the bottom of the field  reverse direction        
    if  byy >= fyy then 
    bvy=-1 
    ballspeedup()
    Ball:labelcolor(95)
    end
    
    if borderhit == true then
    bvy=math.random(1,2)
    if bvy==2 then 
        bvy=1
        else
        bvy=-1
        end                
    end
    

        
return bvx,bvy
end
--blockball
function blockball(px,py,pxx,pyy)
bx,by=Ball:x()+bvx,Ball:y()+bvy
bxx,byy=bx+16,by+16

--if the ball is still in the field then detect block hits
if inrect(bx,by,px,py,pxx,pyy) == true or inrect(bxx,byy,px,py,pxx,pyy) == true then

--if the ball is on the left side of the field
    if bx <= (FIELDBOX:w()/2) then
    bvx=1
    Ball:labelcolor(80)
    --or if its on the right side
    else
    bvx=-1
    Ball:labelcolor(220)
    end
        
    

            
byr=math.random(1,15) 

        if byr <= 5 then bvy=0 end
        if byr  >= 6 and byr <= 10 then bvy=-1 end
        if byr >= 11 then bvy=1 end  
    
end

end
-- moveBall
function moveBall()
-- move the ball

bx,by = Ball:x(),Ball:y()
obx,oby = bx,by
bx=bx+bvx*ballspeed
by=by+bvy*ballspeed
Ball:resize(bx,by,16,16)
    
    --total distance 
    tdx=tdx+(math.abs(bvx)*ballspeed)
    tdy=tdy+(math.abs(bvy)*ballspeed)
    if os.time()-oldTime >= 1 then
    distance:label("distance per second x:"..tdx.."  y:"..tdy)
    tdx,tdy= 0,0
    oldTime=os.time()
    end
end
-- movePaddles 
function movePaddles()
mx=Fl:event_x()
my=Fl:event_y()

lx,ly=LEFTBOX:x(),LEFTBOX:y()
lxx,lyy=lx+LEFTBOX:w(),my+LEFTBOX:h()
if inrect(mx,my,fx,fy,fxx,fyy) == true and inrect(mx,lyy,fx,fy,fxx,fyy) == true then
LEFTBOX:resize(lx,my,LEFTBOX:w(),LEFTBOX:h())
end

rx,ry=RIGHTBOX:x(),RIGHTBOX:y()
rxx,ryy=rx+RIGHTBOX:w(),my+RIGHTBOX:h()

if inrect(mx,my,fx,fy,fxx,fyy) == true and inrect(mx,ryy,fx,fy,fxx,fyy) == true then
RIGHTBOX:resize(rx,my,RIGHTBOX:w(),RIGHTBOX:h())
end


lx,ly=LEFTBOX:x(),LEFTBOX:y()
lxx,lyy=lx+LEFTBOX:w(),my+LEFTBOX:h()
rx,ry=RIGHTBOX:x(),RIGHTBOX:y()
rxx,ryy=rx+RIGHTBOX:w(),ry+RIGHTBOX:h()
blockball(lx,ly,lxx,lyy)
blockball(rx,ry,rxx,ryy)

end
--playPong
function playPong()

if (Fl:event_text()== "q") then os.exit() end

speedkey=tonumber(Fl:event_text())
if speedkey ~= nil then
if speedkey >= 1 and speedkey <=9 then ballspeed=speedkey end
    end     
         
         if playGame == true then
         
     movePaddles()
     borderball()
     moveBall()
     
        Pong:redraw()
        murgaLua.sleepMilliseconds(20)
    end
end
--pongWindow_CB
function pongWindow_CB()

if (Fl:event_key()== fltk.FL_Escape) then playGame=not playGame end
    
    if playGame == true then
    Pong:label("PONG")
    else
    Pong:label("PONG  (PAUSED)")
    end
end

do Pong= fltk:Fl_Double_Window(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "PONG")
Pong:label(gLabelTable[#gLabelTable])
Pong:callback(pongWindow_CB)
Pong:resize(380,194,652,443)
Pong:color(0)

do FIELDBOX= fltk:Fl_Box(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "FIELDBOX")
FIELDBOX:label(gLabelTable[#gLabelTable])
FIELDBOX:resize(0,0,655,444)
FIELDBOX:box(fltk.FL_FLAT_BOX)
FIELDBOX:color(0)
FIELDBOX:labeltype(fltk.FL_NO_LABEL)
FIELDBOX:labelcolor(33)
end

do SCORELEFT= fltk:Fl_Output(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "SCORELEFT")
SCORELEFT:label(gLabelTable[#gLabelTable])
SCORELEFT:resize(205,1,60,51)
SCORELEFT:box(fltk.FL_NO_BOX)
SCORELEFT:color(0)
SCORELEFT:labeltype(fltk.FL_NO_LABEL)
SCORELEFT:labelsize(7)
SCORELEFT:labelcolor(72)
SCORELEFT:textsize(36)
SCORELEFT:textcolor(72)
end

do SCORERIGHT= fltk:Fl_Output(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "SCORERIGHT")
SCORERIGHT:label(gLabelTable[#gLabelTable])
SCORERIGHT:resize(385,0,65,51)
SCORERIGHT:box(fltk.FL_NO_BOX)
SCORERIGHT:color(0)
SCORERIGHT:selection_color(177)
SCORERIGHT:labeltype(fltk.FL_NO_LABEL)
SCORERIGHT:labelsize(7)
SCORERIGHT:labelcolor(72)
SCORERIGHT:textsize(36)
SCORERIGHT:textcolor(177)
end

do LEFTBOX= fltk:Fl_Box(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "LeftBox")
LEFTBOX:label(gLabelTable[#gLabelTable])
LEFTBOX:resize(25,193,24,82)
LEFTBOX:box(fltk.FL_FLAT_BOX)
LEFTBOX:color(80)
LEFTBOX:labeltype(fltk.FL_NO_LABEL)
LEFTBOX:labelsize(7)
LEFTBOX:labelcolor(88)
end

do RIGHTBOX= fltk:Fl_Box(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "Rightbox")
RIGHTBOX:label(gLabelTable[#gLabelTable])
RIGHTBOX:resize(600,193,24,82)
RIGHTBOX:box(fltk.FL_FLAT_BOX)
RIGHTBOX:color(220)
RIGHTBOX:labeltype(fltk.FL_NO_LABEL)
RIGHTBOX:labelsize(7)
RIGHTBOX:labelcolor(216)
end

do instructions= fltk:Fl_Box(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "ESC to Pause   Q to QUIT")
instructions:label(gLabelTable[#gLabelTable])
instructions:resize(0,-1,650,16)
instructions:labelsize(10)
instructions:labelcolor(63)
end

do distance= fltk:Fl_Box(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "distance per second")
distance:label(gLabelTable[#gLabelTable])
distance:resize(0,427,650,16)
distance:labelsize(10)
distance:labelcolor(63)
end

do Ball= fltk:Fl_Box(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "¥")
Ball:label(gLabelTable[#gLabelTable])
Ball:resize(320,226,15,16)
Ball:labelsize(16)
Ball:labelcolor(95)
end
end
Pong:show()

gLabelTable[#gLabelTable] ="@circle"
Ball:label(gLabelTable[#gLabelTable])

Pong:make_current();
fx,fy=FIELDBOX:x()+8,FIELDBOX:y()+8
fxx,fyy=fx+FIELDBOX:w()-8,fy+FIELDBOX:h()-8

while Pong do
Fl:check()
playPong()     
end
Fl:run()