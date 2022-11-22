-- Declaration of global variables
make_window = make_window or nil
MathWindow = MathWindow or nil
HiddenGroup = HiddenGroup or nil
output6 = output6 or nil
NextButton = NextButton or nil
Save = Save or nil
output4 = output4 or nil
output5 = output5 or nil
NumPositionGroup = NumPositionGroup or nil
onesplaceT = onesplaceT or nil
tensplaceT = tensplaceT or nil
hundredsplaceT = hundredsplaceT or nil
onesplaceB = onesplaceB or nil
tensplaceB = tensplaceB or nil
hundredsplaceB = hundredsplaceB or nil
hundredsplaceD = hundredsplaceD or nil
tensplaceD = tensplaceD or nil
onesplaceD = onesplaceD or nil
MathTab = MathTab or nil
MathGroup = MathGroup or nil
divisiongroup = divisiongroup or nil
output1b = output1b or nil
output2b = output2b or nil
equalsbar1 = equalsbar1 or nil
fractionbar = fractionbar or nil
output2c = output2c or nil
output1c = output1c or nil
divisionlabel = divisionlabel or nil
answeroutput = answeroutput or nil
output1 = output1 or nil
output2 = output2 or nil
output3 = output3 or nil
solutionbar = solutionbar or nil
AnswerCheck = AnswerCheck or nil
StatusGroup = StatusGroup or nil
daybar = daybar or nil
yearbar = yearbar or nil
correctbar = correctbar or nil
optionsgroup = optionsgroup or nil
mincountertop = mincountertop or nil
maxcounterbottom = maxcounterbottom or nil
mincounterbottom = mincounterbottom or nil
maxcountertop = maxcountertop or nil

function make_window()
  rndMinTop=1
  rndMinBottom=1
  
rndMaxTop=11
  rndMaxBottom=11
  
rndProcessOption=4
  
o1=math.random(rndMinTop,rndMaxTop)
  o2=math.random(rndMinBottom,rndMaxBottom)
  o3=math.random(1,rndProcessOption)
  o4=0
  
answervalue=0
  
score={{}}
  score["answer"]= {}
  score["correct"]=""
  score["tries"]=""
  
score["multiplication"]={}
  score["division"]={}
  score["subtraction"]={}
  score["addition"]={}
  

mathRecords={}
  

local Q = '"';
  local ba="{";
  local bb="}";
  local C=",";
  

score["correct"]=0
  score["tries"]=0
  score["addition"]={"1,1,1,2"}
  score["subtraction"]={"1,1,2,0"}
  score["multiplication"]={"1,1,3,1"}
  score["division"]={"1,1,4,1"}
  currentUnit={}
  listCount = 0; --#mathList
  totalwords = 0
  keystrokeCount = 0
  totalLetters =0
  wordscompleted=0
  spellingTimerStart = os.time()
  TotalElapsedTime = 0
  UnitElapsedTime = 0
  wordsPerMinute = 0
  minuteCount = 0
  elapsedWordtime = 0
  wpmcount = 0
  unitDepth = 1
  listDepth = 1
  wordsPerMinute=0
  -- "len": the # operation.
  function len_event (op)
         if type(op) == "string" then
           return strlen(op)         -- primitive string length
         elseif type(op) == "table" then
           return #op                -- primitive table length
         else
           local h = metatable(op).__len
           if h then
             -- call the handler with the operand
             return (h(op))
           else  -- no handler available: default behavior
             error()
           end
         end
       end
  function getLocations(o1,o2,o3)
  

--TOP
  --hundredsplacebox
  hptx,hpty = hundredsplaceT:x(),hundredsplaceT:y()
  hptw,hpth = hundredsplaceT:w(),hundredsplaceT:h()
  --tensplacebox
  tptx,tpty = tensplaceT:x(),tensplaceT:y()
  tptw,tpth = tensplaceT:w(),tensplaceT:h()
  --onesplacebox
  optx,opty = onesplaceT:x(),onesplaceT:y()
  optw,opth = onesplaceT:w(),onesplaceT:h()
  if o1 < 10 then 
  output1:resize(optx,opty,hptw,hpth)
  end
  if o1 >= 10 and o1 < 100 then
  output1:resize(tptx,tpty ,tptw,tpth)
  end
  if o1 >= 100 and o1 < 1000 then
  output1:resize(hptx,hpty,hptw,hpth)
  end
  


--BOTTOM
  --hundredsplacebox
  hpbx,hpby = hundredsplaceB:x(),hundredsplaceB:y()
  hpbw,hpbh = hundredsplaceB:w(),hundredsplaceB:h()
  --tensplacebox
  tpbx,tpby = tensplaceB:x(),tensplaceB:y()
  tpbw,tpbh = tensplaceB:w(),tensplaceB:h()
  --onesplacebox
  opbx,opby = onesplaceB:x(),onesplaceB:y()
  opbw,opbh = onesplaceB:w(),onesplaceB:h()
  o3w,o3h = output3:w(),output3:h()
  --DIVISION
  --hundredsplacebox
  hpdx,hpdy = hundredsplaceD:x(),hundredsplaceD:y()
  hpdw,hpdh = hundredsplaceD:w(),hundredsplaceD:h()
  --tensplacebox
  tpdx,tpdy = tensplaceD:x(),tensplaceD:y()
  tpdw,tpdh = tensplaceD:w(),tensplaceD:h()
  --onesplacebox
  opdx,opdy = onesplaceD:x(),onesplaceD:y()
  opdw,opdh = onesplaceD:w(),onesplaceD:h()
  
if o2 < 10 then 
  output2:resize(opbx,opby,hpbw,hpbh)
  output3:resize((opbx-o3w),opby,o3w,o3h)
  output2b:resize(opdx,opdy,hpbw,hpdh)
  end
  if o2 >= 10 and o2 < 100 then
  output2:resize(tpbx,tpby ,tpbw,tpbh)
  output3:resize((tpbx-o3w),opby,o3w,o3h)
  output2b:resize(tpdx,tpdy ,tpdw,tpdh)
  end
  if o2 >= 100 and o2 < 1000 then
  output2:resize(hpbx,hpby,hpbw,hpbh)
  output3:resize((hpbx-o3w),opby,o3w,o3h)
  output2b:resize(hpdx,hpdy,hpbw,hpdh)
  end
  




end
  function listScoreForOutput(TableName)
  	local Q = '"';
  	local ba="{";
  	local bb="}";
  	local C=",";
  
local listout = ""
  local scoreword={}
  local wordlist=""
  		for i = 1,#score[TableName],1 do
  		scoreword=score[TableName][i]	
  		
  			qfind = string.find(scoreword,Q)
  			if qfind == nil then
  			scoreword=Q..scoreword..Q
  			end
  		
  		
  		listout = listout..scoreword..C
  		end
  		
  		 scoreout="\n".."score["..Q..TableName..Q.."]="..ba..string.sub(listout,1,-2)..bb;
  	
	return scoreout	
  end
  function updateMaxMin()
  rndMinTop=mincountertop:value()
  rndMinBottom=mincounterbottom:value()
  rndMaxTop=maxcountertop:value()
  rndMaxBottom=maxcounterbottom:value()
  return rndMinTop,rndMinBottom,rndMaxTop,rndMaxBottom
  end
  function updateProcessOptions()
  
end
  function updateProgressValues()
  currentcorrect = score["correct"] 
  currenttries = score["tries"]
  
daybar:value(dailypercent)
  daybar:label(dailypercent.." today")
  
dailypercentupvalue=( currentcorrect / currenttries )*100
  correctbar:value(dailypercentupvalue)
  correctbar:label("Proficiency: "..dailypercentupvalue)
  
monthlypercent=(currentcorrect)/200
  yearlypercent=(currentcorrect)/1720
  currentpercent=((currentcorrect)/10)*100
  
--output4:value(currentcorrect)
  --output5:value(currenttries)
  

yearbar:value((1720-currentcorrect))
  yearbar:label(currentcorrect.." of 1720")
  
sc=score["correct"]
  st=score["tries"]
  MathWindow:label(sc.." correct of "..st.." tries".." | Proficiency:"..dailypercentupvalue.." | 1720")
  
end
  function openMathRecords()
  listFile="mathRecord.lua"
  	local sl=io.open(listFile,"r*")
  	if sl~=nil then
  	dofile(listFile)
  	sl:close()
  	end
  	return score["correct"]	
  end
  function openCurrentMathProgress()
  wordlistdepthfile = "CurrentMathProgress.txt"
  myFile = io.open(wordlistdepthfile,"r")
  if myFile ~= nil then
   dofile(wordlistdepthfile)
   myFile:close()
  end
  end
  function WriteMathListsToFile()
  mathListsFile = "mathRecord.lua"
  	local f = io.open(mathListsFile,"w")
  	local Q = '"';
  	local ba="{";
  	local bb="}";
  	local C=",";
  
	if f ~= nil then 
  	
		
  	
		
  		
  		correct=score["correct"]
  		tries=score["tries"]
  		
  

	listwrite="\n"
  		listwrite = listwrite.."\n"..listScoreForOutput("addition")
  		listwrite = listwrite.."\n"..listScoreForOutput("subtraction")
  		listwrite = listwrite.."\n"..listScoreForOutput("multiplication")
  		listwrite = listwrite.."\n"..listScoreForOutput("division")
  		
  		
  			
  		
  		listwrite = listwrite.."\n".."score["..Q.."correct"..Q.."]="..correct..";\n";
  		listwrite = listwrite.."\n".."score["..Q.."tries"..Q.."]="..tries..";\n";
  		
  		f:write(listwrite)
  		f:write(string.char (10))
  		io.close(f)
  	end
  	
	
  	
	
  	
end
  function progressdaily()
  progbar:minimum(0)
  progbar:maximum(100) 
  end
  function randomize()
  o1=math.random(rndMinTop,rndMaxTop)
  o2=math.random(rndMinBottom,rndMaxBottom)
  

o3=math.random(1,rndProcessOption)
  

o4=0
  return o1,o2,o3
  end
  function answerproblem(o1,o2,o3,answervalue)
  

mathsigns={"+","-","/","*","^"}
  
-- addition
  if o3 == 1 then answervalue = o1 + o2 end
  
-- multiplication
  if o3 == 4 then answervalue = o1 * o2 end
  
-- handle subtraction without negative values
  if o3 == 2 then 
  	if o1 < o2 then 
  		hold1 = o1
  		ol = o2
  		o2 = hold1
  	end
  	answervalue = o1 - o2 
  end
  
-- handle fractions as divisions
  	if o3 == 3 then  
  	subtotal = o1 * o2 
  	answervalue = o1
  	o1=subtotal
  	fractionbar:show()
  	divisiongroup:show()
  	output3:label("Divide")
  	output2b:value(o2)
  	output1b:value(o1)
  	output2c:value(o2)
  	output1c:value(o1)
  	else
  	divisiongroup:hide()
  	output3:label(" ")
  	fractionbar:hide()
  	end
  	
output1:value(o1)
  output2:value(o2)
  output3:value(mathsigns[o3])
  


getLocations(o1,o2,o3)
  
answeroutput:value(answervalue)
  alloutputs = o1..","..o2..","..o3..","..answervalue
  
return o1,o2,o3,answervalue
  end
  function checkanswer(w)
  local tried=score["tries"]
  
if AnswerCheck:value() ~= nil then 
  alloutputs = Q..o1..output3:value()..o2.."="..answeroutput:value()..Q
  tried=tried+1
  score["tries"]=tried
  
end
  
alloutputs = Q..o1..","..o2..","..o3..","..answeroutput:value()..Q
  
--if the entered value equalds correct answer
  if w:value() == answeroutput:value() then
  dailypercent=dailypercent +1
  score["correct"]=score["correct"]+1	
  

	if o3 == 1 then 
  	alloutputs = Q..o1..","..o2..","..answeroutput:value()..Q
  	table.insert(score["addition"], alloutputs)
  	end
  
	if o3 == 2 then 
  	alloutputs = Q..o1..","..o2..","..answeroutput:value()..Q
  	table.insert(score["subtraction"], alloutputs)
  	end
  
	if o3 == 3 then 
  	alloutputs = Q..o1..","..o2..","..answeroutput:value()..Q
  	table.insert(score["multiplication"], alloutputs)
  	end
  
	if o3 == 4 then 
  	alloutputs = Q..o1..","..o2..","..answeroutput:value()..Q
  	table.insert(score["division"], alloutputs)
  	end
  


rndMinTop,rndMinBottom,rndMaxTop,rndMaxBottom=updateMaxMin()
  o1,o2,o3,answervalue = answerproblem(randomize(rndMinTop,rndMaxBottom,4))
  w:value("")
  save()
  end
  
updateProgressValues()
  

MathWindow:redraw()
  MathWindow:make_current()
  end
  function cycleproblems()
  

o1,o2,o3,answervalue = answerproblem(randomize(rndMaxTop,rndMaxBottom,rndProcessOption))
  

MathWindow:redraw()
  MathWindow:make_current()
  end
  function save()
  WriteMathListsToFile()
  end
  if MathWindow ~= nil then MathWindow:hide() end
  local o = fltk:Fl_Double_Window(-32000, -32000, 965, 721)
  MathWindow = o
  o:color(0)
  do
    local o = fltk:Fl_Group(15, 5, 1410, 630)
    HiddenGroup = o
    do
      local o = fltk:Fl_Output(1105, 14, 150, 17, "=")
      output6 = o
      o:labelcolor(7)
      o:color(31)
      o:textcolor(7)
      o:align(36)
      o:labelsize(12)
      local o = fltk:Fl_Button(1270, 15, 60, 15, "NEXT")
      NextButton = o
      o:labelsize(12)
      o:callback(cycleproblems)
      local o = fltk:Fl_Button(1335, 15, 60, 15, "Save")
      Save = o
      o:callback(save)
      local o = fltk:Fl_Output(15, 616, 25, 19, "Correct of:")
      output4 = o
      o:labelcolor(62)
      o:align(40)
      o:box(fltk.FL_NO_BOX)
      o:labelsize(10)
      o:textcolor(62)
      o:color(31)
      o:textsize(10)
      local o = fltk:Fl_Output(90, 616, 25, 19, "Tries")
      output5 = o
      o:labelcolor(62)
      o:align(40)
      o:box(fltk.FL_NO_BOX)
      o:labelsize(10)
      o:textcolor(62)
      o:color(31)
      o:textsize(10)
    end
    o['endd'](o)
    local o = fltk:Fl_Group(173, 108, 459, 424, "NumPositionGroup")
    NumPositionGroup = o
    do
      local o = fltk:Fl_Box(525, 116, 72, 89, "onesplace")
      onesplaceT = o
      o:color(6)
      o:box(fltk.FL_UP_FRAME)
      local o = fltk:Fl_Box(465, 116, 132, 89, "tensplace")
      tensplaceT = o
      o:color(6)
      o:box(fltk.FL_UP_FRAME)
      local o = fltk:Fl_Box(407, 116, 190, 89, "hundredsplaceT")
      hundredsplaceT = o
      o:color(6)
      o:box(fltk.FL_THIN_UP_FRAME)
      local o = fltk:Fl_Box(525, 211, 72, 89, "onesplace")
      onesplaceB = o
      o:color(6)
      o:box(fltk.FL_UP_FRAME)
      local o = fltk:Fl_Box(465, 211, 132, 89, "tensplace")
      tensplaceB = o
      o:color(6)
      o:box(fltk.FL_UP_FRAME)
      local o = fltk:Fl_Box(407, 211, 190, 89, "hundredsplaceT")
      hundredsplaceB = o
      o:color(6)
      o:box(fltk.FL_THIN_UP_FRAME)
      local o = fltk:Fl_Box(193, 432, 160, 81, "hundredsplaceT")
      hundredsplaceD = o
      o:color(6)
      o:box(fltk.FL_THIN_UP_FRAME)
      local o = fltk:Fl_Box(243, 432, 110, 81, "tensplace")
      tensplaceD = o
      o:color(6)
      o:box(fltk.FL_UP_FRAME)
      local o = fltk:Fl_Box(293, 432, 60, 81, "onesplace")
      onesplaceD = o
      o:color(6)
      o:box(fltk.FL_UP_FRAME)
    end
    o['endd'](o)
    local o = fltk:Fl_Tabs(0, 4, 1515, 851)
    MathTab = o
    o:color(0)
    o:selection_color(34)
    o:box(fltk.FL_GTK_UP_BOX)
    do
      local o = fltk:Fl_Group(1, 33, 1481, 822, "Math")
      MathGroup = o
      o:when(0)
      o:labelcolor(59)
      o:color(33)
      o:labelsize(11)
      o:box(fltk.FL_GTK_UP_BOX)
      do
        local o = fltk:Fl_Group(186, 164, 554, 666)
        divisiongroup = o
        o:labelcolor(1)
        do
          local o = fltk:Fl_Output(398, 433, 208, 82)
          output1b = o
          o:labelcolor(80)
          o:labelsize(100)
          o:textfont(1)
          o:textcolor(60)
          o:textsize(90)
          o:box(fltk.FL_NO_BOX)
          local o = fltk:Fl_Output(211, 433, 160, 73, "=")
          output2b = o
          o:textcolor(60)
          o:labelcolor(59)
          o:textfont(1)
          o:textsize(90)
          o:labelsize(40)
          o:box(fltk.FL_NO_BOX)
          local o = fltk:Fl_Button(365, 426, 274, 5, "button")
          equalsbar1 = o
          o:color(1)
          o:selection_color(0)
          o:box(fltk.FL_FLAT_BOX)
          local o = fltk:Fl_Button(408, 201, 216, 5)
          fractionbar = o
          o:align(4)
          o:color(1)
          o:selection_color(0)
          o:box(fltk.FL_FLAT_BOX)
          local o = fltk:Fl_Output(186, 802, 40, 28)
          output2c = o
          o:labelcolor(59)
          o:labelsize(16)
          o:textfont(1)
          o:textcolor(181)
          o:textsize(16)
          o:box(fltk.FL_NO_BOX)
          local o = fltk:Fl_Output(186, 777, 40, 30)
          output1c = o
          o:labelcolor(59)
          o:labelsize(16)
          o:textfont(1)
          o:textcolor(181)
          o:textsize(16)
          o:box(fltk.FL_NO_BOX)
          local o = fltk:Fl_Output(398, 423, 8, 82, ")")
          divisionlabel = o
          o:textcolor(60)
          o:labelcolor(80)
          o:textfont(1)
          o:textsize(90)
          o:labelsize(100)
          o:box(fltk.FL_NO_BOX)
        end
        o['endd'](o)
        local o = fltk:Fl_Output(1, 324, 561, 24, "Answer:")
        answeroutput = o
        local o = fltk:Fl_Output(421, 112, 191, 88, "output1:")
        output1 = o
        o:labelcolor(59)
        o:align(5)
        o:box(fltk.FL_NO_BOX)
        o:labelfont(1)
        o:textcolor(60)
        o:labelsize(10)
        o:textfont(1)
        o:textsize(100)
        local o = fltk:Fl_Output(421, 207, 190, 88, "output2:")
        output2 = o
        o:labelcolor(59)
        o:align(5)
        o:box(fltk.FL_NO_BOX)
        o:labelfont(1)
        o:textcolor(60)
        o:labelsize(10)
        o:textfont(1)
        o:textsize(100)
        local o = fltk:Fl_Output(340, 208, 81, 92, "output3:")
        output3 = o
        o:labelcolor(59)
        o:textcolor(61)
        o:textsize(120)
        o:labelsize(10)
        o:box(fltk.FL_NO_BOX)
        local o = fltk:Fl_Button(361, 298, 255, 7, "button")
        solutionbar = o
        o:labelcolor(4)
        o:color(218)
        o:box(fltk.FL_FLAT_BOX)
        o:labelsize(3)
        o:selection_color(0)
        local o = fltk:Fl_Input(400, 308, 215, 113, "=")
        AnswerCheck = o
        o:labelcolor(59)
        o:color(35)
        o:box(fltk.FL_FLAT_BOX)
        o:labelsize(40)
        o:when(8)
        o:textcolor(61)
        o:textfont(1)
        o:textsize(100)
        o:callback(checkanswer)
        local o = fltk:Fl_Group(10, 604, 942, 113, "Status")
        StatusGroup = o
        o:labelsize(11)
        do
          local o = fltk:Fl_Progress(10, 667, 942, 16, "Daily: 10 Correct")
          daybar = o
          o:align(20)
          o:labelcolor(2)
          o:color(32)
          o:labelsize(10)
          o:selection_color(34)
          o:box(fltk.FL_FLAT_BOX)
          local o = fltk:Fl_Progress(10, 684, 942, 16, "Year:  1720 Correct")
          yearbar = o
          o:align(20)
          o:labelcolor(2)
          o:color(32)
          o:labelsize(10)
          o:selection_color(34)
          o:box(fltk.FL_FLAT_BOX)
          local o = fltk:Fl_Progress(10, 701, 942, 16, "Proficiency")
          correctbar = o
          o:align(20)
          o:labelcolor(2)
          o:color(57)
          o:labelsize(10)
          o:selection_color(34)
          o:box(fltk.FL_FLAT_BOX)
        end
        o['endd'](o)
      end
      o['endd'](o)
      local o = fltk:Fl_Group(21, 30, 1440, 805, "Options")
      optionsgroup = o
      o:color(32)
      o:labelsize(10)
      o:box(fltk.FL_GTK_UP_BOX)
      do
        local o = fltk:Fl_Value_Input(486, 246, 95, 24, "Top number minimum:")
        mincountertop = o
        o:minimum(1)
        o:labelcolor(221)
        o:maximum(99)
        o:labelfont(1)
        o:value(1)
        o:step(1)
        o:labelsize(12)
        o:callback(updateMaxMin)
        local o = fltk:Fl_Value_Input(486, 333, 95, 24, "Bottom number maximum:")
        maxcounterbottom = o
        o:minimum(1)
        o:labelcolor(221)
        o:maximum(100)
        o:labelfont(1)
        o:value(10)
        o:step(1)
        o:labelsize(12)
        o:callback(updateMaxMin)
        local o = fltk:Fl_Value_Input(486, 376, 95, 24, "Bottom number minimum:")
        mincounterbottom = o
        o:minimum(1)
        o:labelcolor(221)
        o:maximum(99)
        o:labelfont(1)
        o:value(1)
        o:step(1)
        o:labelsize(12)
        o:callback(updateMaxMin)
        local o = fltk:Fl_Value_Input(486, 286, 95, 24, "Top number maximum:")
        maxcountertop = o
        o:minimum(1)
        o:labelcolor(221)
        o:maximum(100)
        o:labelfont(1)
        o:value(10)
        o:step(1)
        o:labelsize(12)
        o:callback(updateMaxMin)
      end
      o['endd'](o)
    end
    o['endd'](o)
  end
  o['endd'](o)
  MathWindow:label("MATH MACHINE")
  MathWindow:show()
  
dailypercent=0
  
answeroutput:hide()
  maxcounterbottom:value(rndMaxBottom)
  maxcountertop:value(rndMaxTop)
  
daybar:minimum(0)
  daybar:maximum(20) 
  daybar:value(0)
  yearbar:minimum(0)
  yearbar:maximum(1720) 
  correctbar:minimum(0)
  correctbar:maximum(101) 
  
output1:label(" ")
  output2:label(" ")
  output3:label(" ")
  output4:label(" ")
  output5:label(" ")
  output6:label(" ")
  
-- open mathRecord.lua get score["correct"] & score["tries"] data
  score["correct"]= 
  

openMathRecords()
  --score["correct"]=(#score["addition"])+(#score["subtraction"])+(#score["multiplication"])+(#score["division"])
  --score["tries"]=#score["correct"]
  cycleproblems() 
  

output5:value(score["tries"])
  output4:value(score["correct"])
  
Fl:scheme("plastic")
  MathWindow:redraw()
  MathWindow:make_current()
  return MathWindow
end

for _,i in ipairs {make_window()} do i:show() end
Fl:run()
