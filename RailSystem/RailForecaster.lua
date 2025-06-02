dfpwm = require("cc.audio.dfpwm")
speaker = peripheral.find("speaker")
monitor = peripheral.find("monitor")

LastCartTravelTimestamp = os.epoch("utc") / 1000
HasPlayedAnnouncement = true

function PlayAnnouncement()
    local decoder = dfpwm.make_decoder()
    for chunk in io.lines("sounds/Arriving.dfpwm", 16 * 1024) do
        local buffer = decoder(chunk)

        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

function ProcessCart()
    -- Reset announcer
    HasPlayedAnnouncement = false

    -- Update last cart timestamp
    LastCartTravelTimestamp = os.epoch("utc") / 1000
end

function UpdateScreenInfo()
    local TimeSinceLastCart = (os.epoch("utc") / 1000) - LastCartTravelTimestamp
    local TimeTillNextCart = math.max(23.50 - TimeSinceLastCart, 0) -- Used to be 23.5

    if (TimeTillNextCart <= 21) and (HasPlayedAnnouncement == false) then
        PlayAnnouncement()
        HasPlayedAnnouncement = true
    end

    monitor.clear()

    monitor.setCursorPos(8, 1)
    monitor.write("Hellhole Casino")

    monitor.setCursorPos(9, 2)
    monitor.write("Rail Transport")

    monitor.setCursorPos(1, 4)
    if TimeTillNextCart < 10 then
        monitor.setCursorPos(5, 4)
        monitor.write(string.format("Cart is now arriving"))
    else
        monitor.write("Please wait for the next cart")
    end
end

-- ##################
-- #      MAIN      #
-- ##################

-- Set up the monitor
monitor.clear()
monitor.setTextScale(1)  -- Adjust text size
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.red)
monitor.clear()

while true do
    if redstone.getInput("back") then
        ProcessCart()
    end
    UpdateScreenInfo()
    sleep(0.05)
end
