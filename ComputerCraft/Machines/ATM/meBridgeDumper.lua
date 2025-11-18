local meBridge = peripheral.find("meBridge")

term.clear()

print("Dumping all ME items...")
print("======================")
local items = meBridge.listItems()
for _, item in pairs(items) do
    print(item.name .. ":" .. item.amount)
end
