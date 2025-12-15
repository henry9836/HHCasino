-- ffmpeg -i input.wav -ac 1 -ar <sampleRate> output.dfpwm
-- mpv --audio-samplerate=22000 Hills.dfpwm
local api = require("lib.api")
local config = require("lib.config")
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()

local configUrl = config.getApiUrl();
local sampleRate = 48000

-- Function to play a DFPWM file of any sample rate
-- filename: string, path to the DFPWM file
-- originalRate: number, sample rate the file was encoded at (e.g., 8000, 16000)
local function play(filename, originalRate)
    if not speaker then
        error("No speaker found")
    end
 
    local upsampleFactor = math.floor(48000 / originalRate + 0.5)
    if upsampleFactor < 1 then upsampleFactor = 1 end
 
    local decoder = dfpwm.make_decoder()
    local h = fs.open(filename, "rb")
    if not h then
        error("File not found: " .. filename)
    end
 
    while true do
        local chunk = h.read(1024)
        if not chunk then break end
        local decoded = decoder(chunk)  -- returns table of bytes
 
        -- upsample by repeating each sample
        local upsampled = {}
        for i = 1, #decoded do
            for j = 1, upsampleFactor do
                upsampled[#upsampled + 1] = decoded[i]
            end
        end
 
        speaker.playAudio(upsampled)
        os.pullEvent("speaker_audio_empty")
    end
 
    h.close()
end

-- Open modem port and list
local modem = peripheral.find("modem")
if modem then
    modem.open(666)
end

-- Reads music list
local playlistFile = fs.open("playlistFile", "r")
local playlist = {}
while true do
    local line = file.readLine()
    if not line then break end

    line = line:match("^%s*(.-)%s*$") -- trim whitespace
    if line ~= "" then
        table.insert(list, line)
    end
end

-- Randomises a music list
math.randomseed(os.epoch("utc"))
for i = #playlist, 2, -1 do
    local j = math.random(i)
    playlist[i], playlist[j] = playlist[j], playlist[i]
end

-- print result for now
print("[ Playlist Queued ]")
for i, file in ipairs(playlist) do
    write(" - ")
    print(file)
end

-- Plays through the music list
local t, dt = 0, 2 * math.pi * 220 / 48000
for i, file in ipairs(playlist) do
    -- Get rid of the previous files
    shell.run("rm", "/playlist/*.dfpwm")

    term.clear()
    term.setCursorPos(1, 1)
    print("Retrieving: " .. file)

    local result = api.searchMusicFile(file, configUrl)
    if result then
        sampleRate = tonumber(result["sample-rate"])
        webpath = result.path

        -- wget url /playlist/filename.dfpwm
        shell.run("wget", webpath .. " " .. "/playlist/" .. file .. ".dfpwm")

        print("Currently Playing: " .. file)
        play("/playlist/" .. file .. ".dfpwm", sampleRate)
    else
        print("ERROR")
        sleep(3)
        goto continue
    end
end

-- If we get a modem comm then insert at next position of list

-- When empty rerandomise and restart loop

print("Restarting playlist in 3 seconds")
sleep(3)
os.reboot()