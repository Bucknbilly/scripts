local CONFIG = getgenv().CONFIG
if not CONFIG or not CONFIG.main then
    warn("CONFIG not set! do getgenv().CONFIG = { main = 'yourname' } before loading!")
    return
end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService   = game:GetService("TextChatService")
local StarterGui        = game:GetService("StarterGui")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

local lp = Players.LocalPlayer

local function notify(title, text)
    StarterGui:SetCore("SendNotification", {Title = title, Text = tostring(text), Duration = 5})
end

local function say(msg)
    pcall(function()
        local chan = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
        if chan then chan:SendAsync(msg) return end
        if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
        end
    end)
end

local function getTime()
    local ls = lp:FindFirstChild("leaderstats")
    if ls then
        local t = ls:FindFirstChild("Time")
        if t and (t:IsA("IntValue") or t:IsA("NumberValue")) then
            return math.max(0, math.floor(t.Value))
        end
    end
    return 0
end

local function donate(amount)
    if amount <= 0 then return notify("Donate Fail", "0 time") end
    say(';donate "' .. CONFIG.main .. '" "' .. amount .. '"')
    notify("Donated", amount .. " to " .. CONFIG.main)
end

local autoEnabled = false
local autoInterval = 60
local autoThread = nil

local function toggleAuto(enable, interval)
    if autoThread then task.cancel(autoThread) autoThread = nil end
    autoEnabled = enable
    if enable then
        autoInterval = interval or autoInterval
        autoThread = task.spawn(function()
            while autoEnabled do donate(getTime()) task.wait(autoInterval) end
        end)
        notify("Auto Donate", "ON every " .. autoInterval .. "s")
    else
        notify("Auto Donate", "OFF")
    end
end

local hideConn = nil
local function toggleHide(on)
    if hideConn then hideConn:Disconnect() hideConn = nil end
    if on then
        hideConn = RunService.Stepped:Connect(function()
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(9999, 9999, 9999) end
        end)
        notify("Hide", "ON")
    else
        notify("Hide", "OFF")
    end
end

local function summon()
    local mainPlr = Players:FindFirstChild(CONFIG.main)
    if not mainPlr or not mainPlr.Character or not mainPlr.Character:FindFirstChild("HumanoidRootPart") then
        return notify("Summon", "Main not found")
    end
    toggleHide(false)
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.CFrame = mainPlr.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
        notify("Summon", "Teleported to " .. CONFIG.main)
    end
end

local flingConn = nil
local function findPlayer(query)
    if not query or query == "" then return nil end
    local q = query:lower()
    for _, p in ipairs(Players:GetPlayers()) do if p.Name:lower() == q then return p end end
    for _, p in ipairs(Players:GetPlayers()) do if (p.DisplayName or ""):lower() == q then return p end end
    for _, p in ipairs(Players:GetPlayers()) do if p.Name:lower():find(q, 1, true) then return p end end
    for _, p in ipairs(Players:GetPlayers()) do if (p.DisplayName or ""):lower():find(q, 1, true) then return p end end
    return nil
end

local function toggleFling(on, targetName)
    if flingConn then flingConn:Disconnect() flingConn = nil end
    if not on then
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) hrp.AssemblyAngularVelocity = Vector3.new(0,0,0) end
        notify("Fling", "Stopped") return
    end
    local target = findPlayer(targetName)
    if not target then notify("Fling Error", "No player: " .. tostring(targetName)) return end
    flingConn = RunService.Heartbeat:Connect(function()
        local tHrp  = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local hum   = lp.Character and lp.Character:FindFirstChild("Humanoid")
        if not (myHrp and tHrp) then return end
        myHrp.CFrame = tHrp.CFrame * CFrame.new(math.random(-2,2), math.random(0,1), math.random(-2,2))
        myHrp.AssemblyAngularVelocity = Vector3.new(math.random(-900,900), math.random(-1800,1800), math.random(-900,900))
        local dir = tHrp.Position - myHrp.Position
        local flat = Vector3.new(dir.X, 0, dir.Z)
        local pushDir = (flat.Magnitude > 0.01) and flat.Unit or Vector3.new(1, 0, 0)
        tHrp.AssemblyLinearVelocity = pushDir * 2800 + Vector3.new(math.random(-200,200), math.random(600,1000), math.random(-200,200))
        if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then hum.Jump = true end
    end)
    notify("Fling", "Flinging " .. target.Name)
end

local function isMine(botArg)
    if not botArg or botArg == "" then return true end
    local req = botArg:lower()
    local myName = lp.Name:lower()
    local myDisplay = (lp.DisplayName or ""):lower()
    return myName:find(req, 1, true) ~= nil or myDisplay:find(req, 1, true) ~= nil
end

local function processCmd(msg, speakerName)
    if speakerName ~= CONFIG.main then return end
    local firstChar = msg:sub(1, 1)
    if firstChar ~= "." and firstChar ~= ";" then return end

    local words = {}
    for w in msg:gmatch("%S+") do table.insert(words, w) end
    if #words == 0 then return end

    local cmd = words[1]:sub(2):lower()
    local arg1 = words[2]
    local arg2 = words[3]

    if not isMine(arg2) and not isMine(arg1) then return end

    if cmd == "dall" or cmd == "donateall" then
        donate(getTime())

    elseif cmd == "adall" then
        local n = tonumber(arg1)
        if n and n > 0 then toggleAuto(true, n) else toggleAuto(false) end

    elseif cmd == "stopauto" then
        toggleAuto(false)

    elseif cmd == "hide" then
        toggleHide(true)

    elseif cmd == "unhide" or cmd == "show" then
        toggleHide(false)

    elseif cmd == "summon" then
        summon()

    elseif cmd == "fling" then
        if not arg1 then notify("Fling", "Usage: .fling [player]") return end
        toggleFling(true, arg1)

    elseif cmd == "stopfling" or cmd == "unfling" then
        toggleFling(false)
    end
end

TextChatService.OnIncomingMessage = function(message)
    if not message.TextSource then return end
    local speaker = Players:GetPlayerByUserId(message.TextSource.UserId)
    if not speaker then return end
    processCmd(message.Text, speaker.Name)
end

Players.PlayerChatted:Connect(function(_, player, msg)
    if player then processCmd(msg, player.Name) end
end)

lp.Chatted:Connect(function(msg)
    processCmd(msg, lp.Name)
end)

local VirtualUser = game:GetService("VirtualUser")

lp.Idled:Connect(function()
    pcall(function() VirtualUser:CaptureController() end)
    pcall(function() VirtualUser:ClickButton2(Vector2.new(math.random(1,8), math.random(1,8))) end)
end)

task.spawn(function()
    while true do
        pcall(function() VirtualUser:CaptureController() end)
        pcall(function() VirtualUser:ClickButton2(Vector2.new(math.random(1,8), math.random(1,8))) end)
        task.wait(45)
    end
end)

notify("Script Loaded", "Commands: .dall .adall .hide .unhide .summon .fling .stopfling | Anti-AFK: ON")