--function make_window()
-- Generate Temporary Grid


GridSize=256
GridSpread=20

function wClose(w)
w:hide()
w=nil
end


grpGrid={}
drpGrid={}
drpColors={}
btnList={}
	function startGrid()
	grid:w(GridSize*GridSpread)
	grid:h(GridSize*GridSpread)
		for i = 1,GridSize,1 do
		for ii = 1,GridSize,1 do
		table.insert(grpGrid,{i*GridSpread,ii*GridSpread})
		table.insert(drpGrid,{0,0})
		table.insert(btnList,"")
		end
		end
	end


function idleDrag()
if DWindow == nil then return end

if Fl:event_key()==32 then newcolor=fltk.fl_show_colormap(nc) end

 if newcolor == nil then 
nc = math.random(1,255)
else
nc = newcolor
end


	local Q = '"'
	fe=Fl:event()
	if fe == 1 or fe == 5 then 
		mx,my=Fl:event_x(),Fl:event_y()
      		rx,ry=10,10    
		xi,yi = 0,0
		ia,ib = 0,0
		

		for i = 1,#grpGrid,1 do
			if mx ~= nil  then 	
			xi=grpGrid[i][1]
			 yi =grpGrid[i][2] 
			  
				if mx >= xi and mx <= xi+(GridSpread-1) and my >= yi and my <= yi+(GridSpread-1) then
				 ia  = i
		 		 btnm = "x"..xi.."y"..yi
		 			drpColors[ia] = nc
					fltk.fl_color(nc) 
					srun = "if "..btnm.." == nil then ".. btnm.."= fltk:Fl_Button("..xi..","..yi..","..tostring(GridSpread)..","..tostring(GridSpread)..","..Q..Q..");\n"..btnm..":box(fltk.FL_FLAT_BOX);\n"..btnm..":color("..nc..")\n keeper:add("..btnm..") \n "..btnm..":show()\n  btnList[ia]="..Q..btnm..Q.." end\n;"

		
			makeabutton =  loadstring(srun)
				makeabutton()
						crun = "if "..btnm..":w()==0 then \n"..btnm.."=nil \n".." else \n"..btnm..":show() \n end\n"
				chck = loadstring(crun)
chck()
				
		 		end
		
			end
		end
		
		
		
		
			

else
	--grid:hide()
	
end

if Fl:event() == 2 then 

	
	end
	
	DWindow:redraw()



Fl:check()
end

function gridCB()
 idleDrag() 
print(Fl:event())

end
do DWindow= fltk:Fl_Double_Window(0,0,0,0,"")
if gLabelTable==nil then gLabelTable={} end
table.insert(gLabelTable, "DragGrid")
DWindow:label(gLabelTable[#gLabelTable])
DWindow:callback(wClose)
DWindow:resize(167,50,258,260)
DWindow:when(1)
Fl_Group:current():resizable(DWindow)
--DWindow:show()
do keeper= fltk:Fl_Scroll(0,0,0,0,"")
keeper:resize(0,0,256,256)
keeper:type(7)
keeper:align(5)
Fl_Group:current():resizable(keeper)
do grp= fltk:Fl_Group(0,0,0,0,"")
grp:callback(idleDrag)
grp:resize(0,0,2565,2565)
grp:when(1)
Fl_Group:current(Fl_Group:current():parent())
end

do grid= fltk:Fl_Button(0,0,0,0,"")
grid:callback(idleDrag)
grid:resize(0,0,2560,2560)
grid:box(fltk.FL_UP_FRAME)
grid:down_box(fltk.FL_BORDER_FRAME)
grid:labelsize(11)
end
end
end
DWindow:show()

DWindow:show();
DWindow:make_current();
grid:when(1)
grp:when(5)
grid:hide()


DWindow:show()
startGrid()

timer = murgaLua.createFltkTimer()
timer:callback(idleDrag)
timer:do_callback()

while DWindow  ~= nil do

idleDrag()

end
--end
Fl:run()
