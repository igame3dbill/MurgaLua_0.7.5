#!/usr/bin/murgaLua

-- Define the constants
host  = "127.0.0.1"
port  = 6969

-- Ask what mode we want to run in
if fltk.fl_choice("Are you a client or a server (start the server first)",
               "Client", "Server", nil) >= 1
then
  server = assert(socket.bind("*", port))
  serverMode = "server"
  fltk.fl_message("Chat window will appear when a connection is received\n" ..
                  "Listening on PORT : " .. port .. "...")
  print ("Listening on PORT '" .. port .. "', please connect with a client.")
  io.flush()
  client = server:accept()
else
  client = assert(socket.connect(host, port))
  serverMode = "client"
end

-- If you are going to use a callback it has to be defined before it's used.
function quit_callback(w)
   if fltk.fl_choice("Are you sure you want to EXIT ?", "No", "Yes", nil) >= 1 then
      window:hide()
      os.exit()
   end
end

window = fltk:Fl_Window(295, 132, "Tiny Chat " .. serverMode)
window:callback(quit_callback)

messageInput  = fltk:Fl_Input(5, 80, 285, 25);
messageOutput = fltk:Fl_Browser(5, 5, 285, 70);
quitButton    = fltk:Fl_Button(230, 105, 60, 25, "Quit");
sendButton    = fltk:Fl_Return_Button(5, 105, 70, 25, "Send");

quitButton:callback(quit_callback)
   
sendButton:callback(
    function(sendButton)
        messageOutput:add("Sent : " .. messageInput:value())
        messageOutput:bottomline(messageOutput:size())        
        assert(client:send(messageInput:value() .. "\n"))
        
        messageInput:value("")

    end
)
	
window:show()

-- client:setoption("tcp-nodelay", true)
client:settimeout(0.10)
   
while 1 do

   	line, err = client:receive('*l')

    if (line)
    then
        messageOutput:add("Recv : " .. line)
        messageOutput:bottomline(messageOutput:size())  
    end 
	  
    Fl:check()
    murgaLua.sleep(10)

end
