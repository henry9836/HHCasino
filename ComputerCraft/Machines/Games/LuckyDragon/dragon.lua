local api = require("lib.api")
local config = require("lib.config")
local crypto = require("lib.crypto")
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()

-- Load Config Data
local configUrl = config.getApiUrl();
local configSecret = config.getSecret();

local activeUserId = ""
local activeUserName = ""
local sampleRate = 48000

local function play(filename, originalRate)
    for chunk in io.lines(filename, 16 * 1024) do
        local buffer = decoder(chunk)

        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

local toggleLight(state)
    redstone.setOutput("top", state)
end

toggleLight(true)

