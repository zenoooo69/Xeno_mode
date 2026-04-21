-- SERVICES ( xeno logic )
-- =====================
task.wait(0.5)
local GameStarted = false
local GameRunning = true
local bossDead = false
local RS = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local gold = player:WaitForChild("leaderstats"):WaitForChild("Gold")
local RunService = game:GetService("RunService")
local Towers = workspace:WaitForChild("Towers")
local ignore = {}
local BUILD_DONE = false

-- =====================
-- AUTO CHARM
-- =====================
local RS = game:GetService("ReplicatedStorage")

local AUTO_CHARM = true
local COOLDOWN = 99
local lastUse = 0

task.spawn(function()
    while true do
        task.wait(1)

        if not AUTO_CHARM then continue end
        if bossDead then continue end

        if tick() - lastUse >= COOLDOWN then
            local success = pcall(function()
                RS.Events.UseCharm:FireServer(3)
            end)

            if success then
                lastUse = tick()
                print("Charm đã sài")
            end
        end
    end
end)


local function isIgnored(pos)
    for _,v in ipairs(ignore) do
        if (v - pos).Magnitude < 3 then
            return true
        end
    end
    return false
end

-- =====================
-- SIMPLE GUI (AUTO)
-- =====================
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Xeno Farm"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- FRAME
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 130)
frame.Position = UDim2.new(0, 10, 0.5, -55)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- UI CORNER
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 8)

-- TITLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,20)
title.BackgroundTransparency = 1
title.Text = "69 Xeno 69"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

-- GOLD
goldLabel = Instance.new("TextLabel")
goldLabel.Size = UDim2.new(1,0,0,20)
goldLabel.Position = UDim2.new(0,0,0,20)
goldLabel.BackgroundTransparency = 1
goldLabel.TextColor3 = Color3.fromRGB(255,255,0)
goldLabel.Text = "Gold: 0"
goldLabel.TextScaled = true
goldLabel.Font = Enum.Font.Gotham
goldLabel.Parent = frame

-- NEED
needLabel = Instance.new("TextLabel")
needLabel.Size = UDim2.new(1,0,0,20)
needLabel.Position = UDim2.new(0,0,0,40)
needLabel.BackgroundTransparency = 1
needLabel.TextColor3 = Color3.fromRGB(255,100,100)
needLabel.Text = "Need: 0"
needLabel.TextScaled = true
needLabel.Font = Enum.Font.Gotham
needLabel.Parent = frame

-- COST
costLabel = Instance.new("TextLabel")
costLabel.Size = UDim2.new(1,0,0,20)
costLabel.Position = UDim2.new(0,0,0,60)
costLabel.BackgroundTransparency = 1
costLabel.TextColor3 = Color3.fromRGB(100,255,100)
costLabel.Text = "Cost: 0"
costLabel.TextScaled = true
costLabel.Font = Enum.Font.Gotham
costLabel.Parent = frame

-- NEXT
nextLabel = Instance.new("TextLabel")
nextLabel.Size = UDim2.new(1,0,0,20)
nextLabel.Position = UDim2.new(0,0,0,80)
nextLabel.BackgroundTransparency = 1
nextLabel.TextColor3 = Color3.fromRGB(150,150,255)
nextLabel.Text = "Next: -"
nextLabel.TextScaled = true
nextLabel.Font = Enum.Font.Gotham
nextLabel.Parent = frame

local rebuildLabel = Instance.new("TextLabel")
rebuildLabel.Size = UDim2.new(1,0,0,20)
rebuildLabel.Position = UDim2.new(0,0,0,100)
rebuildLabel.BackgroundTransparency = 1
rebuildLabel.TextColor3 = Color3.fromRGB(255,150,150)
rebuildLabel.Text = "Rebuild: False"
rebuildLabel.TextScaled = true
rebuildLabel.Font = Enum.Font.Gotham
rebuildLabel.Parent = frame

-- =====================
-- STATE
-- =====================
local REBUILDING = false
local rebuildQueue = {}
local rebuildingNow = false
local rebuildState = {
    active = false,
    name = "-",
    level = 0
}
-- =====================
-- VOTE
-- =====================
RS.Events.VoteForMap:FireServer("Distant Lands 2.0")
task.wait(1)
RS.Events.VoteForMap:FireServer("Ready")

task.spawn(function()
    local info = workspace:WaitForChild("Info")
    local gameRunning = info:WaitForChild("GameRunning")

    task.wait(15) -- đợi game vô ( ~15s )
    GameStarted = true

    while true do
        task.wait(0.5)

        if GameStarted and gameRunning.Value == false then
            GameRunning = false
            bossDead = true
            break
        end
    end
end)
-- =====================
-- RESULT CHECK
-- =====================
task.spawn(function()
    local info = workspace:WaitForChild("Info")
    local messages = info:WaitForChild("Message")
    local wave = info:FindFirstChild("Wave")

    local resultDetected = false

    local function check(text)
        text = string.lower(text)

        if string.find(text, "victory") or string.find(text, "victory!") then
            return "WIN"
        end

        if string.find(text, "game over") or string.find(text, "defeat") then
            return "LOSE"
        end
    end

    messages:GetPropertyChangedSignal("Value"):Connect(function()
        if resultDetected then return end

        local result = check(messages.Value)
        if not result then return end

        resultDetected = true
        bossDead = true
        GameRunning = false

        local waveValue = wave and wave.Value or 0

        -- print win/thua
        if result == "WIN" then
            print("🏆 VICTORY")
            print("User:", player.Name)
            print("Gold:", gold.Value)
            print("Wave:", waveValue)
        else
            print("❌ DEFEAT")
            print("User:", player.Name)
            print("Gold:", gold.Value)
            print("Wave:", waveValue)
        end

        -- out game
        task.wait(1)
        pcall(function()
            RS.Events.ExitGame:FireServer()
        end)
    end)
end)
-- =====================
-- COST SYSTEM
-- =====================
local effects = workspace.Info.TowerEffects
local placeMulti = effects.PlacingTowerMultiplier
local upgradeMulti = effects.UpgradePriceMultiplier

local BASE_COST = {}

for _, f in ipairs(RS.Towers:GetChildren()) do
    for _, v in ipairs(f:GetChildren()) do
        for _, lvl in ipairs(v:GetChildren()) do
            for _, m in ipairs(lvl:GetChildren()) do
                if m:IsA("Model") and m:FindFirstChild("Config") then
                    local p = m.Config:FindFirstChild("Price")
                    if p and not BASE_COST[m.Name] then
                        BASE_COST[m.Name] = p.Value
                    end
                end
            end
        end
    end
end
local CUSTOM_COST = {

    -- Wizard
    ["Galaxy Wizard"] = 3500,
    ["Galaxy Potions"] = 2000,
    ["Galaxy Spells"] = 4400,
    ["Enhanced Galaxy Spells"] = 7800,
    ["Galactic Staff"] = 41650,

    -- Guardian
    ["Guardian"] = 1050,
    ["Deserted Armor"] = 2000,
    ["Snowy Helmet"] = 3800,
    ["Lava Knight"] = 11200,
    ["Electrifying Sword"] = 28000,
    ["Guardian Angel"] = 92000,

    -- Lava Mortar
    ["Electric Mortar"] = 4400,
    ["Electric Hat"] = 4700,
    ["Lightning Lava"] = 14500,
    ["Electrically Trained"] = 28400,
    ["Mega Zap Mortar"] = 96500,

    -- Catalyst
    ["Catalyst"] = 400,
    ["Electrically Charged"] = 350,
    ["VoidLightning"] = 2000,
    ["High Voltage"] = 8560,
    ["Deadly Bolts"] = 21500,

    -- Chainsaw
    ["Chainsaw Wielder"] = 1350,
    ["Soundproof"] = 1800,
    ["Extra Protection"] = 8600,
    ["Magic Chainsaw"] = 34500,
    ["Magical Shredding"] = 88000,

    -- Helicopter
    ["Helicopter Kid"] = 2400,
    ["Stable Flying"] = 6000,
    ["Bombs"] = 29000,
    ["Toxic Bombs"] = 58000,
    ["Death Heli"] = 132000,

    -- Lava Sniper
    ["Lava Sniper"] = 2500,
    ["Fire Shades"] = 2000,
    ["Magma Hat"] = 4250,
    ["Lava Coat"] = 10000,
    ["Eruption Sniper"] = 22000,
    ["Volcanic Lasers"] = 46000,

    -- 🔥 Machinist
    ["Machinist"] = 1000,
    ["Faster Working"] = 1300,
    ["Second Machine"] = 3200,
    ["True Machinist"] = 9000,
    ["Futurist"] = 19250,

    -- Ray Blaster
    ["Geo Blaster"] = 2875,
    ["Geometrical Suit"] = 1200,
    ["Hacker"] = 3250,
}

local function getCost(name, up, towerInstance)
    local base = CUSTOM_COST[name] or BASE_COST[name] or 0
    local cost = base * (up and upgradeMulti.Value or placeMulti.Value)

    -- check giá giảm
    if towerInstance and towerInstance:FindFirstChild("Config") then
        local cheaper = towerInstance.Config:FindFirstChild("CheaperUpgrades")
        if cheaper then
            cost = cost * cheaper.Value
        end
    end

    return math.floor(cost + 1)
end
local UPGRADE_CHAIN = {
    ["Guardian"] = {
        "Deserted Armor",
        "Snowy Helmet",
        "Lava Knight",
        "Electrifying Sword",
        "Guardian Angel"
    },

    ["Laser Sniper"] = {
        "Pro Sniper",
        "Glowing Hat",
        "More Grip",
        "Heavy Clothes",
        "Frosted Lasers"
    },

    ["Wizard"] = {
        "Galaxy Potions",
        "Galaxy Spells",
        "Enhanced Galaxy Spells",
        "Galactic Staff"
    },

    ["Machinist"] = {
        "Faster Working",
        "Second Machine",
        "True Machinist",
        "Futurist"
    },

    ["Lava Mortar"] = {
        "Electric Hat",
        "Lightning Lava",
        "Electrically Trained",
        "Mega Zap Mortar"
    },

    -- 🔥 NEW

    ["Catalyst"] = {
        "Electrically Charged",
        "Void Lightning",
        "High Voltage",
        "Deadly Bolts"
    },

    ["Chainsaw Wielder"] = {
        "Soundproof",
        "Extra Protection",
        "Magic Chainsaw",
        "Magical Shredding"
    },

    ["Helicopter Kid"] = {
        "Stable Flying",
        "Bombs",
        "Toxic Bombs",
        "Death Heli"
    },

    ["Lava Sniper"] = {
        "Fire Shades",
        "Magma Hat",
        "Lava Coat",
        "Eruption Sniper",
        "Volcanic Lasers"
    ["Ray Blaster"] = {
        "Geometrical Suit",
        "Hacker",
        "Overclocked Core",
        "Digital Overdrive",
        "Quantum Blaster"
        }
    }
}

-- =====================
-- WAIT GOLD
-- =====================

local currentTarget = {}

local function waitGold(name, isUpgrade, towerInstance)
    currentTarget.name = name
    currentTarget.isUpgrade = isUpgrade

    while true do
        if bossDead then return false end

        local cost = getCost(name, isUpgrade, towerInstance)

        -- first check
        if gold.Value >= cost then

            -- double check
            task.wait(0.1)

            cost = getCost(name, isUpgrade, towerInstance)

            if gold.Value >= cost then
                return true
            end
        end

        if BUILD_DONE then
            goldLabel.Text = "Build Done"
            needLabel.Text = "Rebuilding..."
            costLabel.Text = "-"
            nextLabel.Text = "-"
        else
            goldLabel.Text = "Gold: "..gold.Value
            needLabel.Text = "Need: "..math.max(0, cost - gold.Value)
            costLabel.Text = "Cost: "..cost
            nextLabel.Text = "Next: "..name
        end
        task.wait(0.1)
    end
end

local function waitGoldRebuild(name, isUpgrade, towerInstance)
    while true do
        if bossDead then return false end

        local cost = getCost(name, isUpgrade, towerInstance)

        -- first check
        if gold.Value >= cost then

            -- double check
            task.wait(0.5)

            if bossDead then return false end

            local cost = getCost(name, isUpgrade, towerInstance)

            if gold.Value >= cost then
                return true
            end
        end

        task.wait(0.1)
    end
end

-- =====================
-- SPAWN
-- =====================
local function spawn(args)
    while REBUILDING and not rebuildingNow do task.wait() end
    if bossDead then return end
    return RS.Functions.SpawnTower:InvokeServer(unpack(args))
end

-- =====================
-- SNAPSHOT
-- =====================
local function readTower(t)
    local c = t:FindFirstChild("Class")
    local s = t:FindFirstChild("Skin")
    if not c or not s then return end

    local lv = t:FindFirstChild("Level")
    return {
        class = c.Value,
        skin = s.Value,
        level = lv and lv.Value or 1,
        pos = t:GetPivot().Position,
        cf = t:GetPivot()
    }
end

local function key(pos)
    return math.floor(pos.X*10).."_"..math.floor(pos.Y*10).."_"..math.floor(pos.Z*10)
end

local function snapshot()
    local snap = {}
    for _,t in ipairs(Towers:GetChildren()) do
        local d = readTower(t)
        if d then snap[key(d.pos)] = d end
    end
    return snap
end

local lastSnapshot = snapshot()
local debounce = {}
-- =====================
-- SPAWN BASE
-- =====================
local function spawnBase(data)
    local name = data.skin ~= "Default" and data.skin or data.class

    if not waitGoldRebuild(name, false) then return end

    if data.skin == "Default" then
        return spawn({data.class, data.cf, nil, data.class})
    else
        return spawn({data.skin, data.cf, nil, data.class, data.skin})
    end
end

-- =====================
-- UPGRADE
-- =====================
local function upgradeTower(tower, lv)
    local class = tower:FindFirstChild("Class").Value
    local chain = UPGRADE_CHAIN[class]

    if not chain then return nil end

    local upgradeName = chain[lv-1]
    if not upgradeName then return nil end

    -- waitGold
    if not waitGoldRebuild(upgradeName, true, tower) then
        return nil
    end

    local newTower = spawn({
        upgradeName,
        tower:GetPivot(),
        tower,
        class
    })

    -- 🔥 return khi success only
    if newTower then
        return newTower
    end

    return nil
end

-- =====================
-- REBUILD QUEUE
-- =====================
local function rebuild(data)
    for _,v in ipairs(rebuildQueue) do
        if (v.pos - data.pos).Magnitude < 1 then return end
    end
    table.insert(rebuildQueue, data)
end

-- =====================
-- WORKER (SEQUENTIAL FIX)
-- =====================
task.spawn(function()
    while true do
        task.wait(0.05)

        -- rebuild = ignore
        if rebuildingNow then continue end
        if #rebuildQueue == 0 then continue end

        rebuildingNow = true
        REBUILDING = true

        local data = table.remove(rebuildQueue, 1)

        if not data then
            rebuildingNow = false
            REBUILDING = false
            continue
        end
        rebuildState.active = true
        rebuildState.name = data.class
        rebuildState.level = data.level

        -- =====================
        -- SPAWN BASE
        local tower
        local tries = 0
        local maxTries = 3

        while tries < maxTries do
            tower = spawnBase(data)

            if tower then
                break
            end

            tries += 1
            task.wait(0.3)
        end

        
        if not tower then
            REBUILDING = false
            rebuildingNow = false
            rebuildState.active = false
            rebuildState.name = "-"
            rebuildState.level = 0
            continue
        end

        -- =====================
        -- UPGRADE LOOP
        -- =====================
        for lv = 2, data.level do
            if bossDead then break end
            if not tower or not tower.Parent then break end

            local upgraded = false

            while not upgraded do
                if bossDead then break end
                if not tower or not tower.Parent then break end

                local newTower = upgradeTower(tower, lv)

                if newTower then
                    tower = newTower
                    upgraded = true
                else
                    task.wait(0.3)
                end
            end
        end

        -- =====================
        -- DONE
        -- =====================
        REBUILDING = false
        rebuildingNow = false
        rebuildState.active = false
        rebuildState.name = "-"
        rebuildState.level = 0
    end
end)

-- =====================
-- DETECT DELETE
-- =====================
local function process()
    local now = snapshot()


    for k,old in pairs(lastSnapshot) do
        if isIgnored(old.pos) then continue end
        if not now[k] and not debounce[k] then
            debounce[k] = true

            task.delay(1,function()
                  rebuild(old)
            debounce[k] = nil
            end)
            end
        end
    lastSnapshot = now
end

RunService.Heartbeat:Connect(process)
task.wait(1)
lastSnapshot = snapshot()

-- =====================
-- SAFE WAIT
-- =====================
local function safeWait()
    while REBUILDING or rebuildingNow do task.wait() end
end

local function markUpgrade(cf)
    local pos = cf.Position

    table.insert(ignore, pos)

    task.delay(0.5, function()
        for i,v in ipairs(ignore) do
            if (v - pos).Magnitude < 0.1 then
                table.remove(ignore, i)
                break
            end
        end
    end)
end

-- =====================
-- BUILD FLOW (GIỮ NGUYÊN)
-- =====================
-- (PHẦN NÀY GIỮ NGUYÊN 100% CODE EM)
-- =====================
-- HELPER
-- =====================
local function getTowerAt(cf, class)
    for _,t in ipairs(Towers:GetChildren()) do
        local c = t:FindFirstChild("Class")
        if c and c.Value == class then
            if (t:GetPivot().Position - cf.Position).Magnitude < 2 then
                return t
            end
        end
    end
end

local function fixTower(tower, cf, class)
    if not tower or not tower.Parent then
        tower = getTowerAt(cf, class)
    end
    return tower
end

task.spawn(function()
    while true do
        if rebuildState.active then
            rebuildLabel.Text = "Rebuild: True (" ..
                rebuildState.name .. " | Lv" .. rebuildState.level .. ")"
        else
            rebuildLabel.Text = "Rebuild: False"
        end

        task.wait(0.1)
    end
end)



-- =====================
-- SAFE FIX HELPERS
-- =====================
local function safeFix(tower, cf, class)
    if not tower or not tower.Parent then
        tower = fixTower(nil, cf, class)
    end
    return tower
end
-- =====================
-- SAFE FIX HELPERS
-- =====================


-- =====================
-- AUTO SPAWN WRAPPER (fiX MARK)
-- =====================
local spawningLock = false

local function spawnTowerSafe(args)
    if spawningLock then return nil end
    spawningLock = true

    local old = args[3]
    local name = args[1]
    local isUpgrade = old ~= nil
    local cf = args[2]
    local class = args[4]

    local startTime = os.clock()
    local timeout = 60

    while true do
        if bossDead then
            spawningLock = false
            return nil
        end

        if os.clock() - startTime > timeout then
            warn("❌ Timeout spawn:", name)
            spawningLock = false
            return nil
        end

        local cost = getCost(name, isUpgrade, old)

        if gold.Value < cost then
            task.wait(0.1)
            continue
        end

        local before = gold.Value
        local t = spawn(args)

        -- 🔥 wait server sync (robust)
        local after = before
        local waited = 0

        while waited < 0.4 do
            task.wait(0.05)
            waited += 0.05
            after = gold.Value

            if after < before then break end
        end

        if after < before then
            -- ✔ SUCCESS

            -- 1. direct return nếu có
            if t and t.Parent then
                spawningLock = false
                return t
            end

            -- 2. tìm đúng tower vừa spawn (lọc kỹ hơn)
            local best
            for _,tower in ipairs(Towers:GetChildren()) do
                local c = tower:FindFirstChild("Class")

                if c and c.Value == class then
                    local dist = (tower:GetPivot().Position - cf.Position).Magnitude

                    if dist < 2 then
                        best = tower
                        break
                    end
                end
            end

            if best then
                spawningLock = false
                return best
            end

            -- 3. chờ thêm (server chậm)
            task.wait(0.2)
        end

        task.wait(0.1)
    end
end


-- =====================
-- 1. PRESENT DRAGON
-- =====================
safeWait()
waitGold("Present Dragon", false)
spawnTowerSafe({
    "Present Dragon",
    CFrame.new(-203.1414, 2.5045, -76.3242),
    nil,
    "Present Dragon"
})

-- =====================
-- 2. GUARDIAN (6)
-- =====================
local guardians = {}

local guardianPos = {
    CFrame.new(-216.72,3.28,-73.15),
    CFrame.new(-216.48,3.28,-70.53),
    CFrame.new(-220.70,3.28,-69.02),
    CFrame.new(-219.35,3.28,-73.22),
    CFrame.new(-216.49,3.28,-67.71),
    CFrame.new(-216.50,3.28,-64.95)
}

for i,cf in ipairs(guardianPos) do
    safeWait()
    waitGold("Guardian", false)
    guardians[i] = spawnTowerSafe({"Guardian", cf, nil, "Guardian"})
end

-- =====================
-- 3. RAY BLASTER LV3
-- =====================
safeWait()
waitGold("Geo Blaster", false)

local rb_cf = CFrame.new(-220.46,3.54,-66.26)
local rb = spawnTowerSafe({"Geo Blaster", rb_cf, nil, "Ray Blaster", "Geo Blaster"})
rb = safeFix(rb, rb_cf, "Ray Blaster")

if rb then
    waitGold("Geometrical Suit", true, rb)
    rb = spawnTowerSafe({"Geometrical Suit", rb:GetPivot(), rb, "Ray Blaster"})

    waitGold("Hacker", true, rb)
    rb = spawnTowerSafe({"Hacker", rb:GetPivot(), rb, "Ray Blaster"})
end

-- =====================
-- 4. ELECTRIC MORTAR (6)
-- =====================
local mortarPos = {
    CFrame.new(-217.03,3.48,-76.33),
    CFrame.new(-219.96,3.39,-75.92),
    CFrame.new(-214.37,3.45,-75.74),
    CFrame.new(-215.50,3.54,-78.49),
    CFrame.new(-218.54,3.39,-78.59),
    CFrame.new(-221.69,3.39,-78.07)
}

local mortars = {}

for i,cf in ipairs(mortarPos) do
    safeWait()
    waitGold("Electric Mortar", false)
    mortars[i] = spawnTowerSafe({"Electric Mortar", cf, nil, "Lava Mortar", "Electric Mortar"})
end

-- =====================
-- 5. GUARDIAN LV2
-- =====================
for i,g in ipairs(guardians) do
    safeWait()
    g = safeFix(g, guardianPos[i], "Guardian")

    if g then
        waitGold("Deserted Armor", true, g)
        guardians[i] = spawnTowerSafe({"Deserted Armor", g:GetPivot(), g, "Guardian"})
    end
end

-- =====================
-- 6. GUARDIAN LV3-4
-- =====================
for i,g in ipairs(guardians) do
    safeWait()
    g = safeFix(g, guardianPos[i], "Guardian")

    if g then
        waitGold("Snowy Helmet", true, g)
        g = spawnTowerSafe({"Snowy Helmet", g:GetPivot(), g, "Guardian"})

        waitGold("Lava Knight", true, g)
        guardians[i] = spawnTowerSafe({"Lava Knight", g:GetPivot(), g, "Guardian"})
    end
end

local sniperPos = {
    CFrame.new(-209.96,3.54,-77.19),
    CFrame.new(-207.22,3.39,-77.26),
    CFrame.new(-208.03,3.54,-80.03),
    CFrame.new(-210.82,3.45,-80.27),
    CFrame.new(-214.86,3.54,-80.93),
    CFrame.new(-218.45,3.39,-81.39)
}

local snipers = {}

-- =====================
-- PLACE ALL (delay 0.5s)
-- =====================
for i,cf in ipairs(sniperPos) do
    safeWait()
    waitGold("Lava Sniper", false)

    snipers[i] = spawnTowerSafe({
        "Lava Sniper",
        cf,
        nil,
        "Laser Sniper",
        "Lava Sniper"
    })

    task.wait(0.5)
end

-- =====================
-- UPGRADE ALL
-- =====================
for i,s in ipairs(snipers) do
    safeWait()
    s = safeFix(s, sniperPos[i], "Laser Sniper")

    if s then
        waitGold("Fire Shades", true, s)
        s = spawnTowerSafe({"Fire Shades", s:GetPivot(), s, "Laser Sniper"})

        waitGold("Magma Hat", true, s)
        snipers[i] = spawnTowerSafe({"Magma Hat", s:GetPivot(), s, "Laser Sniper"})
    end
end

-- =====================
-- 7. WIZARD (2 FULL)
-- =====================
local wizardPos = {
    CFrame.new(-213.06,3.39,-72.91),
    CFrame.new(-209.74,3.39,-73.72)
}

local wizards = {}

-- PLACE FIRST
for i,cf in ipairs(wizardPos) do
    safeWait()
    waitGold("Galaxy Wizard", false)

    wizards[i] = spawnTowerSafe({"Galaxy Wizard", cf, nil, "Wizard", "Galaxy Wizard"})
    task.wait(0.5)
end

-- UPGRADE
for i,w in ipairs(wizards) do
    safeWait()
    w = safeFix(w, wizardPos[i], "Wizard")

    if w then
        waitGold("Galaxy Potions", true, w)
        w = spawnTowerSafe({"Galaxy Potions", w:GetPivot(), w, "Wizard"})

        waitGold("Galaxy Spells", true, w)
        w = spawnTowerSafe({"Galaxy Spells", w:GetPivot(), w, "Wizard"})

        waitGold("Enhanced Galaxy Spells", true, w)
        w = spawnTowerSafe({"Enhanced Galaxy Spells", w:GetPivot(), w, "Wizard"})

        waitGold("Galactic Staff", true, w)
        wizards[i] = spawnTowerSafe({"Galactic Staff", w:GetPivot(), w, "Wizard"})
    end
end

-- =====================
-- 8. MACHINIST
-- =====================

safeWait()
waitGold("Machinist", false)

local m_cf = CFrame.new(-212.6984, 3.3995, -69.1346) * CFrame.Angles(0, -0.0564620979, 0)

local m = spawnTowerSafe({
    "Machinist",
    m_cf,
    nil,
    "Machinist"
})

m = safeFix(m, m_cf, "Machinist")

if m then
    waitGold("Faster Working", true, m)
    m = spawnTowerSafe({"Faster Working", m:GetPivot(), m, "Machinist"})

    waitGold("Second Machine", true, m)
    m = spawnTowerSafe({"Second Machine", m:GetPivot(), m, "Machinist"})

    waitGold("True Machinist", true, m)
    m = spawnTowerSafe({"True Machinist", m:GetPivot(), m, "Machinist"})

    waitGold("Futurist", true, m)
    m = spawnTowerSafe({"Futurist", m:GetPivot(), m, "Machinist"})
end

-- =====================
-- GUARDIAN FULL LV6
-- =====================

-- LV5
for i,g in ipairs(guardians) do
    safeWait()
    g = safeFix(g, guardianPos[i], "Guardian")

    if g then
        waitGold("Electrifying Sword", true, g)
        g = spawnTowerSafe({
            "Electrifying Sword",
            g:GetPivot(),
            g,
            "Guardian"
        })

        guardians[i] = g
    end
end

-- LV6 (FINAL)
for i,g in ipairs(guardians) do
    safeWait()
    g = safeFix(g, guardianPos[i], "Guardian")

    if g then
        waitGold("Guardian Angel", true, g)
        guardians[i] = spawnTowerSafe({
            "Guardian Angel",
            g:GetPivot(),
            g,
            "Guardian"
        })
    end
end


-- =====================
-- SNIPER FULL LV6
-- =====================
for i,s in ipairs(snipers) do
    safeWait()
    s = safeFix(s, sniperPos[i], "Laser Sniper")

    if s then
        waitGold("Lava Coat", true, s)
        s = spawnTowerSafe({"Lava Coat", s:GetPivot(), s, "Laser Sniper"})

        waitGold("Eruption Sniper", true, s)
        s = spawnTowerSafe({"Eruption Sniper", s:GetPivot(), s, "Laser Sniper"})

        waitGold("Volcanic Lasers", true, s)
        snipers[i] = spawnTowerSafe({"Volcanic Lasers", s:GetPivot(), s, "Laser Sniper"})
    end
end

-- =====================
-- MORTAR FULL LV5
-- =====================
for i,m in ipairs(mortars) do
    safeWait()
    m = safeFix(m, mortarPos[i], "Lava Mortar")

    if m then
        waitGold("Electric Hat", true, m)
        m = spawnTowerSafe({"Electric Hat", m:GetPivot(), m, "Lava Mortar"})

        waitGold("Lightning Lava", true, m)
        m = spawnTowerSafe({"Lightning Lava", m:GetPivot(), m, "Lava Mortar"})

        waitGold("Electrically Trained", true, m)
        m = spawnTowerSafe({"Electrically Trained", m:GetPivot(), m, "Lava Mortar"})

        waitGold("Mega Zap Mortar", true, m)
        mortars[i] = spawnTowerSafe({"Mega Zap Mortar", m:GetPivot(), m, "Lava Mortar"})
    end
end


-- =====================
-- DRONE PILOT (5 → LV5)
-- =====================

local drones = {}

-- PLACE ALL
for i,cf in ipairs(dronePos) do
    safeWait()
    waitGold("Helicopter Kid", false)

    drones[i] = spawnTowerSafe({
        "Helicopter Kid",
        cf,
        nil,
        "Drone Pilot",
        "Helicopter Kid"
    })

    task.wait(0.5)
end

-- UPGRADE
for i,d in ipairs(drones) do
    safeWait()
    d = safeFix(d, dronePos[i], "Drone Pilot")

    if d then
        waitGold("Stable Flying", true, d)
        d = spawnTowerSafe({"Stable Flying", d:GetPivot(), d, "Drone Pilot"})

        waitGold("Bombs", true, d)
        d = spawnTowerSafe({"Bombs", d:GetPivot(), d, "Drone Pilot"})

        waitGold("Toxic Bombs", true, d)
        d = spawnTowerSafe({"Toxic Bombs", d:GetPivot(), d, "Drone Pilot"})

        waitGold("Death Heli", true, d)
        drones[i] = spawnTowerSafe({"Death Heli", d:GetPivot(), d, "Drone Pilot"})
    end
end

-- =====================
-- CHAINSAW (4 → LV5)
-- =====================

local chainsaws = {}

local chainsawPos = {
    CFrame.new(-220.8536, 3.2845, -63.5424) * CFrame.Angles(0, 0, 0),
    CFrame.new(-220.8257, 3.2845, -60.9326) * CFrame.Angles(0, 0, 0),
    CFrame.new(-220.8209, 3.2845, -57.8157) * CFrame.Angles(0, 0, 0),
    CFrame.new(-218.0222, 3.2845, -56.7653)
        * CFrame.Angles(0, 5.018965324162116e-32, 1.148205388565229e-24)
}

-- PLACE ALL
for i,cf in ipairs(chainsawPos) do
    safeWait()
    waitGold("ChainsawWielder", false)

    chainsaws[i] = spawnTowerSafe({
        "ChainsawWielder",
        cf, -- ✅ đã có cả rotation
        nil,
        "Chainsaw Wielder"
    })

    task.wait(0.5)
end

-- UPGRADE
for i,c in ipairs(chainsaws) do
    safeWait()
    c = safeFix(c, chainsawPos[i], "Chainsaw Wielder") -- ✅ dùng lại đúng CFrame

    if c then
        waitGold("Soundproof", true, c)
        c = spawnTowerSafe({"Soundproof", c:GetPivot(), c, "Chainsaw Wielder"})

        waitGold("Extra Protection", true, c)
        c = spawnTowerSafe({"Extra Protection", c:GetPivot(), c, "Chainsaw Wielder"})

        waitGold("Magic Chainsaw", true, c)
        c = spawnTowerSafe({"Magic Chainsaw", c:GetPivot(), c, "Chainsaw Wielder"})

        waitGold("Magical Shredding", true, c)
        chainsaws[i] = spawnTowerSafe({"Magical Shredding", c:GetPivot(), c, "Chainsaw Wielder"})
    end
end

local catalystPos = {
    CFrame.new(-216.8484,3.2845,-52.3482),
    CFrame.new(-212.6117,3.3995,-64.7285),
    CFrame.new(-209.4589,3.2845,-56.9277)
}

local catalysts = {}

-- PLACE ALL
for i,cf in ipairs(catalystPos) do
    safeWait()
    waitGold("Catalyst", false)

    catalysts[i] = spawnTowerSafe({"Catalyst", cf, nil, "Catalyst"})
    task.wait(0.5)
end

-- UPGRADE
for i,c in ipairs(catalysts) do
    safeWait()
    c = safeFix(c, catalystPos[i], "Catalyst")

    if c then
        waitGold("Electrically Charged", true, c)
        c = spawnTowerSafe({"Electrically Charged", c:GetPivot(), c, "Catalyst"})

        waitGold("Void Lightning", true, c)
        c = spawnTowerSafe({"Void Lightning", c:GetPivot(), c, "Catalyst"})

        waitGold("High Voltage", true, c)
        c = spawnTowerSafe({"High Voltage", c:GetPivot(), c, "Catalyst"})

        waitGold("Deadly Bolts", true, c)
        catalysts[i] = spawnTowerSafe({"Deadly Bolts", c:GetPivot(), c, "Catalyst"})
    end
end
-- =====================
-- BUILD FINISHED
-- =====================
BUILD_DONE = true

goldLabel.Text = "Build Done"
needLabel.Text = "Rebuilding..."
costLabel.Text = "-"
nextLabel.Text = "-"

print("✅ BUILD DONE - REBUILD MODE")

