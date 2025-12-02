local Bridge = {}

Bridge.meBridge = peripheral.find("meBridge")

function Bridge.dumpAllItems()
    return Bridge.meBridge.listItems()
end

function Bridge.dumpAllItemsToScreen()
    local items = Bridge.dumpAllItems();

    for _ , item in pairs(items) do
        print(item.name ..  ":" .. item.amount)
    end
end

return Bridge;
