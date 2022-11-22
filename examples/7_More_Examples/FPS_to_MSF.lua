-- by mikshaw

-- A Tool to convert Frames Per Second to Milliseconds per Frame

ww = 250
bw = ww/5
bh = 30
wh = bh*4

function fps_to_mpf()
    mpf_val = math.ceil(1/fps_box:value()*1000)
    mpf_box:value(mpf_val)
    mpf_slide:value(mpf_val)
end
function mpf_to_fps()
    fps_val = math.ceil(1000/mpf_box:value())
    fps_box:value(fps_val)
    fps_slide:value(fps_val)
end

win = fltk:Fl_Window(ww, wh, "frames-per-second/milliseconds-per-frame")
fps_box = fltk:Fl_Int_Input(0, 10, bw, bh, "frames per second")
fps_box:align(6)
fps_slide = fltk:Fl_Hor_Slider(bw, 10, bw*4, bh)
fps_slide:minimum(1)
fps_slide:maximum(200)
fps_slide:step(1)
fps_slide:callback(
function()
    fps_box:value(fps_slide:value())
    fps_to_mpf()
end)
fps_box:callback(
function()
    fps_slide:value(fps_box:value())
    fps_to_mpf()
end)

mpf_box = fltk:Fl_Int_Input(0, bh*2, bw, bh, "milliseconds per frame")
mpf_box:align(6)
mpf_slide = fltk:Fl_Hor_Slider(bw, bh*2, bw*4, bh)
mpf_slide:minimum(5)
mpf_slide:maximum(1000)
mpf_slide:step(1)
mpf_slide:callback(
function()
    mpf_box:value(mpf_slide:value())
    mpf_to_fps()
end)
mpf_box:callback(
function()
    mpf_slide:value(mpf_box:value())
    mpf_to_fps()
end)

win:show()
Fl:run()