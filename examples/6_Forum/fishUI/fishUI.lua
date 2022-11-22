-- Changelog
-- V Redrawing
-- V Stopping execution (and resuming afterwards)
-- V Rerunning a sample
-- V Finer control of delay.
-- V Fix multiline source highlighting during run.
-- V Stack display
-- V Update code in editor when there are changes to the codebox. (But only if it changes an already existing character,
--   else we get messed up with the codebox indexing by y,x and the editor indexing only by position in stream.)
-- 
-- TODO's
-- * Input handling
-- * Resizing the window, and between in and output for more elaborate examples like the 99 Bottles one.
-- * Fast mode: no more gui fidling, only output final result. Needs better separation of logic and gui.
--
-- LIMITATIONS
-- So apparently the "official" <>< specs changed, this program keeps to the original operations, as found here:
-- http://esolangs.org/w/index.php?title=Fish&oldid=22153.
-- It's dead slow compared to a plain lua implementation.
-- Currently there is no GUI input handling (feel free to contribute)
-- Only visualizes the codebox in the first quadrant, and only if there already is a character there. This is because the editor indexes by position and the 
-- codebox by x,y. If adding characters we would mess up the mapping between c and meta_c.
--
-- README
-- There are 3 big concepts in Fish:
-- * A global codebox, a 2-D grid containing the code, which is modifyable by the code
--   This contains all code, and is read in initially. The Instruction Pointer starts at 0,0 in the 1,0 direction (to the right).
--   The IP will wrap around in any direction to the oposite side. If the IP wraps from the far side (end of line, or over the last line) it wraps
--   back to the beginning at x=0 or y=0 respectively, regardless whether there are any characters written by the program in the other 3 quadrants. As a 
--   consequence, these can be used to store values without influencing the flow of code.
--
-- * A global stack
--
-- * A pool of threads which all have their own stack
--
-- The sourcecode can contain any character, but you will activate the improbability drive when you encounter a character outside of
-- the instruction set.
-- The available instructions are:
-- > < ^ v		Set the direction of the IP in this direction
-- / \ | _ #	Mirror the direction of the IP depending on the current direction
-- 				(>^,<v, v>, ^>; >v,<^,v>, ^<; ><, <>, vv, ^^; >>,<<,v^,^v;><,<>,v^,^v)  
-- x			Set a random direction
-- + - * , %	Pop A, Pop B, push (B operator A), resp plus, minus, multiply, divide, modulo
-- =,),( 		Pop A, pop B, push 1 if A equal, greater than, smaller than B, respectively. 0 otherwise.
-- !			Skip next instruction inconditionally
-- ?			Skip next instruction if top of the stack equals 0 or the stack is empty
-- :			Duplicate the value at the stack top
-- ~			Pops the stack top
-- $ @ 			Rotate 2 resp 3 at the top clockwize, so 1234 -> 1243 and 1234-> 1423
-- &			If the registry is free, pops the stacktop and stores it in the registry. Otherwise pushes the value in the registry
-- r			Reverse the stack
-- }{			Rotate the entire stack clockwise or counterclockwise (1234 -> 4123 and 1234-> 2341, resp)
-- g			Pop A, Pop B, push the value of the codebox at (B,A)
-- p			Pop A, Pop B, Pop C, change the value of the codebox at (C,B) to A
-- o n			Output character or number
-- i 			takes one character as input and push it on the stack
-- ;			End program (necesarry as otherwise the codebox just wraps)
-- [			Create new thread at next direction change (old thread just skips to the next instruction) 
-- ]			End thread
-- .			Switches between local and global stack
-- m			pops values from current stack, and puts them on the other
-- X			Output debugging info to the console
--
-- The interface itself is dead simple:
-- Put in your code in the editor, set a convenient delay between each step with the roll input.
-- Hit run to run the program, use backspace to interrupt, and use step to go step by step.
-- Reset does what it says, and resets the execution state.
--
-- Have fun with this. And feel free to adapt to the new specs, or whatever.
--
-- Jan-Pieter
--
-- configuration --
demos={
	HelloWorld=[["Hello, World!"r>?o?<;]],
	SimpleLoop=[[4>:n?v;,
 ^ -1<]],
	BottlesOfBeer=[[
b9*v
   \:n" bottles"r:&r&1=?~~" of beer on the wall,"a0r&> ?o?<~&
   \:n" bottles"r:&r&1=?~~" of beer."a0r&> ?o?<~&
   \"Take one down, pass it around,"a0r&> ?o?<~&
   \1-:0=?v~:n>" bottles of beer on the wall."aa0r&> ?o?<~&
;!?/
          ~   ^     <
          >"No more"^]],
	SelfMod=[[30"`"1+::o&p&"y"(?;]]
}

size=10
font=fltk.FL_COURIER
def_delay=100
def_delay_step=50
-- end config --

-- parsing different commands
p=function(state, where, what) --push
	local str=("%d (%s)"):format(what or where ,((what or where)>31 and (what or where)<127) and string.char(what or where) or "_")
	if what then
		if where==1 then
			win.stack:add(str)
			table.insert(state.s,where,what) -- push on stack
		else print("Freak event inserting at some pos ~= end and pos ~= begin") end
	else
		win.stack:insert(1,str)
		table.insert(state.s,where) -- push on stack
	end
end
P=function(state, which) --Pop
	win.stack:remove(1)
	return table.remove(state.s,which)
end
W=function(...) win.output_buffer:append(...) end 
t="><^v/\\|_#x+-*,%=)(!?:~$@&r}{gponi;[].mX"		-- all tokens
C=t.char
B=t.byte
F=t.match
M=setmetatable
f={
"s.dx,s.dy=1,0","s.dx,s.dy=-1,0","s.dx,s.dy=0,-1","s.dx,s.dy=0,1",
"s.dx,s.dy=-s.dy,-s.dx","s.dx,s.dy=s.dy,s.dx","s.dx=-s.dx","s.dy=-s.dy","s.dx,s.dy=-s.dx,-s.dy",
"z=math.random(1,4)f[('><^v'):sub(z,z)]()",
"p(s,P(s)+P(s))","p(s,-P(s)+P(s))","p(s,P(s)*P(s))",
"z=P(s)if z~=0 then p(s,P(s)/z)else error'Div by 0'end","y=P(s)z=P(s)p(s,z%y)", -- div
"p(s,P(s)==P(s) and 1 or 0)",
"p(s,P(s)>P(s) and 1 or 0)",
"p(s,P(s)<P(s) and 1 or 0)",
"s.x,s.y=s.x+s.dx,s.y+s.dy",
"if #s.s==0 or s.s[#s.s]==0 then f['!'](s) end",
"p(s,s.s[#s.s])",
"P(s)",
"z=#s.s s.s[z],s.s[z-1]=s.s[z-1],s.s[z]",
"z=#s.s s.s[z],s.s[z-1],s.s[z-2]=s.s[z-1],s.s[z-2],s.s[z]",
"if s.r then p(s,s.r)s.r=nil else s.r=P(s)end",
"if s.s==s.l then z=s.l s.l={}s.s=s.l else z=S S={}s.s=S end for k=1,#z do s.s[#z-k+1]=z[k]end redrawStack(s)",
"p(s,1,P(s))",
"p(s,P(s,1))",
"z=P(s) p(s,c[P(s)][z])",
"local A,B,C=P(s),P(s),P(s) c[B][C]=A local pos=meta_c[B][C] if pos then win.edt_buffer:replace(pos,pos+1,string.char(A)) end",
"W(C(P(s)))",
"W(P(s))",
"z=io.read(1) if not z then p(s,4)else while z:match'%s'do z=io.read(1)if not z then z='\\4'end end p(s,B(z))end",
"fltk.fl_message('Fish program quit')win.edt:activate() step=coroutine.create(function()return end) coroutine.resume(step)", --"os.exit()"
"T.nt=true",
"table.insert(T,s.id)for k=s.id,#T do T[k].id=k end", -- update self.id after removing a thread.
"s.s = s.s==S and s.l or S redrawStack(s)", -- TODO Stack redraw
"z= s.s==S and s.l or S for k=#s.s,1,-1 do table.insert(z,P(s,1))end",
"dbg(s)",
}

function dbg(s)
	print""
	print("Current Stack:",s.s==s.l and "Local Stack" or "Global Stack")
	print("Local stack:")
	for k,v in pairs(s.l) do print("",k,v,v>=0 and string.char(v) or "NEG") end
	print("Global stack:")
	for k,v in pairs(S) do print("",k,v,v>=0 and string.char(v) or "NEG") end
	print("Register: ",s.r)
	print("Codebox:")
	for k=0,#c do
		io.write(string.format("%0"..#tostring(#c).."i",k),": ")
		for l=0,#c[k] do
			io.write(string.char(c[k][l]))
		end
		io.write"\n"
	end
end

-- Linking commands to functions
z=1
for k in t:gmatch"." do -- will contain the tokens
	--TODO setfenv / setmetatable to avoid all indexing in functions.
	f[k]=assert(loadstring("s=...;"..f[z]))
	z=z+1
end
function run()

T={		-- table of threads
	--nt = new thread to be created.
	}
c={}	-- codebox IP wraps around
meta_c = {} -- data about the codebox
S={}	-- global stack
-- codebox layout
--     -----> +x
--  @  |line of text			-- wrap around to second line
--     |second line of text.	-- negative indices can be used for variables
--     |
--     V +Y

-- y first coord, x second
-- wrap around rows if nil row
-- wrap around cols if nil char.
function T.n(T,x,y,dx,dy) -- New thread function
	z={
	id=#T+1,					-- keep number id
	l={},					-- local stack
	dx=dx or 1,					-- 1 for +x, -1 for -x, 0 for y/-y
	dy=dy or 0,					-- 1 for +y, -1 for -y, 0 for x/-x 
	x=x or 0,					-- X of IP
	y=y or 0,					-- Y of IP
	-- i,					-- will contain type of quote when reading in a string 
	-- r,					-- registry
	}
	z.move=function(s)
		s.x,s.y=s.x+s.dx,s.y+s.dy
		if s.y > #c then
			s.y=0
		elseif s.y<0 then
			s.y=#c
		end
		if s.x>#c[s.y] and s.dx==1 then
			s.x=0
		elseif s.x<0 then
			s.x=#c[s.y]
		end
		-- update highlight of current command
		local pos = meta_c[s.y][s.x]
		if pos and pos >=0 then
			win.edt_buffer:highlight(pos,pos+1)
		end
		-- update stack display
		if type(win.curr_stack) and win.curr_stack~= s.id then
			redrawStack(s)
		end
	end
	z.s=z.l -- current stack is local stack
	T[z.id]=z	-- add at next index
end
T:n(-1)

-- compile to codebox
--fh= arg[1] and io.open(arg[1]) or io.stdin	-- use file or stdin
-- Todo: find a way to "lock" the editor.
win.edt:deactivate()
y=0;pos=0
while pos<=win.edt_buffer:length() do
	c[y]=M({},{__index=function()return 32 end})--default to space
	meta_c[y] = {} --M({},{__index=function()return -1 end})

	local l = win.edt_buffer:line_text(pos)
	for k=1,#l do
		local z=l:sub(k,k)
		if not i then		-- normal mode
			if F(z,"['\"]") then i=z end
			if F(z,"[^\n\r]")then --filter out only newlines
				c[y][k-1]=B(z)
			end -- any spacing allowed.
		else				-- verbatim string mode
			if z==i then i=nil end
			c[y][k-1]=B(z)
		end
		meta_c[y][k-1] = pos
		pos=pos+1
	end
	pos=pos+1 -- accounts for newline character
	y=y+1
end

while #T>0 do
	for id=1,#T do
		s=T[id]
		s:move()	  -- move the IP
		n,o=s.dx,s.dy -- keep old directions for new thread detection
		q=C(c[s.y][s.x])
		if s.i then						-- stringparsing mode		
			if F(q,"['\"]") then		-- end-quote
				s.i=nil
			else
				p(s,c[s.y][s.x])	-- push contents of box, then advance
			end
		else 							-- not in string parsing mode
			if F(q,"['\"]") then		-- start-quote
				s.i=q
			elseif F(q,"%x") then		-- parsing a number
				p(s,tonumber(q,16))
			elseif F(q,"[^ ]") then
				assert(f[q])
				f[q](s)	-- call, feed with state/thread
			end
		end
	end
	if T.nt and (n~=s.dx or o~=s.dy) then
		-- create new thread
		T:n(s.x,s.y,s.dx,s.dy)
		T.nt=nil
		s.dx,s.dy=n,o		-- restore directions of parent
	end
	coroutine.yield()
end
end

function redrawStack(s)
	if s.s==s.l then
		win.stack:label("Local "..s.id)
	else
		win.stack:label('Global')
	end -- set title
	win.stack:clear()
	for k=#s.s,1,-1 do
		win.stack:add(("%d (%s)"):format(s.s[k],(s.s[k]>31 and s.s[k]<127) and string.char(s.s[k]) or "_"))
	end
	win.curr_stack=s.s==s.l and s.id or "g" -- set stack
end


win = {}
  win.window = fltk:Fl_Double_Window(334, 210, 625, 355, "Fish interpreter")
  do
	win.edt_buffer = fltk:Fl_Text_Buffer()
    win.edt = fltk:Fl_Text_Editor(25, 25, 260, 280)
	win.edt:buffer(win.edt_buffer)
	win.edt:textfont(font)
	win.edt:textsize(size)
	win.edt:selection_color(fltk.FL_BLACK)

	win.output_buffer = fltk:Fl_Text_Buffer()
    win.output = fltk:Fl_Text_Display(285, 25, 260, 280)
	win.output:buffer(win.output_buffer)
	win.output:textfont(font)
	win.output:textsize(size)
	win.output:selection_color(fltk.FL_BLACK)

	win.stack = fltk:Fl_Select_Browser(550,25,70,280)
	win.stack:label("Global") -- TODO fix label
	win.stack:textfont(font)
	win.stack:textsize(size)
	win.curr_stack="g"

    win.rol = fltk:Fl_Roller(105, 320, 45, 25, "Delay")
    win.rol_output = fltk:Fl_Value_Output(160, 320, 50, 25)
	win.rol:type(fltk.FL_HORIZONTAL)
    win.rol:align(4)
    win.rol:step(def_delay_step)
	win.rol:bounds(0,10000)
	win.rol_output:value(def_delay)
	win.rol:callback(function() win.rol_output:value(win.rol:value()) end)

	function reset()
		step=nil
		step=coroutine.create(run)
		win.edt:activate()
		win.output_buffer:text''
		win.stack:clear()
	end
    win.reset = fltk:Fl_Button(215, 320, 70, 25, "Reset")
	win.reset:callback(reset)
    local o = fltk:Fl_Button(285, 320, 70, 25, "Step")
	o:callback( function() local res,err = coroutine.resume(step) if not res then fltk.fl_alert("program error:\n"..err) end
end)
    local o = fltk:Fl_Button(355, 320, 70, 25, "Run")
	o:callback(function()
		if coroutine.status(step) == "dead" then
			local res = fltk.fl_choice("Program ended. Restart?","Cancel","OK",NULL)
			if res ~= 0 then -- Yes, restart. reinitiate coroutine and empty output buffer.
				reset()
			end
		end
		while coroutine.status(step)~="dead" do
			local res,err = coroutine.resume(step)
			if not res then fltk.fl_alert("program error:\n"..err) reset() end
			win.output:redraw()
			Fl:wait()
			if Fl:event_key()==fltk.FL_BackSpace then break end -- spacebar pressed
			murgaLua.sleepMilliseconds(win.rol_output:value())
		end
	end)
	win.demos = fltk.Fl_Choice(425,320,150,25)
	for k in pairs(demos) do win.demos:add(k) end
	win.demos:value(3)
	win.demos:callback(function()
		reset()
		win.edt_buffer:text(demos[win.demos:text()])
	end)
  end
  fltk.Fl_End()
  reset()
  win.window:show()
  win.edt_buffer:text(demos.HelloWorld)
Fl:run()
