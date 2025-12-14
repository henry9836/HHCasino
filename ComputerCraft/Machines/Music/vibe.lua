local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

local decoder = dfpwm.make_decoder()
local h = fs.open("music.dfpwm", "rb")

local upsampleFactor = 6 -- 8k -> 48k

while true do
    local chunk = h.read(1024)  -- small chunks
    if not chunk then break end
    local decoded = decoder(chunk)  -- decode 8k chunk

    -- upsample by repeating each sample
    local upsampled = {}
    for i = 1, #decoded do
        for j = 1, upsampleFactor do
            upsampled[#upsampled+1] = decoded:sub(i,i)
        end
    end

    speaker.playAudio(table.concat(upsampled))
    os.pullEvent("speaker_audio_empty")
end

h.close()
