-----------------------------------------------------------------------------------
dofile("cfg.ini")

bl=-25
isjoin=nil
------------------------Draw GUI begin--------------------------------------------
ww,wh,wt=600,477,"Simple IRC Client - Powered by jyf1987"

w= fltk:Fl_Window(ww,wh,wt)
w:callback(function()
if fltk.fl_choice("Are you sure you want to EXIT ?", "No", "Yes", nil) >= 1 then
w:hide()
os.exit()
end
end)

msgout= fltk:Fl_Browser(5, 5, ww-10, wh-40)

msgin= fltk:Fl_Input(5, wh-30, ww-10, 25)
msgin:callback(
function()
iput(rd,msgin:value())
print("< "..cfg.nick.." > :"..msgin:value())
msgout:bottomline(msgout:size())
msgin:value("")
end
)
msgin:when(fltk.FL_WHEN_ENTER_KEY_ALWAYS)
w:show()
Fl:flush()
Fl:check()
Fl:wait(1)
w:make_current()
------------------------Draw GUI end-----------------------------------------------

------------------------------Utils------------------------------------------------
split=function(str, pat)
if (str==nil) then return {"", ""} end
local t = {} -- NOTE: use {n = 0} in Lua-5.0
local fpat = "(.-)" .. pat
local last_end = 1
local s, e, cap = str:find(fpat, 1)
while s do
if s ~= 1 or cap ~= "" then
table.insert(t,cap)
end
last_end = e+1
s, e, cap = str:find(fpat, last_end)
end
if last_end <= #str then
cap = str:sub(last_end)
table.insert(t, cap)
end
return t
end

print=function(str)
msgout:add(str)
msgout:bottomline(msgout:size())
bl=bl+1
if (bl>0) then
msgout:remove(1)
bl=bl-1
Fl:redraw()
end
end
------------------------------Irc func---------------------------------------------
function iput(skt,msg)
skt:send("PRIVMSG "..cfg.chanel.." :"..msg.."\n")
end

function ipong(skt)
skt:send('PONG 123456')
end

function iquit(skt)
skt:send('QUIT')
skt:close()
end

function onjoin(skt,hstr)
local usr=string.match(hstr[1],":(.*)!")
if ((isjoin==nil) and cfg.debug) then
cfg.debug=nil
end
print(usr.." JOIN "..cfg.chanel)
end

function onquit(skt,hstr)
local usr=string.match(hstr[1],":(.*)!")
print(usr.." QUIT "..cfg.chanel)
end

function onmsg(skt,hstr)
local hstr=hstr
local usr=string.match(hstr[1],":(.*)!")
--print(usr)
table.remove(hstr,1)
table.remove(hstr,1)
table.remove(hstr,1)
local msg=table.concat(hstr,"\032")
print("< "..usr.." > "..msg)
end
-----------------------------------------------------------------------------------
rd=socket.connect(cfg.host,cfg.port)
rd:settimeout(0.03)

rd:send("USER "..cfg.user.." hi.baidu.com/jyf1987 "..cfg.host.." :"..cfg.user.."\n")

rd:send("NICK "..cfg.nick.."\n")

if (cfg.pwd and cfg.pwd~="") then
rd:send("PRIVMSG /msg nickserv identify "..cfg.pwd.."\n")
end
rd:send("JOIN "..cfg.chanel.."\n")

s=rd:receive('*l')

while 1 do

if s then
if (string.find(s,"PING"))==1 then 
print(s)
ipong(rd)
s=rd:receive('*l')
end

local debug=(cfg.debug=="on") and print("Debug: "..s)
local hstr=split(s,"%s")
--print(#hstr[2])
---------------------hook event----------------------------------- 

if hstr[2]=="JOIN" then
onjoin(rd,hstr) 
elseif hstr[2]=="PRIVMSG" then
onmsg(rd,hstr) 
elseif hstr[2]=="PART" then
onquit(rd,hstr)
end

------------------------------------------------------------------ 
end
s=rd:receive('*l')
Fl:check()

Fl:wait(0.01)
--murgaLua.sleep(10)
end
