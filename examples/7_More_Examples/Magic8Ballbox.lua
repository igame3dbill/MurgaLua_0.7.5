EightBallAnswers={"Outlook Good", "Outlook Not So Good ", "My Reply Is No", "Don't Count On It", "You May Rely On It", "Ask Again Later", "Most Likely ", "Cannot Predict Now", "Yes ", "Yes, definitely", "Better Not Tell You Now ", "It Is Certain", "Very Doubtful", "It Is Decidedly So", "Concentrate And Ask Again", "Signs Point To Yes ", "My Sources Say No ", "Without A Doubt ", "Reply Hazy, Try Again", "As I See It, Yes"}
math.randomseed(os.time())
function shakebox()
local shakeammount=math.random(8,16)
local answer=math.random(1,#EightBallAnswers)
local wx=EightBox:x()
local wy=EightBox:y()
local ww=EightBox:h()
local wh=EightBox:w()

for i = 1,shakeammount,1 do
EightBox:resize(wx-8,wy,wh,ww)
Fl:wait(0)
EightBox:resize(wx,wy-8,wh,ww)
Fl:wait(0)
EightBox:resize(wx+8,wy,wh,ww)
Fl:wait(0)
EightBox:resize(wx,wy+8,wh,ww)
end
Fl:wait(0)
EightBox:resize(wx,wy,wh,ww)
EightBox:redraw()
AnswerOutput:value(EightBallAnswers[answer])
end
do EightBox= fltk:Fl_Double_Window(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "MAGIC 8 BOX")
EightBox:label(gLabelTable[#gLabelTable])
EightBox:resize(509,283,362,119)

do background= fltk:Fl_Box(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "label")
background:label(gLabelTable[#gLabelTable])
background:resize(0,-1,365,237)
background:box(fltk.FL_FLAT_BOX)
background:color(0)
end

do ShakeButton= fltk:Fl_Button(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "Shake")
ShakeButton:label(gLabelTable[#gLabelTable])
ShakeButton:callback(shakebox)
ShakeButton:resize(0,75,365,45)
ShakeButton:box(fltk.FL_NO_BOX)
ShakeButton:labelfont(1)
ShakeButton:labelsize(21)
ShakeButton:labelcolor(1)
end

do AnswerOutput= fltk:Fl_Output(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, " ")
AnswerOutput:label(gLabelTable[#gLabelTable])
AnswerOutput:resize(20,16,325,39)
AnswerOutput:box(fltk.FL_NO_BOX)
AnswerOutput:textcolor(2)
end
end
EightBox:show()
Fl:run()