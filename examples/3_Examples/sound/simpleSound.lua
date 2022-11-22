-- create an audio device using default parameters and exit in case of errors

if not proAudio.create() then os.exit(1) end

-- load and play a sample:
sample = proAudio.sampleFromFile("VeryAlarmed.ogg")
if sample then proAudio.soundPlay(sample) end

print("Playing OGG file")
io.flush()

-- wait until the sound has finished:
while proAudio.soundActive()>0
do
	murgaLua.sleep(500)
end

-- load and play a sample:
sample = proAudio.sampleFromFile("winNatureSysStart.wav")
if sample then proAudio.soundPlay(sample) end

print("Playing WAV file")
io.flush()

-- wait until the sound has finished:
while proAudio.soundActive()>0
do
	murgaLua.sleep(500)
end

-- cleanup and exit
proAudio.destroy()
os.exit(0)
