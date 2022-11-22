w=fltk:Fl_Double_Window(220,60,"password.lua")
-- The fl_password dialog is not the most
-- secure way to password-protect ANYTHING,
-- but it probably suits a need somewhere.


-- This is the file that stores your password.
-- It should be chmod 600 if you want it to have any security.
function password_callback()
password_file = "thisisapasswordfile"

-- Try to open the file and grab the first line
password_check = io.open(password_file,"r")
if password_check then password = password_check:read("*l")
password_check:close()
else
password = "god"
end
-- If file exists, but is empty
if password == "" then password = "god" end
-- password dialog
enter_password = fltk.fl_password("password is \""..password.."\"")
if enter_password == password then
  fltk.fl_message("Congratulations! You can read and type!")
else
  fltk.fl_alert("NO!")
end
end

password_button=fltk:Fl_Return_Button(10,10,200,30,"click")
password_button:callback(password_callback)
w:show()
Fl:run()
