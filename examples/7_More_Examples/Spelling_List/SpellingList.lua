--function make_window()
spellingLists={{"global","solar","buffalo","soldier","blindfold","trombone","decompose","diagnose","episode","telescrope","bicycle","biannual","biweekly","bimonthly","rupture","interrupt","disrupt","erupt","league","","Oklahoma","New Mexico"},
{"redeem","underneath","monkey","gravity","brief","magnify","exercise","motivate","remote","erode","injustice","encircle","misconduct","disobey","interrupting","valuables","respect","subscribe"},
{"pupil","community","uniform","union","university","argue","refugge","cue","commute","execute","semifinal","semipro","semicircle","semiskilled","dictate","dictator","dictionary","predict","restaurant","against","Virginia","Georgia"},
{"baboon","mushroom","droop","raccoon","youth","group","fluent","inconclusive","exclude","rude","midday","midnight","midsummer","midway","tractor","traction","subtract","distract","luxury","deluxe","Illinois","Wyoming"},
{"concern","observe","internal","early","learn","disturb","absurd","survive","firm","thirsty","forecase","forewarn","foresee","forefather","ferry","conference","prefer","transfer","business","figure","Vermont","Alsaska"},
{"skeleton","package","octopus","arctic","campus","ache","mechanic","chorus","character","stomach","underpass","undersea","underground","undertake","vision","visible","invisible","vista","journal","courtesy","Montana","Colorado"},
{"squirrel","requested","conquest","quietly","quarterly","quotation","special","offical","social","artificial","deface","declaw","dethrone","defrost","current","cursive","currency","concur","honor","donor","Arizona","Deleware"},
{"cubicle","fumigate","frugal","swoop","mockingbird","curb","choral","quail","squirm","crucial","foretell","underline","deform","midstream","cursor","visual","transferable","dictating"},
{"trivia","piano","memorial","librarian","champion","curiosity","patriot","radio","machine","period","respectable","predictable","acceptable","honorable","adventure","venture","avenue","convention","February","animals","Louisiana","Hawaii"},
{"science","scene","conceited","ancestor","citizen","rejouice","twice","fragrance","recent","harshly","loudly","decently","silently","script","description","prescription","manuscript","toward","permanent","Indiana","Missouri"},
{"balanced","motivated","sharing","probing","likely","immediately","tasteful","announcement","sincerely","starvation","occupation","humilition","location","capture","captivate","captor","captive","language","caught","West Virginia","North Carolina"},
{"heavier","heaviest","laziest","cozier","tiniest","worrying","supplying","displaying","betrayed","surveyed","relaying","dentist","journalist","scientist","violinist","credible","incredible","credit","discredit","prairie","daily","California","Minnesota"},
{"journeys","highways","holidays","turkeys","valleys","diaries","hobbies","libraries","counties","territories","senator","governor","director","counselor","sense","sensitive","sensational","nonsense","really","everybody","Massachusetts","Washington"},
{"aviator","trio","certain","turbulence","expensive","accurately","contributing","countries","daisies","surveys","relation","slowly","educator","typist","sensitively","credit","captured","prescriptions"},
{"photograph","dolphin","hyphen","philosophy","trophy","guilty","guard","guitar","guess","guide","forgiveness","closeness","goodness","illness","audio","audible","audience","audition","opposite","favorite","South Dakota","Idaho"},
{"ointment","coil","coinage","poison","exploit","disappoint","emply","annoy","royal","voyage","hazardous","glamorous","joyous","dangerous","form","formal","formula","conform","expect","beauty","Maryland","Oregon"},
{"bound","surround","scoundrel","ounce","blouse","drowsy","drown","rowdy","clownish","allow","victorious","glorious","furious","various","pending","pendant","pendulum","appendage","during","occur","Florida","Nebraska"},
{"novice","apprentice","service","notice","justice","practice","furnace","palace","terrace","menace","famous","ridiculous","nervous","disirous","tent","tension","antenna","extend","grief","glacier","North Dakota","Utah"},
{"doesn't","won't","there's","who's","shouldn't","couldn't","wouldn't","let's","they're","you're","leadereship","friendship","horsemanship","relationship","elect","election","select","selection","rehearsal","several","Iowa","Michigan"},
{"autograph","quessing","annoyed","poisonous","ounces","surface","can't","here's","membership","weakness","adventurous","continous","formality","auditions","extending","elected"},
{"windshield","masterpiece","supermarket","wristwatch","background","anywhere","campground","earthquake","handshake","overlook","musicology","biology","zoology","geology","vitamin","vital","vitality","revitalize","scissors","necessary","United States","Washington"},
{"tail","tale","mail","male","groan","grown","waist","waste","berry","bury","active","instructive","protective","destructive","century","cent","percent","centipede","experience","existence","Canada","Mexico"},
{"close","clothes","deer","dear","hour","our","hear","here","heard","herd","punishment","reinforcement","treatment","enrollment","circus","circle","circular","circulation","humorous","beatiful","America","Africa"},
{"presence","presents","pause","paws","chews","choose","rose","rows","days","daze","fearful","painful","truthful","successful","divided","division","individual","indivisible","measure","pleasant","Asia","Europe"},
{"mist","missed","guest","guessed","find","toad","towed","aloud","allowed","angelic","artistic","aquatic","graphic","image","imagine","imaginary","imagination","Wednesday","Tuesday","Australia","Antartica"},
{"someone","headache","so","sew","sow","road","rowed","rode","lesson","lessen","scientific","wonderful","enjoyment","corrective","images","divided","centuries","vitamins"}}

  listFile="spellingLists.lua"
    local sl=io.open(listFile,"r*")
    if sl~=nil then
    dofile(listFile)
    sl:close()
    end
    
currentUnit={}
listCount = #spellingLists
totalwords = 0
for i = 1,listCount do 
currentUnit = spellingLists[i]
unitCount = #currentUnit
for ii = 1,unitCount do
totalwords = totalwords + 1
--print(currentUnit[ii])
end
end
print(totalwords)

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

wordlistdepthfile = "CurrentUnitCurrentWord.txt"
myFile = io.open(wordlistdepthfile,"r")
if myFile ~= nil then
dofile(wordlistdepthfile)
myFile:close()
end

function wClose()
os.exit()
end --wclose

-- WriteSpellingListsToFile
function WriteSpellingListsToFile()
spellingListsFile = "spellingLists.lua"
    local f = io.open(spellingListsFile,"w")
    local Q = '"';
    local ba="{";
    local bb="}";
    local C=",";

    if f ~= nil then 
    local listout = ""
    
        for i = 1,#spellingLists do
        local wordlist=""
        
            for ii = 1,#spellingLists[i] do
            wordlist=wordlist .. Q..spellingLists[i][ii]..Q..C 
            end
            listout = listout..ba..string.sub(wordlist,1,-2)..bb..C.."\n"
            
        end
        listwrite = "spellingLists="..ba..string.sub(listout,1,-3)..bb;
        f:write(listwrite)
        f:write(string.char (10))
        io.close(f)
    end
end
-- WordInput_callback
function WordInput_callback(w)
wordtext = tostring(w:value())
realword = WordInput:label()
spellinglistWindow:make_current()
keystrokeCount = keystrokeCount + 1

if wordtext ~= realword then
    if string.sub(wordtext,-1,-1) == "." and string.len(wordtext)>2 then
    realword = string.sub(wordtext,1,-2)
    wordtext = realworld
    spellingLists[unitDepth][listDepth] = realword
    WordInput:label("")    
    WordInput:label(realword)
    WordInput:replace(0,string.len(realword)+1,realword)
    WordInput:redraw()

    WriteSpellingListsToFile()
    
    end
end

if wordtext == realword then
wordscompleted = wordscompleted + 1
totalLetters = totalLetters + string.len(wordtext)
    listDepth = listDepth + 1
    if listDepth > #spellingLists[unitDepth] then
    listDepth = 1
    unitDepth = unitDepth + 1
    if unitDepth > #spellingLists then
unitDepth=1
end

    UnitElapsedTime = 0
    end    
WordInput:label("")    
WordInput:label(spellingLists[unitDepth][listDepth])
UnitLabel = "Unit "..tostring(unitDepth)

WordInput:replace(0,string.len(wordtext),"")
WordInput:redraw()
wpmcount = wpmcount + 1



whatText = "unitDepth="..unitDepth.."\n".."listDepth="..listDepth.."\n"
myFile = io.open("CurrentUnitCurrentWord.txt","w")
if myFile ~= nil then
myFile:write(string.char (10))
myFile:write(whatText)
myFile:write(string.char (10))
io.close(myFile)
end 

elapsedWordtime = os.time() - spellingTimerStart  
spellingTimerStart = os.time()
TotalElapsedTime = TotalElapsedTime + elapsedWordtime
UnitElapsedTime = UnitElapsedTime + elapsedWordtime

minuteCount = minuteCount + elapsedWordtime

if minuteCount > 60 then 
minuteCount = 0
wordsPerMinute = wpmcount
wpmcount = 0
end

InfoBrowser:clear()
InfoBrowser:add(UnitLabel)
InfoBrowser:add("Word "..listDepth.." of "..#spellingLists[unitDepth])
InfoBrowser:add("Words Today: "..wordscompleted)
InfoBrowser:add("Keystrokes: "..keystrokeCount.." for "..totalLetters)

TimeBrowser:clear()
TimeBrowser:add("Word time: "..elapsedWordtime)
TimeBrowser:add("Unit Time: "..UnitElapsedTime)
TimeBrowser:add("Total Time: "..TotalElapsedTime)
TimeBrowser:add("WPM: "..wpmcount.."_"..minuteCount.." = "..wordsPerMinute)
spellinglistWindow:redraw()

end
WordInput:redraw()


end
do spellinglistWindow= fltk:Fl_Double_Window(0,0,0,0,"")
spellinglistWindow:callback(wClose)
spellinglistWindow:resize(6,50,742,322)
--spellinglistWindow:show()
do fieldBackgrp= fltk:Fl_Group(0,0,0,0,"")
fieldBackgrp:resize(0,0,740,320)
fieldBackgrp:box(fltk.FL_DOWN_BOX)
Fl_Group:current(Fl_Group:current():parent())
end

do InfoBrowser= fltk:Fl_Browser(0,0,0,0,"")
InfoBrowser:resize(0,0,352,55)
InfoBrowser:box(fltk.FL_FLAT_BOX)
InfoBrowser:color(47)
InfoBrowser:labelsize(10)
InfoBrowser:textsize(10)
end

do TimeBrowser= fltk:Fl_Browser(0,0,0,0,"")
TimeBrowser:resize(350,0,389,55)
TimeBrowser:box(fltk.FL_FLAT_BOX)
TimeBrowser:color(47)
TimeBrowser:labelsize(10)
TimeBrowser:textsize(10)
end

do WordInput= fltk:Fl_Input(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "1234567890123")
WordInput:label(gLabelTable[#gLabelTable])
WordInput:callback(WordInput_callback)
WordInput:resize(15,169,715,146)
WordInput:color(55)
WordInput:labelsize(94)
WordInput:labelcolor(179)
WordInput:align(5)
WordInput:when(1)
WordInput:textsize(70)
end
end
spellinglistWindow:show()

spellinglistWindow:make_current()

WordInput:label(spellingLists[unitDepth][listDepth])
UnitLabel= "Unit "..tostring(10+unitDepth)
spellingTimerStart = os.time()
elapsedWordtime = os.time() -spellingTimerStart 
TotalElapsedTime = TotalElapsedTime + elapsedWordtime
UnitElapsedTime = UnitElapsedTime + elapsedWordtime
InfoBrowser:clear()
InfoBrowser:add(UnitLabel)
InfoBrowser:add("Word "..listDepth.." of "..#spellingLists[unitDepth])
InfoBrowser:add("Words Today: "..wordscompleted)
InfoBrowser:add("Keystrokes: "..keystrokeCount.." for "..totalLetters)
TimeBrowser:add("Word time: "..elapsedWordtime)
TimeBrowser:add("Unit Time: "..UnitElapsedTime)
TimeBrowser:add("Total Time: "..TotalElapsedTime)
TimeBrowser:add("WPM: "..wpmcount.."_"..minuteCount.." = "..wordsPerMinute)
spellinglistWindow:redraw()

Fl:run()