#! /usr/bin/env murgaLua

-- Application made for easy transcription of interviews.
-- TODO's
-- V decent text editor (take from demos.lua)
-- V mplayer or vlc control (via net or fifo) ...
-- * Nice print output / HTML / odt output ...
-- * configurable options
-- * slower / faster controls
dbg=print
-- Functions to implement
-- togglePlay() 
-- loadSample() 
-- seek() 
-- quit() 
-- init(host,port) 

-- Adding interfacing code {{{
vlc={}

function vlc.init(config) --{{{
	local host=config.host or "localhost"
	local port=tonumber(config.port) or 9876
	local line=([[vlc --extraintf rc --lua-config='rc={hosts={"%s:%s"}}']]):format(host,port)
	print(line)
	fh = io.popen(line)
	murgaLua.sleep(500)
	client,err = socket.connect(host,port)
	if err then print(err) else client:settimeout(0.01) end
	return setmetatable({c=client},{__index=vlc})
end --}}}

function vlc.sendCommand(client, str) --{{{
	print("Command sent: ",str)
	local bytes,err = client.c:send(str.."\n")
	local ret={}
	if not bytes then
		print(err)
	elseif client then
		local fb = client.c:receive()
			while fb do
				ret[#ret+1]=fb
				fb=client.c:receive()
			end
	end
	return table.concat(ret,"")
end --}}}
	
function vlc.loadSample(client,filename) --{{{
	return vlc.sendCommand(client,("add %s "):format(filename))
end --}}}

function vlc.togglePlay(client)
	return vlc.sendCommand(client,"pause")
end

function vlc.quit(client)
	return vlc.sendCommand(client,"shutdown")
end
function vlc.clear(client)
	return vlc.sendCommand(client,"clear")
end
function vlc.seekBack(client,amount)
	local time = client:getTime()-amount
	print(time)
	return vlc.sendCommand(client,("seek %s"):format(time))
end
function vlc.seekForward(client,amount)
	local time = client:getTime()+amount
	print(time)
	return vlc.sendCommand(client,("seek %s"):format(time))
end
function vlc.getTime(client)
	return vlc.sendCommand(client,"get_time")
end

--}}}
	
-- Adding interfacing code, via io.popen	 -- {{{
vlcPipe={state={}}
function vlcPipe.init(config)
	vlcPipe.state.fifo = os.tmpname()
	os.execute("mkfifo ".. vlcPipe.state.fifo)
	local line=([[vlc --extraintf rc --lua-config="rc={prompt=''}" >]]..vlcPipe.state.fifo)
	local fhout,err = io.popen(line,"w")

	murgaLua.sleep(500)
	if err then print(err) end
	local fhin,err = io.open(vlcPipe.state.fifo,"r")
	if err then print(err) end

	local fh={
		send=function(self,str)
			fhout:write(str)
			fhout:flush()
			murgaLua.sleep(100)
		end,
		receive=function(self)
			if io.type(fhin)=="file" then
				return fhin:read("*a")
			else
				return nil
			end
		end,
		close=function(self)
			fhin:close()
		end
		}

	return setmetatable({c=fh},{__index=vlcPipe})
end

function vlcPipe.sendCommand(client, str)
	print("Command sent: ",str)
	local bytes,err = client.c:send(str.."\n")
	if err then print(err) else
		local ret={}
		local fb = client.c:receive()
		print("going into loop after",str)
		--[[while fb do
			ret[#ret+1]=fb
			fb = client.c:receive()
		end

		return table.concat(ret,"") --]]
		return fb
	end
end
	
function vlcPipe.loadSample(client,filename)
	return vlcPipe.sendCommand(client,("add %s "):format(filename))
end

function vlcPipe.togglePlay(client)
	return vlcPipe.sendCommand(client,"pause")
end

function vlcPipe.quit(client)
	client.c:close()
	os.remove(vlcPipe.state.fifo)
	return vlcPipe.sendCommand(client,"shutdown")
end
function vlcPipe.clear(client)
	return vlcPipe.sendCommand(client,"clear")
end
--[ [
function vlcPipe.seekBack(client,amount)
	local time = client:getTime()-amount
	print(time)
	return vlcPipe.sendCommand(client,("seek %s"):format(time))
end
function vlcPipe.seekForward(client,amount)
	local time = client:getTime()+amount
	print(time)
	return vlcPipe.sendCommand(client,("seek %s"):format(time))
end
function vlcPipe.getTime(client)
	return vlcPipe.sendCommand(client,"get_time"):match("(%d+)")
end --]]

--}}}

--- Gui and handling
-- Settings {{{
ww,wh = 600, 500 -- window width and height
mh = 25 -- menu heigth
text_size = 12
text_font=fltk.FL_TIMES
com=vlc--Pipe -- alias for easy changing of backends
com_opts={
	host="localhost",
	port= 9876
	}
skipAmount = 10

file={
	--filename="",
	--modified=false,
	--soundfile=
}
--}}}

-- Callbacks & Functions {{{
cb={}

function dropFile(mess) --{{{
	if file.buffer:length() > 0 --and not file.modified then
	then
		return fltk.fl_choice(mess,"no","yes",NULL)
	else
		return 1
	end
end --}}}

function cb.new() --{{{
	local confirm = dropFile("Sure you want to erase current file, opening a new file?")
	if confirm == 1 then
		file.buffer=fltk.Fl_Text_Buffer()
		editor:buffer(file.buffer)
	else
		w:show()
	end
end --}}}

function cb.quit() --{{{
	local confirm=fltk.fl_choice("Sure you want to quit?","stay","quit",NULL)
	if confirm == 1 then
		if dropFile("Close file and loose changes?") then
			if file.client then
				file.client:quit()
			end
			os.exit(0)
		else
			w:show()
		end
	else
		w:show()
	end -- cancel
end --}}}

function cb.save() --{{{
	local filename
	if not file.filename then
		filename = fltk.fl_file_chooser("Save transcript as...","*.txt","transcript.txt",0)
		if not filename then return end
	else
		filename=file.filename
	end
	
	local test = io.open(filename,'w+')
	if test then
		test:close()
		if lfs.attributes(filename) then
			local confirm = fltk.fl_choice("File exists, overwrite?","No","Yes",NULL)
			if not confirm then return end
		end
		local retval = file.buffer:savefile(filename)
		if retval ~= 0 then
			fltk.fl_message("Error while writing file: "..retval)
			return
		else
			file.filename=filename
		end
	end
end --}}}

function cb.open() -- {{{
	local confirm = dropFile"Open other file, loosing changes to current file?"
	if confirm==1 then
		local filename=fltk.fl_file_chooser("Open transcript","*.txt","transcript.txt",0)
		if filename then
			local test = io.open(filename,"r")
			if test then
				local retval = file.buffer:loadfile(filename)
				if retval ~= 0 then
					fltk.fl_message("Error while writing file: "..retval)
					return
				end
				file.filename = filename
			end
		end
	end
end --}}}

function cb.open_audio () --{{{
	local filename = fltk.fl_file_chooser("Choose soundfile to transcribe","{*.mp3,*.wma,*.ogg,*.wav}",0)
	if filename then
		local test = io.open(filename,"r")
		if test then
			if not file.client then
				file.client = com.init(com_opts)
			end
			file.soundfile = filename
			file.client:clear()
			file.client:loadSample(filename)
		end
	end
end --}}}

function cb.toggle_play() --{{{
	if file.client then
		file.client:togglePlay()
	else
		fltk.fl_message("Please load an audio file first")
	end
end --}}}

function cb.skipBack() --{{{
	if file.client then
		file.client:seekBack(skipAmount)
	else
		fltk.fl_message("Please load an audio file first")
	end
end --}}}

function cb.skipForward() --{{{
	if file.client then
		file.client:seekForward(skipAmount)
	else
		fltk.fl_message("Please load an audio file first")
	end
end --}}}

function cb.getTime() --{{{
	print("File.client = ",file.client)
	if file.client then
		local time=file.client:getTime()
		print(time)
		if time then
			fltk.fl_message("Time is "..time) 
		else
			fltk.fl_message("Could not get time")
		end
	end
end
--}}}
--}}}
w = fltk.Fl_Double_Window(0,0,ww,wh, arg[0])
w:callback(cb.quit)

file.buffer=fltk:Fl_Text_Buffer()

editor=fltk:Fl_Text_Editor(0,mh,ww,wh-mh)
--editor:textfont(fltk.FL_SCREEN) -- reading code SUCKS with a variable-width font
editor:textsize(text_size) -- initial size of text
editor:textfont(text_font)
editor:wrap_mode(1,100)
editor:buffer(file.buffer)

local char=string.byte
menu = fltk:Fl_Menu_Bar(0, 0, ww, mh)
menu:add("&File/&New"       ,fltk.FL_CTRL+char'n',cb.new)
menu:add("&File/&Save"      ,fltk.FL_CTRL+char's',cb.save)
menu:add("&File/&Open"      ,fltk.FL_CTRL+char'o',cb.open)
menu:add("&File/Open &Audio",fltk.FL_CTRL+fltk.FL_SHIFT+char'o',cb.open_audio)
menu:add("&File/&Quit"      ,fltk.FL_CTRL+char'q',cb.quit)

menu:add("Control/&Toggle Play",fltk.FL_CTRL+char' ',cb.toggle_play)
menu:add("Control/"..skipAmount.."seconds &back",fltk.FL_CTRL+char'l',cb.skipBack)
menu:add("Control/"..skipAmount.." seconds &forward",fltk.FL_CTRL+char'm',cb.skipForward)
menu:add("Control/&Get Time",fltk.FL_CTRL+char't',cb.getTime)

menu:add("Help/&About"     ,nil                 ,cb.about)
menu:add("Help/&Manual"    ,nil                 ,cb.manual)

fltk.Fl_End() -- end of window
w:resizable(editor)
--w:resizable(menu)
w:show()
Fl:run()
-- vim:fdm=marker
