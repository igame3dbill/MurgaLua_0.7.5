-- create an audio device using default parameters and exit in case of errors
require("proAudioRt")
if not proAudio.create() then os.exit(1) end

-- load and play a sample:
sample = proAudio.sampleFromFile("sample.ogg")
if sample then proAudio.soundPlay(sample) end

-- wait until the sound has finished:
while proAudio.soundActive()>0 do end -- for the sake of simplicity busy waiting instead of a preferable sleep() call

-- cleanup and exit
proAudio.destroy()
os.exit(0)