--[[
**********************************************************
*    Anim
*
*   The <anim.lua> script provides code for defining an interface
*   that allows the definition of parameters for a bezier 
*   animation
*  
*   @author:     Marielle Lange 
*   @date:       2007-05-27
*   @version:    0.1 
*   @support:    Lua 5.1, murgaLua ???
***********************************************************/
]]

  do 

    --[[
      ||  Settings
      ||
   ]]
      
    require "lib/utils"
    require "lib/bezier"

    --- positions --------
    anim_L = 5
    anim_T = 5
    anim_R = 550
    anim_B = 243
    ------
    bz_color = 70
    pt_color = 92
    pt_size = 10
    dial_size = 25

    --- images --------
    fltk.fl_register_images()
    img_sprite = Fl_Shared_Image.get("pix/car_blue_32.png")
    img_play = Fl_Shared_Image.get("pix/ButtonPlay_01.png")
    img_stop = Fl_Shared_Image.get("pix/ButtonPlay2_03.png")
    img_toolbar = Fl_Shared_Image.get("pix/toolbar.png")
    ------------------ 

    --[[
      ||  Interface / UI
      ||
   ]]

    --------------------------------
    --- Window Box -----------------
    window = fltk:Fl_Double_Window(573, 313, "Bezier Animation");
    window:box(fltk.FL_BORDER_BOX);
    window:color(36);

    --------------------------------
    ---anim_zone -----------------
    anim_zone = fltk:Fl_Box(3, 3, 567, 260);
    anim_zone:box(fltk.FL_BORDER_BOX);
    anim_zone:image(img_display);
    anim_zone:color(55);

    -----------------------------------
    --- 2 points for the bezier line  -
    pt_left = fltk:Fl_Button(140, 120, pt_size, pt_size);
    pt_left:color(pt_color);
    pt_right = fltk:Fl_Button(520, 145, pt_size, pt_size);
    pt_right:color(pt_color);

    -----------------------------------
    --- 2 control handles for the bezier line  -
    bz_left = fltk:Fl_Button(135, 35, pt_size, pt_size);
    bz_left:color(bz_color);
    bz_right = fltk:Fl_Button(535, 60, pt_size, pt_size);
    bz_right:color(bz_color);

    --------------------------------
    --- sprite to be animated ------
    sprite = fltk:Fl_Box(510, 145, 50, 40);
    sprite:image(img_sprite);
    sprite:redraw();

    --[[
      ||  Managing the animation, once the button "play" is pushed
      ||
   ]]

    
    function animate_callback(object)
      pt1 = {}; pt2 = {}; ct1 = {}; ct2 = {}; 
      pt1.x = pt_left:x(); pt1.y = pt_left:y()
      pt2.x = pt_right:x(); pt2.y = pt_right:y()
      ct1.x = bz_left:x(); ct1.y = bz_left:y()
      ct2.x = bz_right:x(); ct2.y = bz_right:y()
      io.output("bezier_points.txt")
      io.write(package.path) 
      points = curve_getPoints(pt1, pt2, ct1, ct2)
    
      run_anim(sprite,points)
      -- io.output("bezier_points.txt")
      -- io.write(serialize(points))
    end

    --[[
      ||  Toolbar
      ||
      ||  The toolbar is made, from right to left:
      ||      * a button to start and stop the animation
      ||      * a slider bar to define the speed of the animation
      ||      * 4 times 2 dial button, 2 pairs for the points, 2 pairs for the control handles  of the bezier line
   ]]

    --------------------------------
    --- Toolbar Box ----------------
    toolbar = fltk:Fl_Box(-1, 260, 575, 55);
    toolbar:image(img_toolbar);

    --------------------------------
    --- Animate Button -------------
    animate = fltk:Fl_Button(528, 274, dial_size, dial_size);
    animate:image(img_play);
    animate:callback(animate_callback);
    
    
    --------------------------------
    --- Speed Slider ---------------
    speed_slider = fltk:Fl_Slider(355, 276, 140, 20);
    speed_slider:type(1)
    speed_slider:range(5, 55)
    speed_slider:step(1)
    speed_slider:callback(
      function(slider)
        --
    end)

    --------------------------------
    --- Dials ---------------------  Note:   They should be recoded as a dial object. 

    bz_left_x = fltk:Fl_Dial(20, 274, dial_size, dial_size);
    bz_left_x:color(bz_color);
    -- bz_left_x:box(fltk.FL_PLASTIC_ROUND_DOWN_BOX); shows the dot, not the button
    bz_left_x:value(bz_left:x())
    bz_left_x:range(anim_L, anim_R)
    bz_left_x:step(1)
    --
    bz_left_x:callback(
      function(bz_left_x)
        bz_left:position(bz_left_x:value(),bz_left:y());
        window:redraw();
    end)
    -- ######################## --
    bz_left_y = fltk:Fl_Dial(50, 274, dial_size, dial_size);
    bz_left_y:color(bz_color);
    bz_left_y:value(bz_left:y())
    bz_left_y:range(anim_T, anim_B)
    bz_left_y:step(1)
    --
    bz_left_y:callback(
      function(bz_left_y)
        bz_left:position(bz_left:x(),bz_left_y:value());
        window:redraw();
    end)
    -- ######################## --
    bz_right_x = fltk:Fl_Dial(190, 274, dial_size, dial_size);
    bz_right_x:color(bz_color);
    bz_right_x:value(bz_right:x())
    bz_right_x:range(anim_L, anim_R)
    bz_right_x:step(1)
    ---
    bz_right_x:callback(
      function(bz_right_x)
        bz_right:position(bz_right_x:value(),bz_right:y());
        window:redraw();
    end)

    -- ######################## --
    bz_right_y = fltk:Fl_Dial(220, 274, dial_size, dial_size);
    bz_right_y:color(bz_color);
    bz_right_y:value(bz_right:y())
    bz_right_y:range(anim_T, anim_B)
    bz_right_y:step(1)
    ---
    bz_right_y:callback(
      function(bz_right_y)
        bz_right:position(bz_right:x(),bz_right_y:value());
        window:redraw();
    end)

    -- ######################## --
    pt_left_x = fltk:Fl_Dial(90, 274, dial_size, dial_size);
    pt_left_x:color(pt_color);
    pt_left_x:value(pt_left:x())
    pt_left_x:range(anim_L, anim_R)
    pt_left_x:step(1)
    --
    pt_left_x:callback(
      function(pt_left_x)
        pt_left:position(pt_left_x:value(),pt_left:y());
        window:redraw();
    end)
    -- ######################## --
    pt_left_y = fltk:Fl_Dial(120, 274, dial_size, dial_size);
    pt_left_y:color(pt_color);
    pt_left_y:value(pt_left:y())
    pt_left_y:range(anim_T, anim_B)
    pt_left_y:step(1)
    --
    pt_left_y:callback(
      function(pt_left_y)
        pt_left:position(pt_left:x(),pt_left_y:value());
        window:redraw();
    end)
    -- ######################## --
    pt_right_x = fltk:Fl_Dial(260, 274, dial_size, dial_size);
    pt_right_x:color(pt_color);
    pt_right_x:value(pt_right:x())
    pt_right_x:range(anim_L, anim_R)
    pt_right_x:step(1)
    ---
    pt_right_x:callback(
      function(pt_right_x)
        pt_right:position(pt_right_x:value(),pt_right:y());
        window:redraw();
    end)
    -- ######################## --
    pt_right_y = fltk:Fl_Dial(290, 274, dial_size, dial_size);
    pt_right_y:color(pt_color);
    pt_right_y:value(pt_right:y())
    pt_right_y:range(anim_T, anim_B)
    pt_right_y:step(1)
    ---
    pt_right_y:callback(
      function(pt_right_y)
        pt_right:position(pt_right:x(),pt_right_y:value());
        window:redraw();
    end)



  end
  window:show();
  Fl:run();
