--[[
    Makes the terminal scrollable with page up/down keys, end to go all the way down. Holding del terminates any running programs because Ralph wanted that feature.
    Recommend placing the lua file in root to make calling it easier.
    Usage: Scrollable <program you want to run> <args>
    Usage with monitor: monitor <side> Scrollable <program you want to run> <args>
]]

local scrollableTerminal = {}

function scrollableTerminal.InitIfNeeded()
    if scrollableTerminal.initialized ~= nil then
        return
    end
    --override default print function
    scrollableTerminal.CachedOGPrintFunction = _G.print
    _G.print = scrollableTerminal.printOverwrite
    -- change maxSize to allow more or less messages to be buffered
    scrollableTerminal.maxSize = 50
    scrollableTerminal.initialized = true
    scrollableTerminal.curBufferLocation = 1
    scrollableTerminal.screenBuffer = {}
    scrollableTerminal.width, scrollableTerminal.height = term.getSize()
    scrollableTerminal.height = scrollableTerminal.height -1 -- leave 1 line for menu bar
end

function scrollableTerminal.DrawScreenBuffer()
    if #scrollableTerminal.screenBuffer ~= 0 then
        term.clear()
        for i = 1, scrollableTerminal.height do
            if scrollableTerminal.screenBuffer[i + scrollableTerminal.curBufferLocation -1] ~= nil then
                term.setCursorPos(1,i)
                local text = tostring(scrollableTerminal.screenBuffer[i + scrollableTerminal.curBufferLocation -1])
                term.write(text)
            end
        end

        --draw menu bar
        local menuBar = tostring(scrollableTerminal.curBufferLocation -1) .. " - " .. tostring(scrollableTerminal.curBufferLocation -1 + scrollableTerminal.height)
        menuBar = menuBar .. "  size: " .. tostring(#scrollableTerminal.screenBuffer) .. "/" .. tostring(scrollableTerminal.maxSize)
        local centerX = math.ceil(scrollableTerminal.width / 2)
        local letterStartX = math.floor( (centerX + 1) - (string.len(menuBar) /2))
        term.setCursorPos(letterStartX, scrollableTerminal.height + 1)
        term.write(menuBar)
        term.setCursorPos(1, scrollableTerminal.height + 1)
    end
end

--split input string into many lines for scrollability
function scrollableTerminal.splitString(input)
    input = tostring(input)
    if input == "" then
        return {""}
    end
    local subStrings = {}
    local prevSplit = 0
    for i = 1, #input do
        if string.sub(input, i, i) == "\n" then
            local v1 = string.sub(input, prevSplit, i)
            local v2 = string.gsub(v1, "\n", "")
            table.insert(subStrings, v2)   --delete newlines and split into two separate lines
            prevSplit = i
        end
    end
    if prevSplit ~= #input then --add trailing bit of the string, or the whole string if it wasn't split before
        table.insert(subStrings, string.sub(input, prevSplit +1, #input))
    end
    local shortSubStrings = {}
    for i = 1, #subStrings do
        string = subStrings[i]
        while #string > scrollableTerminal.width do
            for i = scrollableTerminal.width +1, 1, -1 do
                if i == 1 then
                    table.insert(shortSubStrings, string.sub(string, 1, scrollableTerminal.width))
                    string = string.sub(string, scrollableTerminal.width +1, #string)
                    break
                elseif string.sub(string, i, i) == " " then
                    table.insert(shortSubStrings, string.sub(string, 1, i -1))
                    string = string.sub(string, i +1, #string)
                    break
                end
            end
        end
        if #string > 0 then
            if string.sub(string, 1, 1) == " " then
                string = string.sub(string, 2)
            end
            table.insert(shortSubStrings, string)
        end
    end
    return shortSubStrings
end

function scrollableTerminal.printOverwrite(text)
    scrollableTerminal.InitIfNeeded()
    text = tostring(text)

    local splitText = scrollableTerminal.splitString(text)
    for i = 1, #splitText do
        table.insert(scrollableTerminal.screenBuffer, splitText[i])
        if #scrollableTerminal.screenBuffer > scrollableTerminal.maxSize then
            table.remove(scrollableTerminal.screenBuffer,1)
            if #scrollableTerminal.screenBuffer > scrollableTerminal.height + 1
                and scrollableTerminal.curBufferLocation > 1 then
                    scrollableTerminal.curBufferLocation = scrollableTerminal.curBufferLocation -1
            end
        end

        if #scrollableTerminal.screenBuffer > scrollableTerminal.height -- autoscroll when buffer is large enough
        and not ((#scrollableTerminal.screenBuffer -1) > scrollableTerminal.curBufferLocation + scrollableTerminal.height) then -- stop autoscroll when user manually goes up
            scrollableTerminal.curBufferLocation = scrollableTerminal.curBufferLocation + 1
        end
    end
    scrollableTerminal.DrawScreenBuffer()
end

-- 1 to scroll down -1 to scroll up -999 for last line
function scrollableTerminal.UpdateBufferLocationAndDraw(scrollDirection)
    scrollableTerminal.InitIfNeeded()
    if scrollDirection == -1 then
        scrollableTerminal.curBufferLocation = scrollableTerminal.curBufferLocation - 1
    elseif scrollDirection == 1 then
        if scrollableTerminal.curBufferLocation + scrollableTerminal.height -1 < #scrollableTerminal.screenBuffer then
            scrollableTerminal.curBufferLocation = scrollableTerminal.curBufferLocation + 1
        end
    elseif scrollDirection == -999 then
        scrollableTerminal.curBufferLocation = #scrollableTerminal.screenBuffer-scrollableTerminal.height +1
    else
        error("invalid argument enter 1, -1 or -999",1)
    end

    if scrollableTerminal.curBufferLocation < 1 then
        scrollableTerminal.curBufferLocation = 1
    end
    if scrollableTerminal.curBufferLocation > #scrollableTerminal.screenBuffer then
        scrollableTerminal.curBufferLocation = #scrollableTerminal.screenBuffer
    end
    scrollableTerminal.DrawScreenBuffer()
end

local function ScrollableTerminalFnc()
    while true do
        local eventInfo = {os.pullEventRaw()}
        if eventInfo[1] == "key" then
            if eventInfo[2] == keys.pageUp then
                scrollableTerminal.UpdateBufferLocationAndDraw(-1)
            elseif eventInfo[2] == keys.pageDown then
                scrollableTerminal.UpdateBufferLocationAndDraw(1)
            elseif eventInfo[2] == keys['end'] then
                scrollableTerminal.UpdateBufferLocationAndDraw(-999)
            elseif eventInfo[2] == keys.delete and eventInfo[3] ~= nil and eventInfo[3] == true then
                _G.print = scrollableTerminal.CachedOGPrintFunction  --rebind standard print function
                term.clear()
                term.setCursorPos(1,1)
                error()     --there is no way to just terminate a program besides os.shutdown if catching the terminate event, I guess
            end
        elseif eventInfo[1] == "mouse_scroll" then
            scrollableTerminal.UpdateBufferLocationAndDraw(eventInfo[2])
        elseif eventInfo[1] == "terminate" then
            _G.print = scrollableTerminal.CachedOGPrintFunction  --rebind standard print function
            term.clear()
            term.setCursorPos(1,1)
            error()
        end
    end
end



local tArgs = {...}

local function execProgram()
    local suc, ret = pcall(shell.run, table.unpack(tArgs))
    print("----------- PROGRAM EXITED -----------")
    if not suc then
        print(ret)
    end
    print("--------------------------------------")
    print("Terminate this to run another program.")
end

scrollableTerminal.InitIfNeeded()
parallel.waitForAll(ScrollableTerminalFnc, execProgram)