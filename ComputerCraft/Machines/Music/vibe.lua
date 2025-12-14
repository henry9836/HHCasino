local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

local decoder = dfpwm.make_decoder()
local h = fs.open("music.dfpwm", "rb")

while true do
    local chunk = h.read(16 * 1024)
    if not chunk then break end
    speaker.playAudio(decoder(chunk))
    os.pullEvent("speaker_audio_empty")
end

h.close()
