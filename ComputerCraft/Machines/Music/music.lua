local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()
local sampleRate = 48000

-- Speakers play at 48kHz, so 1.5 seconds is 72k samples. We first fill our buffer
-- with 0s, as there's nothing to echo at the start of the track!
function play(filename)
    local samples_i, samples_n = 1, sampleRate * 1.5
    local samples = {}
    for i = 1, samples_n do samples[i] = 0 end

    local decoder = dfpwm.make_decoder()
    for chunk in io.lines(filename, 16 * 1024) do
        local buffer = decoder(chunk)

        for i = 1, #buffer do
            local original_value = buffer[i]

            -- Replace this sample with its current amplitude plus the amplitude from 1.5 seconds ago.
            -- We scale both to ensure the resulting value is still between -128 and 127.
            buffer[i] = original_value * 0.6 + samples[samples_i] * 0.4

            -- Now store the current sample, and move the "head" of our ring buffer forward one place.
            samples[samples_i] = original_value
            samples_i = samples_i + 1
            if samples_i > samples_n then samples_i = 1 end
        end

        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end

        -- The audio processing above can be quite slow and preparing the first batch of audio
        -- may timeout the computer. We sleep to avoid this.
        -- There's definitely better ways of handling this - this is just an example!
        sleep(0.05)
    end
end

-- Open modem port and list
local modem = peripheral.find("modem")
if modem then
    modem.open(666)
end

-- Randomises a music list
local playlist = fs.list('/playlist')
math.randomseed(os.epoch("utc"))
for i = #playlist, 2, -1 do
    local j = math.random(i)
    playlist[i], playlist[j] = playlist[j], playlist[i]
end

-- print result for now
print ("[ Playlist Queued ]")
for i, file in ipairs(playlist) do
    write(" - ")
    print(file)
end

-- Plays through the music list
local t, dt = 0, 2 * math.pi * 220 / 48000
for i, file in ipairs(playlist) do
    term.clear()
    term.setCursorPos(1, 1)
    print("Currently Playing: " .. file)
    play("/playlist/" .. file)
end

-- If we get a modem comm then insert at next position of list

-- When empty rerandomise and restart loop

print("Restarting playlist in 3 seconds")
sleep(3)
os.reboot()