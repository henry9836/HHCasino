local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()

-- Open modem port and list
local modem = peripheral.find("modem") or error("No modem attached", 0)
if modem then
    modem.open(666)
end

-- Randomises a music list
local playlist = fs.list('/playlist')
math.randomseed(os.epoch("utc"))
for i = #files, 2, -1 do
    local j = math.random(i)
    files[i], files[j] = files[j], files[i]
end

-- print result for now
print ("[ Playlist Queued ]")
for i, file in ipairs(files) do
    write(" - ")
    print(file)
end

-- Plays through the music list

-- If we get a modem comm then insert at next position of list

-- When empty rerandomise and restart loop

print("Restarting playlist in 3 seconds")
sleep(3)
os.reboot()