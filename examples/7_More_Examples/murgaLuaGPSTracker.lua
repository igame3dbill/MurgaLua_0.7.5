-- ***********************************************
-- GPSTracker.lua
-- Author: chrimo@moccy.xdsnet.de  and friends
-- Changes: initial startup
-- Beta-0 Test
-- Date: 2007-07-28    startup
-- Date:
-- ***********************************************

version="0.2007-07-28";
port="/dev/tty.BT-348_GPS-Serialport-1"
running=0;
UTCdiff=0;

--
-- GPS GUI
--

MaxWinSizeX=320;                       
MaxWinSizeY=80;                       

BorderX=1;
BorderY=1;

OutWinSizeX=MaxWinSizeX-BorderX;
OutWinSizeY=MaxWinSizeY-BorderY;

ButtonSizeX=79;
ButtonSizeY=30;

window = fltk:Fl_Double_Window(MaxWinSizeX, MaxWinSizeY, "GPSTracker");
window:tooltip("GPSTracker by Chrimo and friends "..version);
window:color(55);
window:align(fltk.FL_ALIGN_CENTER);
window:position(BorderX,BorderY);

startButton = fltk:Fl_Button(MaxWinSizeX/2-ButtonSizeX/2, MaxWinSizeY-ButtonSizeY-BorderY, ButtonSizeX, ButtonSizeY, "Start");
startButton:color(31);
startButton:selection_color(31);
startButton:tooltip("Start");

pos=1;
timeOut=fltk:Fl_Value_Output( pos*BorderX+(pos-1)*ButtonSizeX, BorderY, ButtonSizeX, ButtonSizeY, "");
timeOut:color(31);
timeOut:value(0);
timeOut:type(1);
timeOut:label("UTC");
timeOut:align(fltk.FL_ALIGN_BOTTOM);

pos=2;
latOut=fltk:Fl_Value_Output( pos*BorderX+(pos-1)*ButtonSizeX, BorderY, ButtonSizeX, ButtonSizeY, "");
latOut:color(31);
latOut:value(0);
latOut:type(1);
latOut:label("Latitude");
latOut:align(fltk.FL_ALIGN_BOTTOM);

pos=3;
longOut=fltk:Fl_Value_Output( pos*BorderX+(pos-1)*ButtonSizeX, BorderY, ButtonSizeX, ButtonSizeY, "");
longOut:color(31);
longOut:value(0);
longOut:type(1);
longOut:label("Longitude");
longOut:align(fltk.FL_ALIGN_BOTTOM);

pos=4;
altOut=fltk:Fl_Value_Output( pos*BorderX+(pos-1)*ButtonSizeX, BorderY, ButtonSizeX, ButtonSizeY, "");
altOut:color(31);
altOut:value(0);
altOut:type(1);
altOut:label("Altitude");
altOut:align(fltk.FL_ALIGN_BOTTOM);


function readGPS()
    while (1) do
           ttyin:flush()
        Fl:check();
        reply = ttyin:read("*line")
        Fl:check();
        parseGPGGA(reply);
    end
end

function parseGPGGA (s)
   _,_,time,lat,ns,long,ew,_,_,_,alt = string.find(s,"([^,]+),([^,]+),([NS]),([^,]+),([EW]),([^,]+),([^,]+),([^,]+),([^,]+)")
   
   if( nil ~= alt ) then
     timeOut:value(time+UTCdiff);
     latOut:value(lat);
     longOut:value(long);
     altOut:value(alt);
     
     Fl:check();
   end
end

function quit_callback(object)
    if fltk.fl_ask("Are you sure to quit now ?") >= 1 then
        window:hide();
        if(running ~= 0) then
            ttyin:close();
        end
    end
    os.exit();
end

function start_callback(object)
    if(running == 0) then
        ttyin = assert(io.open(port, "r"));
        ttyin:flush();
    end
    running=1;
    readGPS();
end

window:callback(quit_callback)
startButton:callback(start_callback)

window:show();
Fl:run();