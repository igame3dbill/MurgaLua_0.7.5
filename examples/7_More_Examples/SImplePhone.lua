--[[Here's a little gui wrapper I wrote for a perl command-line program. 
(The command-line program is a very simple push-to-talk half-duplex secure voice demo 
that let's you talk to another net connected PC running the same program. 
 http://perlmonks.org/?node_id=639207)]]--

-- http://www.murga-projects.com/forum/showthread.php?tid=237
-----------------------------------------------------------------
-- sf.lua - gui wrapper for command-line simple phone, ph.pl  ---
--  Usage:   sf.lua [Fn]
--  Example: sf.lua F2    # use F2 for the push-to-talk key
-----------------------------------------------------------------

talk_key = arg[1] or 'F12'; -- F1 - F12
port = 7272
ringtone_sound_file = 'ringtone2.wav'
ring = false

Fl:scheme("plastic")
fltk.fl_register_images()
image_oldph2 = Fl_Shared_Image.get("oldph2.gif");

-- ph.pl -WS writes status in .ph.stat and PID in .ph.pid
function get_ph_stat_file(fname)
  local status = nil;
  statf = io.open(fname,"r");
  if statf then
     status = statf:read();
     statf:close();
  end
  return status;
end
function get_ph_pid()
  return get_ph_stat_file('.ph.pid')
end
function get_ph_status()
  return get_ph_stat_file('.ph.stat')
end

function signal_ph_process(signum)
  local pid = get_ph_pid();
  if pid then
    os.execute("./kill -"..signum.." "..pid.." 2>/dev/null >/dev/null");
  end
end
function stop_ph_process() -- SIGUSR1 (30) = req. smooth shutdown
   signal_ph_process(30) -- INT or KILL sigs shutdown ph even faster
end

function ip_address1() -- the IP we want as the receiver's localhost. (first guess)
  return pattern_cmd_slurp("ipconfig /all",
    'IP Address. . . . . . . . . . . . : (%d+\.%d+\.%d+\.%d+)')
end
function ip_address2() -- the IP we want as the receiver's localhost. (2nd guess)
  return pattern_cmd_slurp(
    "perl -MLWP::Simple -e 'print get($ARGV[0]);' http://checkip.dyndns.org/",
    '(%d+\.%d+\.%d+\.%d+)')
end
function pattern_cmd_slurp(cmd,pattern)
   local fh = io.popen(cmd)
   local match = nil 
   if fh then
        local slurp = fh:read("*a");
        if slurp then
                match = string.match(slurp,pattern)
        end 
        fh:close()
   end 
   return match
end

function quit_callback(w)
   if fltk.fl_choice("Exit simple phone?", "No", "Yes", nil) >= 1 then
      stop_ph_process()
      window:hide()
      os.exit()
   end 
end

-- gui dialog widgets, layout
window = fltk:Fl_Double_Window(289, 196, "simple phone");
window:callback(quit_callback)
menuBar = fltk:Fl_Menu_Bar(0, 0, 395, 25);
local host = fltk:Fl_Input(47, 45, 165, 25, "host");
local listen_button = fltk:Fl_Button(19, 155, 70, 25, "listen");
local call_button = fltk:Fl_Button(224, 45, 45, 25, "call");
local stop_button = fltk:Fl_Button(200, 155, 65, 25, "stop");
local status = fltk:Fl_Text_Display(110, 75, 160, 80);
local key_display = fltk:Fl_Output(140, 155, 42, 25, "talk");
local img_tile = fltk:Fl_Tile(25, 150, 80, 80);
img_tile:image(image_oldph2);


menuBar:callback(
function (w)
   if string.match( w:text(), "&listen" ) then
       listen_for_calls()      
   end
   if string.match( w:text(), "&riginate" ) then
       originate_call()      
   end
   if string.match( w:text(), "&stop" ) then
       stop_ph()      
   end
   if string.match( w:text(), "&password" ) then
       password = fltk:fl_password("secret password");
   end
   if string.match(w:text(),'Blowfish')
   or string.match(w:text(),'DES')
   or string.match(w:text(),'CAST5')
   or string.match(w:text(),'Twofish')
   or string.match(w:text(),'Twofish2')
   or string.match(w:text(),'Serpent')
   or string.match(w:text(),'Anubis')
   or string.match(w:text(),'Camellia')
   then 
       cipher = w:text();
   end
   if string.match(w:text(),'F1')
   or string.match(w:text(),'F2')
   or string.match(w:text(),'F9')
   or string.match(w:text(),'F10')
   or string.match(w:text(),'F11')
   or string.match(w:text(),'F12')
   then
    talk_key = w:text();
    key_display:value(talk_key);
   end
   if string.match( w:text(), "ipconfig" ) then
       host:value( ip_address1()..':'..port );
   end
   if string.match( w:text(), "ch&eckip" ) then
       host:value( ip_address2()..':'..port );
   end
   if string.match( w:text(), "ring tone" ) then
       ring = not ring
   end
   if string.match( w:text(), "&play mixer" ) then
       os.execute("sndvol32.exe /play &");
   end
   if string.match( w:text(), "&record mixer" ) then
       os.execute("sndvol32.exe /rec &");
   end
   if string.match( w:text(), "e&xit" ) then
       quit_callback()      
   end
end )
menuBar:add("&File/e&xit");
menuBar:add("&Call/&listen");
menuBar:mode( 4, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Call/&originate");
menuBar:mode( 5, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Call/&stop");
menuBar:mode( 6, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO
         + fltk.FL_MENU_VALUE);
menuBar:add("&Set/&password");
menuBar:add("&Set/&cipher/DES");
menuBar:mode(11, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/CAST5");
menuBar:mode(12, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/Blowfish");
menuBar:mode(13, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO
         + fltk.FL_MENU_VALUE);
menuBar:add("&Set/&cipher/Twofish");
menuBar:mode(14, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/Twofish2");
menuBar:mode(15, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/Serpent");
menuBar:mode(16, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/Anubis");
menuBar:mode(17, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/Camellia");
menuBar:mode(18, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/CipherSaber");
menuBar:mode(19, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/Eksblowfish");
menuBar:mode(20, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/IDEA");
menuBar:mode(21, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/Khazad");
menuBar:mode(22, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/RC5");
menuBar:mode(23, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/RC6");
menuBar:mode(24, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/Rainbow");
menuBar:mode(25, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/Rijndael");
menuBar:mode(26, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/SEAL2");
menuBar:mode(27, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/&cipher/Square");
menuBar:mode(28, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/push-to-talk &key/F1");
menuBar:mode(31, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/push-to-talk &key/F2");
menuBar:mode(32, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/push-to-talk &key/F9");
menuBar:mode(33, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/push-to-talk &key/F10");
menuBar:mode(34, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/push-to-talk &key/F11");
menuBar:mode(35, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/push-to-talk &key/F12");
menuBar:mode(36, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO);
menuBar:add("&Set/host:port for Receiver (use &ipconfig)");
menuBar:add("&Set/host:port for Receiver (use ch&eckip)");
menuBar:add("&Set/play &ring tone");
menuBar:mode(40, fltk.FL_MENU_TOGGLE );
menuBar:add("&Mixer/&play mixer");
menuBar:add("&Mixer/&record mixer");
menuBar:global()

status_buf = fltk:Fl_Text_Buffer();
status:buffer( status_buf );
status_buf:text("Ready to listen/call");
key_display:value(talk_key);

function ph_cmd_string(opts)
  local cmd = "./perl -I./lib ph.pl -WS -k "..talk_key
  if cipher then cmd = cmd..' -cipher '..cipher end
  if password then cmd = cmd..' -PW '..password end
  if ring then cmd = cmd..' -ring '..ringtone_sound_file end
  if opts then cmd = cmd..' '..opts end
  return cmd..' '..host:value();
end

ph_cmd = nil;

function listen_for_calls() -- wait for calls
  stop_ph_process(); -- if any
  ph_cmd = io.popen(ph_cmd_string())
  menuBar:mode( 4, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO + fltk.FL_MENU_VALUE);
  menuBar:mode( 5, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO );
  menuBar:mode( 6, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO );
end
listen_button:callback(listen_for_calls)

function orginate_call() -- originate a call to target host/IP
  status_buf:text(" calling ");
  ph_cmd = io.popen(ph_cmd_string('-c'))
  status_buf:text(" press "..talk_key.." to talk");
  menuBar:mode( 4, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO );
  menuBar:mode( 5, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO + fltk.FL_MENU_VALUE);
  menuBar:mode( 6, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO );
end
call_button:callback(orginate_call)

function stop_ph() -- stop call and/or  stop listening
  status_buf:text(" stopping ");
  stop_ph_process();
  ph_cmd = nil;
  menuBar:mode( 4, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO );
  menuBar:mode( 5, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO );
  menuBar:mode( 6, fltk.FL_MENU_TOGGLE + fltk.FL_MENU_RADIO + fltk.FL_MENU_VALUE);
end
stop_button:callback(stop_ph)

-- poll for status text from .ph.stat, display it
show_status_timer_delay = 1
function show_status_callback(eventValue)
  if ph_cmd then
    local ph_status = get_ph_status()
    if ph_status then
      status_buf:text(ph_status)
    end
  end
  show_status_timer:value(show_status_timer_delay)
end
show_status_timer = fltk:Fl_Timer(FL_HIDDEN_TIMER, 0,0,0,0,"0")
show_status_timer:callback(show_status_callback)
show_status_timer:value(show_status_timer_delay)

window:show();
Fl:run();