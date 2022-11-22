
--
-- Simple calculator by dvw86
--
-- Taken from : http://www.murga-projects.com/forum/showthread.php?tid=14
--

-- Define the total
total = "0"

-- Define the memory
memory = "0"

-- Define the erase status
erase = "1"

-- Define the text buffer
buffer = "0"

-- Define the Point value
Point = "0"

-- Define the function value
func = "no"

-- Define the error message
errormsg = "No Errors"

--Define the error function
function error()
fltk.fl_alert(errormsg)
ButtonC:take_focus()
errormsg = "No Errors"
ErrorIcon:hide()
end

-- Define the clear function
function clear()
total = "0"
erase = "1"
buffer = "0"
Point = "0"
func = "no"
errormsg = "No Errors"
ErrorIcon:hide()
PlusIcon:hide()
MinusIcon:hide()
TimesIcon:hide()
DivideIcon:hide()
outputWindow:value(buffer)
end

-- Define the CheckBuffer function
function CheckBuffer()
bcount = string.gsub(buffer, "%.", "")
bcount = string.len(bcount)
if bcount<17
then
outputWindow:value(buffer)
else
errormsg = "Too many digits."
ErrorIcon:show()
end
end

-- Define the calculate function
function calculate()
--fltk.fl_alert(func)
--fltk.fl_alert(buffer)
if func == "add"
then
total = value + buffer
buffer = "0"
outputWindow:value(total)
elseif func == "sub"
then
total = value - buffer
buffer = "0"
outputWindow:value(total)
elseif func == "mult"
then
total = value * buffer
buffer = "0"
outputWindow:value(total)
elseif func == "div"
then
total = value / buffer
buffer = "0"
outputWindow:value(total)
end
Point = "0"
func = "no"
PlusIcon:hide()
MinusIcon:hide()
TimesIcon:hide()
DivideIcon:hide()
a, b = string.find(total, "%a")
if a~=nil
then
errormsg = "Logical error."
ErrorIcon:show()
end
end

-- Define the Plus function
function Plus()
calculate()
erase = "1"
func = "add"
value = outputWindow:value()
PlusIcon:show()
MinusIcon:hide()
TimesIcon:hide()
DivideIcon:hide()
end

-- Define the Minus function
function Minus()
calculate()
erase = "1"
func = "sub"
value = outputWindow:value()
PlusIcon:hide()
MinusIcon:show()
TimesIcon:hide()
DivideIcon:hide()
end

-- Define the Multipy function
function Multiply()
calculate()
erase = "1"
func = "mult"
value = outputWindow:value()
PlusIcon:hide()
MinusIcon:hide()
TimesIcon:show()
DivideIcon:hide()
end

-- Define the Divide function
function Divide()
calculate()
erase = "1"
func = "div"
value = outputWindow:value()
PlusIcon:hide()
MinusIcon:hide()
TimesIcon:hide()
DivideIcon:show()
end

-- Define the ChangeSign function
function ChangeSign()
a, b = string.find(outputWindow:value(), "-")
if a~=nil
then
buffer = string.gsub(outputWindow:value(), "-", "")
outputWindow:value(buffer)
else
buffer = "-" .. outputWindow:value()
outputWindow:value(buffer)
end
end

-- Define the display0 function
function display0()
if erase == "1"
then
buffer = "0"
erase = "1"
elseif buffer == "0"
then
buffer = "0"
erase = "1"
else
buffer = buffer .. "0"
erase = "0"
end
CheckBuffer()
end

-- Define the display1 function
function display1()
if erase == "1"
then
buffer = "1"
elseif buffer == "0"
then
buffer = "1"
else
buffer = buffer .. "1"
end
erase = "0"
CheckBuffer()
end

-- Define the display2 function
function display2()
if erase == "1"
then
buffer = "2"
elseif buffer == "0"
then
buffer = "2"
else
buffer = buffer .. "2"
end
erase = "0"
CheckBuffer()
end

-- Define the display3 function
function display3()
if erase == "1"
then
buffer = "3"
elseif buffer == "0"
then
buffer = "3"
else
buffer = buffer .. "3"
end
erase = "0"
CheckBuffer()
end

-- Define the display4 function
function display4()
if erase == "1"
then
buffer = "4"
elseif buffer == "0"
then
buffer = "4"
else
buffer = buffer .. "4"
end
erase = "0"
CheckBuffer()
end

-- Define the display5 function
function display5()
if erase == "1"
then
buffer = "5"
elseif buffer == "0"
then
buffer = "5"
else
buffer = buffer .. "5"
end
erase = "0"
CheckBuffer()
end

-- Define the display6 function
function display6()
if erase == "1"
then
buffer = "6"
elseif buffer == "0"
then
buffer = "6"
else
buffer = buffer .. "6"
end
erase = "0"
CheckBuffer()
end

-- Define the display7 function
function display7()
if erase == "1"
then
buffer = "7"
elseif buffer == "0"
then
buffer = "7"
else
buffer = buffer .. "7"
end
erase = "0"
CheckBuffer()
end

-- Define the display8 function
function display8()
if erase == "1"
then
buffer = "8"
elseif buffer == "0"
then
buffer = "8"
else
buffer = buffer .. "8"
end
erase = "0"
CheckBuffer()
end

-- Define the display9 function
function display9()
if erase == "1"
then
buffer = "9"
elseif buffer == "0"
then
buffer = "9"
else
buffer = buffer .. "9"
end
erase = "0"
CheckBuffer()
end

-- Define the displayPoint function
function displayPoint()
if Point == "0"
then
if erase == "1"
then
buffer = "."
else
buffer = buffer .. "."
end
Point = "1"
end
erase = "0"
CheckBuffer()
end

-- Define the all clear function
function AC()
memory = "0"
MemoryIcon:hide()
clear()
end

-- Define the memory plus funcion
function Mplus()
memory = memory+outputWindow:value()
MemoryIcon:show()
end

-- Define the memory minus function
function Mminus()
fltk.fl_alert(memory .. " " .. outputWindow:value())
memory = memory-outputWindow:value()
fltk.fl_alert(memory)
MemoryIcon:show()
end

-- Define the memory recall function
function MR()
outputWindow:value(memory)
end

-- Set the main window width.
ww = 240

-- Set the main window height.
wh = 410

-- Define the main window.
window = fltk:Fl_Window(ww, wh, "Simple Calculator") 

-- Show the output window.
outputWindow = fltk:Fl_Output(5, 5, ww-25, 40)
outputWindow:textsize(22)
outputWindow:value(total)

-- Define the information icons.
ErrorIcon = fltk:Fl_Button(225, 5, 10, 10)
ErrorIcon:box(fltk.FL_NO_BOX)
ErrorIcon:labelsize(10)
ErrorIcon:label("E")
ErrorIcon:hide()
ErrorIcon:callback(error)

PlusIcon = fltk:Fl_Box(225, 20, 10, 10)
PlusIcon:box(fltk.FL_NO_BOX)
PlusIcon:labelsize(10)
PlusIcon:label("+")
PlusIcon:hide()

MinusIcon = fltk:Fl_Box(225, 20, 10, 10)
MinusIcon:box(fltk.FL_NO_BOX)
MinusIcon:labelsize(15)
MinusIcon:label("-")
MinusIcon:hide()

TimesIcon = fltk:Fl_Box(225, 20, 10, 10)
TimesIcon:box(fltk.FL_NO_BOX)
TimesIcon:labelsize(10)
TimesIcon:label("X")
TimesIcon:hide()

DivideIcon = fltk:Fl_Box(225, 20, 10, 10)
DivideIcon:box(fltk.FL_NO_BOX)
DivideIcon:labelsize(15)
DivideIcon:label("/")
DivideIcon:hide()

MemoryIcon = fltk:Fl_Box(225, 35, 10, 10)
MemoryIcon:box(fltk.FL_NO_BOX)
MemoryIcon:labelsize(10)
MemoryIcon:label("M")
MemoryIcon:hide()

-- Make a button.
ButtonAC = fltk:Fl_Button(5, 55, 50, 50, "AC"); 
ButtonAC:labelsize(15) 
ButtonAC:color(1) 
ButtonAC:align(fltk.FL_ALIGN_WRAP); 
ButtonAC:callback(AC)

-- Make a button.
ButtonMplus = fltk:Fl_Button(65, 55, 50, 50, "M+"); 
ButtonMplus:labelsize(15)  
ButtonMplus:color(219)
ButtonMplus:align(fltk.FL_ALIGN_WRAP); 
ButtonMplus:callback(Mplus)

-- Make a button.
ButtonMminus = fltk:Fl_Button(125, 55, 50, 50, "M-"); 
ButtonMminus:labelsize(15) 
ButtonMminus:color(219)
ButtonMminus:align(fltk.FL_ALIGN_WRAP); 
ButtonMminus:callback(Mminus)

-- Make a button.
ButtonMR = fltk:Fl_Button(185, 55, 50, 50, "MRC"); 
ButtonMR:labelsize(15)
ButtonMR:color(219)
ButtonMR:align(fltk.FL_ALIGN_WRAP); 
ButtonMR:callback(MR)

-- Make a button.
ButtonC = fltk:Fl_Button(5, 115, 50, 50, "C"); 
ButtonC:labelsize(15)
ButtonC:color(1)
ButtonC:align(fltk.FL_ALIGN_WRAP); 
ButtonC:shortcut(fltk.FL_Delete)
ButtonC:callback(clear)
ButtonC:take_focus()

-- Make a button.
ButtonSign = fltk:Fl_Button(65, 115, 50, 50, "+/-" ); 
ButtonSign:labelsize(20)
ButtonSign:color(4)
ButtonSign:align(fltk.FL_ALIGN_WRAP); 
ButtonSign:callback(ChangeSign)

-- Make a button.
ButtonDivide = fltk:Fl_Button(125, 115, 50, 50, "/"); 
ButtonDivide:labelsize(30)
ButtonDivide:color(4)
ButtonDivide:align(fltk.FL_ALIGN_WRAP);
ButtonDivide:shortcut("/")
ButtonDivide:callback(Divide)

-- Make a button.
ButtonMultiply = fltk:Fl_Button(185, 115, 50, 50, "X"); 
ButtonMultiply:labelsize(30)
ButtonMultiply:color(4)
ButtonMultiply:align(fltk.FL_ALIGN_WRAP);
ButtonMultiply:shortcut("*")
ButtonMultiply:callback(Multiply)

Button7 = fltk:Fl_Button(5, 175, 50, 50, "7"); 
Button7:labelsize(30)
Button7:color(39)  
Button7:align(fltk.FL_ALIGN_WRAP);
Button7:shortcut("7")
Button7:callback(display7)

-- Make a button.
Button8 = fltk:Fl_Button(65, 175, 50, 50, "8"); 
Button8:labelsize(30)
Button8:color(39)
Button8:align(fltk.FL_ALIGN_WRAP);
Button8:shortcut("8")
Button8:callback(display8)

-- Make a button.
Button9 = fltk:Fl_Button(125, 175, 50, 50, "9"); 
Button9:labelsize(30)
Button9:color(39)
Button9:align(fltk.FL_ALIGN_WRAP);
Button9:shortcut("9")
Button9:callback(display9)

-- Make a button.
ButtonMinus = fltk:Fl_Button(185, 175, 50, 50, "-"); 
ButtonMinus:labelsize(30)
ButtonMinus:color(4)
ButtonMinus:align(fltk.FL_ALIGN_WRAP);
ButtonMinus:shortcut("-")
ButtonMinus:callback(Minus)

-- Make a button.
Button4 = fltk:Fl_Button(5, 235, 50, 50, "4"); 
Button4:labelsize(30)
Button4:color(39)
Button4:align(fltk.FL_ALIGN_WRAP);
Button4:shortcut("4")
Button4:callback(display4)

-- Make a button.
Button5 = fltk:Fl_Button(65, 235, 50, 50, "5"); 
Button5:labelsize(30)
Button5:color(39)
Button5:align(fltk.FL_ALIGN_WRAP);
Button5:shortcut("5") 
Button5:callback(display5)

-- Make a button.
Button6 = fltk:Fl_Button(125, 235, 50, 50, "6"); 
Button6:labelsize(30)
Button6:color(39)  
Button6:align(fltk.FL_ALIGN_WRAP);
Button6:shortcut("6")
Button6:callback(display6)

-- Make a button.
ButtonPlus = fltk:Fl_Button(185, 235, 50, 50, "+"); 
ButtonPlus:labelsize(30)
ButtonPlus:color(4)
ButtonPlus:align(fltk.FL_ALIGN_WRAP); 
ButtonPlus:shortcut(43)
ButtonPlus:callback(Plus)

-- Make a button.
Button1 = fltk:Fl_Button(5, 295, 50, 50, "1"); 
Button1:labelsize(30)
Button1:color(39)
Button1:align(fltk.FL_ALIGN_WRAP);
Button1:shortcut("1")
Button1:callback(display1)

-- Make a button.
Button2 = fltk:Fl_Button(65, 295, 50, 50, "2"); 
Button2:labelsize(30)
Button2:color(39)
Button2:align(fltk.FL_ALIGN_WRAP);
Button2:shortcut("2")
Button2:callback(display2)

-- Make a button.
Button3 = fltk:Fl_Button(125, 295, 50, 50, "3"); 
Button3:labelsize(30)
Button3:color(39)
Button3:align(fltk.FL_ALIGN_WRAP);
Button3:shortcut("3")
Button3:callback(display3)

-- Make a button.
Button0 = fltk:Fl_Button(5, 355, 110, 50, "0"); 
Button0:labelsize(30)
Button0:color(39)
Button0:align(fltk.FL_ALIGN_WRAP); 
Button0:shortcut("0")
Button0:callback(display0)

-- Make a button.
ButtonPoint = fltk:Fl_Button(125, 355, 50, 50, "."); 
ButtonPoint:labelsize(30)
ButtonPoint:color(39)
ButtonPoint:align(fltk.FL_ALIGN_WRAP); 
ButtonPoint:shortcut(".")
ButtonPoint:callback(displayPoint)

-- Make a button.
ButtonEqual = fltk:Fl_Button(185, 295, 50, 110, "="); 
ButtonEqual:labelsize(30)   
ButtonEqual:align(fltk.FL_ALIGN_WRAP)
ButtonEqual:color(4)  
ButtonEqual:shortcut(fltk.FL_KP_Enter)
ButtonEqual:callback(calculate)

Fl:scheme("plastic")
window:show()
Fl:run()