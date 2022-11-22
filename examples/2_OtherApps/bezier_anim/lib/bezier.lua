--[[
**********************************************************
*    Bezier Anim
*
*   The <bezier.lua> script provides functions for obtaining the 
*   points along a bezier line and moving a sprite along them
*  
*   @author:     Marielle Lange 
*   @date:       2007-05-27
*   @version:    0.1 
*   @support:    Lua 5.1, murgaLua ???
***********************************************************/
]]

--[[
--   coord
--
--  Basic constructor for a coordinate object
]]

function coord(x,y)
  if type(x) ~= "number" then x = 0 end
  if type(y) ~= "number" then y = 0 end
  return x,y
end

--[[
--   bezier curve
--
--  Equations to compute the multiplying coefficient associated with 
--  each element of the bezier curve.
]]
function bz1(t)
  return (t*t*t)
end
-------------
function bz2(t)
  return (3*t*t*(1-t))
end
-------------
function bz3(t)
  return (3*t*(1-t)*(1-t))
end
-------------
function bz4(t)
  return ((1-t)*(1-t)*(1-t))
end


--[[
--   point on bezier curve
--
--  Given a bezier curve defined by 2 points and 2 control handles, returns
--  the position of the point that is at x percent from the start of the bezier curve
]]
function bz_getpos(percent, pt1, pt2, ct1, ct2)
  x,y = coord()
  x = (pt1.x * bz1(percent)) + (pt2.x * bz2(percent)) + (ct1.x * bz3(percent)) + (ct2.x * bz4(percent))
  y = (pt1.y * bz1(percent)) + (pt2.y * bz2(percent)) + (ct1.y * bz3(percent)) + (ct2.y * bz4(percent))
  x,y = round(x), round(y)
  return x,y
end

--[[
--  Points making up the Bezier Curve
--
--  Given a bezier curve defined by 2 points and 2 control handles, returns
--  all the points that make up the bezier curve. With inc = 0.01, will return 100 points.
]]

function curve_getPoints(pt1, pt2, ct1, ct2)
  stage = 0
  inc = 0.01
  points = {}
  ptn = 0
  
  repeat
    -- increment to next step
    stage = stage + inc
    x,y = bz_getpos(stage,pt1,ct1,ct2,pt2)
    ptn = ptn + 1
    points[ptn] = {x=x,y=y}
  until stage > 1  -- stop if reaches the end of the curve
	return points
end

--[[
--   Running the Animation
--
--  The animation function is defined as a coroutine so to allow to be 
--  run every FPS. It is started using a coroutine.resume(anim) call in
--  the main program.
]]

function run_anim(srpite,points)
    local pos = {}
    for p = 1,100 do -- should loop for the number of entries in points, set to 10 for testing purposes
      pos = points[p]
      sprite:position(pos.x,pos.y)
      window:redraw();
      Fl:wait();
	  murgaLua.sleep(50);
    end
end