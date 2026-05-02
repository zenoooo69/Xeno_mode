-- =====================
-- INIT
-- =====================
local RS = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local Towers = workspace:WaitForChild("Towers")

local bossDead = false

-- =====================
-- AUTO SCAN BASE COST
-- =====================
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

-- =====================
-- CUSTOM COST (OVERRIDE)
-- =====================
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
    ["Electric Mortar"] = 8650,
    ["Electric Hat"] = 8500,
    ["Lightning Lava"] = 36000,
    ["Electrically Trained"] = 60000,
    ["Mega Zap Mortar"] = 146000,

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

    -- Machinist
    ["Machinist"] = 1000,
    ["Faster Working"] = 1300,
    ["Second Machine"] = 3200,
    ["True Machinist"] = 9000,
    ["Futurist"] = 19250,

    -- Ray (override nếu game đổi tên)
    ["Geo Blaster"] = 2875,
    ["Geometrical Suit"] = 1200,
    ["Hacker"] = 3250,
}

-- =====================
-- COST LOGIC
-- =====================

local effects = workspace:WaitForChild("Info"):WaitForChild("TowerEffects")
local placeMulti = effects:WaitForChild("PlacingTowerMultiplier")
local upgradeMulti = effects:WaitForChild("UpgradePriceMultiplier")

local function getCost(name, isUpgrade, tower)
    local base = CUSTOM_COST[name] or BASE_COST[name] or 0
    local cost = base * (isUpgrade and upgradeMulti.Value or placeMulti.Value)

    -- 🔥 Cheaper Upgrade (Machinist)
    if isUpgrade and tower then
        local cfg = tower:FindFirstChild("Config")
        if cfg then
            local cheaper = cfg:FindFirstChild("CheaperUpgrades")
            if cheaper then
                cost *= cheaper.Value
            end
        end
    end

    return math.floor(cost + 1)
end

-- =====================
-- GOLD SYSTEM
-- =====================

-- =====================
-- GUI TRACK GOLD
-- =====================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmUI"
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 100)
frame.Position = UDim2.new(0, 100, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,20)
title.Text = "Auto Farm"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Parent = frame

local goldLabel = Instance.new("TextLabel")
goldLabel.Position = UDim2.new(0,0,0,25)
goldLabel.Size = UDim2.new(1,0,0,20)
goldLabel.BackgroundTransparency = 1
goldLabel.TextColor3 = Color3.fromRGB(0,255,0)
goldLabel.Text = "Gold: 0"
goldLabel.Parent = frame

local needLabel = Instance.new("TextLabel")
needLabel.Position = UDim2.new(0,0,0,50)
needLabel.Size = UDim2.new(1,0,0,20)
needLabel.BackgroundTransparency = 1
needLabel.TextColor3 = Color3.fromRGB(255,100,100)
needLabel.Text = "Need: 0"
needLabel.Parent = frame

local nextLabel = Instance.new("TextLabel")
nextLabel.Position = UDim2.new(0,0,0,75)
nextLabel.Size = UDim2.new(1,0,0,20)
nextLabel.BackgroundTransparency = 1
nextLabel.TextColor3 = Color3.new(1,1,1)
nextLabel.Text = "Next: None"
nextLabel.Parent = frame
local gold = player:WaitForChild("leaderstats"):WaitForChild("Gold")

local currentTarget = {
    name = nil,
    isUpgrade = false
}


local function waitGold(name, isUpgrade, tower)
    currentTarget.name = name
    currentTarget.isUpgrade = isUpgrade

    local cost = getCost(name, isUpgrade, tower)
    if cost == 0 then
        warn("Skip (no cost):", name)
        return
    end

    while gold.Value < cost do
        if bossDead then return end

        local need = cost - gold.Value

        goldLabel.Text = "Gold: "..gold.Value
        needLabel.Text = "Need: "..need
        nextLabel.Text = "Next: "..name

        gold:GetPropertyChangedSignal("Value"):Wait()
        cost = getCost(name, isUpgrade, tower)
    end

    -- đủ tiền
    goldLabel.Text = "Gold: "..gold.Value
    needLabel.Text = "Need: 0"
end

local function spawn(args)
    if bossDead then return end
    return RS.Functions.SpawnTower:InvokeServer(unpack(args))
end

-- =====================
-- BOSS DETECT
-- =====================
task.spawn(function()
    local mobs = workspace:WaitForChild("Mobs")
    local bossName = "EmperorOfShapes"

    mobs:WaitForChild(bossName)

    while mobs:FindFirstChild(bossName) do
        task.wait(1)
    end

    bossDead = true
    task.wait(5)
    RS.Events.ExitGame:FireServer()
end)

-- =====================
-- VOTE
-- =====================
RS.Events.VoteForMap:FireServer("Distorted Lands")
task.wait(1)
RS.Events.VoteForMap:FireServer("Ready")

-- =====================
-- PREVIEW CONFIG
-- =====================
local PREVIEW_SIZE = 3 / 3 -- chỉnh size tại đây
local PREVIEW_HEIGHT = 0.15

local previewFolder = Instance.new("Folder")
previewFolder.Name = "PreviewFolder"
previewFolder.Parent = workspace

-- =====================
-- CREATE PREVIEW
-- =====================
local function showPreview(cf, color)
    local p = Instance.new("Part")
    p.Size = Vector3.new(PREVIEW_SIZE, PREVIEW_HEIGHT, PREVIEW_SIZE)
    p.Anchored = true
    p.CanCollide = false
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Transparency = 0.25
    p.CFrame = cf
    p.Name = "PreviewPart"
    p.Parent = previewFolder
end

-- =====================
-- CLEAR PREVIEW
-- =====================
local function clearPreview()
    if previewFolder then
        previewFolder:Destroy()
    end
end

local function previewAll()

    -- =====================
    -- 1️⃣ Present Dragon
    -- =====================
    showPreview(CFrame.new(-208.66, -6.01, -77.53), Color3.fromRGB(255,255,255))

    -- =====================
    -- 2️⃣ Chainsaw đầu
    -- =====================
    local chainsawPos = {
        CFrame.new(-208.38, -5.21, -102.77),
        CFrame.new(-203.68, -5.21, -109.53),
        CFrame.new(-205.74, -5.21, -102.67),
        CFrame.new(-206.39, -5.21, -109.26)
    }
    for _,v in ipairs(chainsawPos) do
        showPreview(v, Color3.fromRGB(255,100,100))
    end

    -- =====================
    -- 3️⃣ Sniper đầu
    -- =====================
    showPreview(CFrame.new(-214.71, -4.97, -47.92), Color3.fromRGB(0,255,0))

    -- =====================
    -- 5️⃣ Medic base
    -- =====================
    local medicBasePos = {
        CFrame.new(-217.14, -5.21, -74.73),
        CFrame.new(-214.59, -5.21, -74.78),
        CFrame.new(-211.94, -5.21, -74.37)
    }

    -- =====================
    -- 6️⃣ Sniper chuẩn
    -- =====================
    local sniperPos = {
        CFrame.new(-211.9716339111328, -4.974852561950684, -47.73666763305664) * 
        CFrame.Angles(-9.981548600990209e-07, 1.5653481483459473, 0.0000010432387398395804),

        CFrame.new(-212.0504150390625, -4.949558258056641, -51.26875686645508) * 
        CFrame.Angles(-3.1415927410125732, 1.428468108177185, 3.141592502593994),

        CFrame.new(-214.7398223876953, -4.974852561950684, -53.378143310546875) * 
        CFrame.Angles(3.1415927410125732, -0.1149868592619896, 3.1415927410125732),

        CFrame.new(-214.6719207763672, -4.974852561950684, -50.776153564453125) * 
        CFrame.Angles(3.1415927410125732, -1.5707963705062866, 3.1415927410125732)
    }

    for _,v in ipairs(sniperPos) do
        showPreview(v, Color3.fromRGB(0,255,0))
    end

    -- =====================
    -- 8️⃣ Chainsaw mid
    -- =====================
    local newChainsawPos = {
        CFrame.new(-214.57, -5.21, -56.58),
        CFrame.new(-217.22, -5.23, -56.03),
        CFrame.new(-219.92, -5.21, -56.17),
        CFrame.new(-218.72, -5.21, -58.86)
    }
    for _,v in ipairs(newChainsawPos) do
        showPreview(v, Color3.fromRGB(255,150,0))
    end

    -- =====================
    -- 9 + 11 Wizard
    -- =====================
    showPreview(CFrame.new(-211.69, -4.96, -41.97), Color3.fromRGB(200,0,255))
    showPreview(CFrame.new(-217.42210388183594, -4.998970031738281, -50.7840690612793), Color3.fromRGB(200,0,255))

    -- =====================
    -- 🔵 Catalyst
    -- =====================
    local catalystPos = {
        CFrame.new(-214.3157958984375, -4.949677467346191, -44.66935729980469) * CFrame.Angles(-0, -0.2703188359737396, -0),
        CFrame.new(-219.62069702148438, -4.989323616027832, -44.87630844116211) * CFrame.Angles(-3.1415927410125732, -0.924589216709137, -3.1415927410125732),
        CFrame.new(-228.43861389160156, -4.998970031738281, -67.7090835571289) * CFrame.Angles(-3.1415927410125732, -0.07117530703544617, -3.1415927410125732)
    }
    for _,v in ipairs(catalystPos) do
        showPreview(v, Color3.fromRGB(0,255,255))
    end

    -- =====================
    -- 🟡 Drone
    -- =====================
    local dronePos = {
        CFrame.new(-220.19866943359375, -4.969793319702148, -53.207252502441406) * CFrame.Angles(-3.1415927410125732, -1.2013239860534668, -3.1415927410125732),
        CFrame.new(-220.01284790039062, -4.984498977661133, -49.68538284301758) * CFrame.Angles(-3.1415927410125732, -0.8221572041511536, -3.1415927410125732),
        CFrame.new(-219.8442840576172, -6.828354358673096, -47.27887725830078) * CFrame.Angles(2.6637938022613525, -1.5291203260421753, 2.685743808746338),
        CFrame.new(-218.71974182128906, -4.817047595977783, -41.646358489990234) * CFrame.Angles(0.024007374420762062, 0.0253317691385746, 0.017472881823778152),
        CFrame.new(-215.7358856201172, -4.825963020324707, -41.673179626464844) * CFrame.Angles(0.022721154615283012, -0.18468348681926727, 0.021006934344768524)
    }
    for _,v in ipairs(dronePos) do
        showPreview(v, Color3.fromRGB(255,255,0))
    end

    -- =====================
    -- 💉 MEDIC FULL (ĐỦ NHƯ BUILD)
    -- =====================
    local medicPosExtra = {
        CFrame.new(-210.82, -5.21, -70.74),
        CFrame.new(-210.78, -5.21, -68.23),
        CFrame.new(-217.43, -5.21, -72.10),
        CFrame.new(-210.60, -5.21, -65.63),
        CFrame.new(-208.05, -5.21, -70.67),
        CFrame.new(-209.23, -5.21, -74.50),
        CFrame.new(-207.79, -5.23, -67.83)
    }

    local all = {}

    for _,v in ipairs(medicBasePos) do table.insert(all,v) end
    for _,v in ipairs(medicPosExtra) do table.insert(all,v) end

    -- tầng 1
    for _,v in ipairs(all) do
        showPreview(v, Color3.fromRGB(0,170,255))
    end

    -- tầng 2 (10 con)
    for i = 1,10 do
        local pos = all[i] + Vector3.new(0,4,0)
        showPreview(pos, Color3.fromRGB(150,255,255))
    end

end
-- =====================
-- =====================
-- BUILD FLOW (FIX MACHINIST)
-- =====================

previewAll()

-- =====================
-- 1️⃣ PRESENT DRAGON
-- =====================
waitGold("Present Dragon", false)
spawn({
    "Present Dragon",
    CFrame.new(-208.66, -6.01, -77.53),
    nil,
    "Present Dragon"
})

-- =====================
-- 2️⃣ 4 CHAINSAW
-- =====================
local chainsawPos = {
    CFrame.new(-208.38, -5.21, -102.77),
    CFrame.new(-203.68, -5.21, -109.53),
    CFrame.new(-205.74, -5.21, -102.67),
    CFrame.new(-206.39, -5.21, -109.26)
}

local chainsaws = {}

for i, pos in ipairs(chainsawPos) do
    waitGold("Chainsaw Wielder", false)
    local c = spawn({"Chainsaw Wielder", pos, nil, "Chainsaw Wielder"})
    chainsaws[i] = c
end

-- =====================
-- 3️⃣ 1 SNIPER → LV2
-- =====================
waitGold("Lava Sniper", false)
local sniper1 = spawn({
    "Lava Sniper",
    CFrame.new(-214.71, -4.97, -47.92),
    nil,
    "Laser Sniper",
    "Lava Sniper"
})

waitGold("Fire Shades", true, sniper1)
sniper1 = spawn({"Fire Shades", sniper1:GetPivot(), sniper1, "Laser Sniper"})

-- =====================
-- 4️⃣ 2 CHAINSAW → LV2
-- =====================
for i = 1, 2 do
    local c = chainsaws[i]

    waitGold("Soundproof", true, c)
    c = spawn({"Soundproof", c:GetPivot(), c, "Chainsaw Wielder"})

    chainsaws[i] = c
end

-- =====================
-- 5️⃣ 3 MEDIC
-- =====================
local medicBasePos = {
    CFrame.new(-217.14, -5.21, -74.73),
    CFrame.new(-214.59, -5.21, -74.78),
    CFrame.new(-211.94, -5.21, -74.37)
}

local medics = {}

for i, pos in ipairs(medicBasePos) do
    waitGold("Medic", false)
    local m = spawn({"Medic", pos, nil, "Medic"})
    medics[i] = m
end

-- =====================
-- 6️⃣ 4 SNIPER → LV2

local sniperPos = {
    CFrame.new(-211.9716339111328, -4.974852561950684, -47.73666763305664) * 
    CFrame.Angles(-9.981548600990209e-07, 1.5653481483459473, 0.0000010432387398395804),

    CFrame.new(-212.0504150390625, -4.949558258056641, -51.26875686645508) * 
    CFrame.Angles(-3.1415927410125732, 1.428468108177185, 3.141592502593994),

    CFrame.new(-214.7398223876953, -4.974852561950684, -53.378143310546875) * 
    CFrame.Angles(3.1415927410125732, -0.1149868592619896, 3.1415927410125732),
    CFrame.new(-214.6719207763672, -4.974852561950684, -50.776153564453125) * 
    CFrame.Angles(3.1415927410125732, -1.5707963705062866, 3.1415927410125732)
}

local snipers = {}

for i, pos in ipairs(sniperPos) do
    waitGold("Lava Sniper", false)
    local s = spawn({"Lava Sniper", pos, nil, "Laser Sniper", "Lava Sniper"})

    waitGold("Fire Shades", true, s)
    s = spawn({"Fire Shades", s:GetPivot(), s, "Laser Sniper"})

    snipers[i] = s
end

-- =====================
-- 7️⃣ SELL ALL CHAINSAW
-- =====================
for _, t in ipairs(Towers:GetChildren()) do
    if t.Name == "Chainsaw Wielder" or t.Name == "Soundproof" then
        RS.Functions.SellTower:InvokeServer(t)
    end
end

-- =====================
-- 8️⃣ PLACE 4 CHAINSAW → LV2
-- =====================
local newChainsawPos = {
    CFrame.new(-214.57, -5.21, -56.58),
    CFrame.new(-217.22, -5.23, -56.03),
    CFrame.new(-219.92, -5.21, -56.17),
    CFrame.new(-218.72, -5.21, -58.86)
}

chainsaws = {}

for i, pos in ipairs(newChainsawPos) do
    waitGold("Chainsaw Wielder", false)
    local c = spawn({"Chainsaw Wielder", pos, nil, "Chainsaw Wielder"})

    waitGold("Soundproof", true, c)
    c = spawn({"Soundproof", c:GetPivot(), c, "Chainsaw Wielder"})

    chainsaws[i] = c
end

-- =====================
-- 9️⃣ WIZARD LV5
-- =====================
waitGold("Galaxy Wizard", false)
local w = spawn({
    "Galaxy Wizard",
    CFrame.new(-211.69, -4.96, -41.97),
    nil,
    "Wizard",
    "Galaxy Wizard"
})

waitGold("Galaxy Potions", true, w)
w = spawn({"Galaxy Potions", w:GetPivot(), w, "Wizard"})

waitGold("Galaxy Spells", true, w)
w = spawn({"Galaxy Spells", w:GetPivot(), w, "Wizard"})

waitGold("Enhanced Galaxy Spells", true, w)
w = spawn({"Enhanced Galaxy Spells", w:GetPivot(), w, "Wizard"})

waitGold("Galactic Staff", true, w)
w = spawn({"Galactic Staff", w:GetPivot(), w, "Wizard"})

-- =====================
-- 🔟 CHAINSAW → LV3
-- =====================
for i, c in ipairs(chainsaws) do
    waitGold("Extra Protection", true, c)
    c = spawn({"Extra Protection", c:GetPivot(), c, "Chainsaw Wielder"})
    chainsaws[i] = c
end

-- =====================
-- 11️⃣ WIZARD 2
-- =====================
waitGold("Galaxy Wizard", false)
local w2 = spawn({
    "Galaxy Wizard",
    CFrame.new(-217.42210388183594, -4.998970031738281, -50.7840690612793),
    nil,
    "Wizard",
    "Galaxy Wizard"
})

waitGold("Galaxy Potions", true, w2)
w2 = spawn({"Galaxy Potions", w2:GetPivot(), w2, "Wizard"})

waitGold("Galaxy Spells", true, w2)
w2 = spawn({"Galaxy Spells", w2:GetPivot(), w2, "Wizard"})

waitGold("Enhanced Galaxy Spells", true, w2)
w2 = spawn({"Enhanced Galaxy Spells", w2:GetPivot(), w2, "Wizard"})

waitGold("Galactic Staff", true, w2)
w2 = spawn({"Galactic Staff", w2:GetPivot(), w2, "Wizard"})

-- =====================
-- 12️⃣ MEDIC → LV5 (3 CON CŨ)
-- =====================
for i, m in ipairs(medics) do
    waitGold("Gun Training", true, m)
    m = spawn({"Gun Training", m:GetPivot(), m, "Medic"})

    waitGold("Army Medic", true, m)
    m = spawn({"Army Medic", m:GetPivot(), m, "Medic"})

    waitGold("Sharp Shooter", true, m)
    m = spawn({"Sharp Shooter", m:GetPivot(), m, "Medic"})

    waitGold("Healing Radar", true, m)
    m = spawn({"Healing Radar", m:GetPivot(), m, "Medic"})

    medics[i] = m
end

-- =====================
-- 13️⃣ 7 MEDIC → LV5
-- =====================
local medicPosExtra = {
    CFrame.new(-210.82, -5.21, -70.74),
    CFrame.new(-210.78, -5.21, -68.23),
    CFrame.new(-217.43, -5.21, -72.10),
    CFrame.new(-210.60, -5.21, -65.63),
    CFrame.new(-208.05, -5.21, -70.67),
    CFrame.new(-209.23, -5.21, -74.50),
    CFrame.new(-207.79, -5.23, -67.83)
}

local medicAll = {}

for _, m in ipairs(medics) do
    table.insert(medicAll, m)
end

for _, pos in ipairs(medicPosExtra) do
    waitGold("Medic", false)
    local m = spawn({"Medic", pos, nil, "Medic"})

    waitGold("Gun Training", true, m)
    m = spawn({"Gun Training", m:GetPivot(), m, "Medic"})

    waitGold("Army Medic", true, m)
    m = spawn({"Army Medic", m:GetPivot(), m, "Medic"})

    waitGold("Sharp Shooter", true, m)
    m = spawn({"Sharp Shooter", m:GetPivot(), m, "Medic"})

    waitGold("Healing Radar", true, m)
    m = spawn({"Healing Radar", m:GetPivot(), m, "Medic"})

    table.insert(medicAll, m)
end

-- =====================
-- GỘP POS
-- =====================
local allMedicPos = {}

for _, v in ipairs(medicPosExtra) do
    table.insert(allMedicPos, v)
end

for _, v in ipairs(medicBasePos) do
    table.insert(allMedicPos, v)
end

-- =====================
-- 14️⃣ 10 MEDIC (Y +4)
-- =====================
for i = 1, 10 do
    local base = allMedicPos[i]
    local newPos = base + Vector3.new(0, 4, 0)

    waitGold("Medic", false)
    local m = spawn({"Medic", newPos, nil, "Medic"})

    waitGold("Gun Training", true, m)
    m = spawn({"Gun Training", m:GetPivot(), m, "Medic"})

    waitGold("Army Medic", true, m)
    m = spawn({"Army Medic", m:GetPivot(), m, "Medic"})

    waitGold("Sharp Shooter", true, m)
    m = spawn({"Sharp Shooter", m:GetPivot(), m, "Medic"})

    waitGold("Healing Radar", true, m)
    m = spawn({"Healing Radar", m:GetPivot(), m, "Medic"})
end

-- =====================
-- 15️⃣ SNIPER → LV6
-- =====================
for _, s in ipairs(Towers:GetChildren()) do
    if s.Name == "Lava Sniper" or s.Name == "Fire Shades" then

        waitGold("Magma Hat", true, s)
        s = spawn({"Magma Hat", s:GetPivot(), s, "Laser Sniper"})

        waitGold("Lava Coat", true, s)
        s = spawn({"Lava Coat", s:GetPivot(), s, "Laser Sniper"})

        waitGold("Eruption Sniper", true, s)
        s = spawn({"Eruption Sniper", s:GetPivot(), s, "Laser Sniper"})

        waitGold("Volcanic Lasers", true, s)
        s = spawn({"Volcanic Lasers", s:GetPivot(), s, "Laser Sniper"})
    end
end

-- =====================
-- 16️⃣ CHAINSAW → LV5
-- =====================
for i, c in ipairs(chainsaws) do
    waitGold("Magic Chainsaw", true, c)
    c = spawn({"Magic Chainsaw", c:GetPivot(), c, "Chainsaw Wielder"})

    waitGold("Magical Shredding", true, c)
    c = spawn({"Magical Shredding", c:GetPivot(), c, "Chainsaw Wielder"})

    chainsaws[i] = c
end

-- =====================
-- 17️⃣ 4 SOUL SPEAKER (END GAME)
-- =====================

local soulPos = {
    CFrame.new(-226.72000122070312, -5.214851379394531, -58.34860610961914),
    CFrame.new(-229.41781616210938, -5.214851379394531, -58.35725021362305),
    CFrame.new(-202.73655700683594, -5.214851379394531, -49.38220977783203),
    CFrame.new(-205.76669311523438, -5.214851379394531, -49.38094711303711)
}

for i, pos in ipairs(soulPos) do
    if bossDead then break end

    -- chờ đủ tiền (nếu muốn an toàn)
    waitGold("Soul Speaker", false)

    spawn({
        "Soul Speaker",
        pos,
        nil,
        "Soul Speaker"
    })

    task.wait(9) -- delay 9s mỗi con
end

-- =====================
-- 18️⃣ 3 CATALYST → LV5
-- =====================

local catalystPos = {
    CFrame.new(-214.3157958984375, -4.949677467346191, -44.66935729980469) * CFrame.Angles(-0, -0.2703188359737396, -0),
    CFrame.new(-219.62069702148438, -4.989323616027832, -44.87630844116211) * CFrame.Angles(-3.1415927410125732, -0.924589216709137, -3.1415927410125732),
    CFrame.new(-228.43861389160156, -4.998970031738281, -67.7090835571289) * CFrame.Angles(-3.1415927410125732, -0.07117530703544617, -3.1415927410125732)
}

local catalysts = {}

for i, pos in ipairs(catalystPos) do
    waitGold("Catalyst", false)
    local c = spawn({"Catalyst", pos, nil, "Catalyst"})

    waitGold("Electrically Charged", true, c)
    c = spawn({"Electrically Charged", c:GetPivot(), c, "Catalyst"})

    waitGold("VoidLightning", true, c)
    c = spawn({"VoidLightning", c:GetPivot(), c, "Catalyst"})

    waitGold("High Voltage", true, c)
    c = spawn({"High Voltage", c:GetPivot(), c, "Catalyst"})

    waitGold("Deadly Bolts", true, c)
    c = spawn({"Deadly Bolts", c:GetPivot(), c, "Catalyst"})

    catalysts[i] = c
end


-- =====================
-- 19️⃣ 5 DRONE → LV5
-- =====================

local dronePos = {
    CFrame.new(-220.19866943359375, -4.969793319702148, -53.207252502441406) * CFrame.Angles(-3.1415927410125732, -1.2013239860534668, -3.1415927410125732),
    CFrame.new(-220.01284790039062, -4.984498977661133, -49.68538284301758) * CFrame.Angles(-3.1415927410125732, -0.8221572041511536, -3.1415927410125732),
    CFrame.new(-219.8442840576172, -6.828354358673096, -47.27887725830078) * CFrame.Angles(2.6637938022613525, -1.5291203260421753, 2.685743808746338),
    CFrame.new(-218.71974182128906, -4.817047595977783, -41.646358489990234) * CFrame.Angles(0.024007374420762062, 0.0253317691385746, 0.017472881823778152),
    CFrame.new(-215.7358856201172, -4.825963020324707, -41.673179626464844) * CFrame.Angles(0.022721154615283012, -0.18468348681926727, 0.021006934344768524)
}

local drones = {}

for i, pos in ipairs(dronePos) do
    waitGold("Helicopter Kid", false)
    local d = spawn({"Helicopter Kid", pos, nil, "Drone Pilot", "Helicopter Kid"})

    waitGold("Stable Flying", true, d)
    d = spawn({"Stable Flying", d:GetPivot(), d, "Drone Pilot"})

    waitGold("Bombs", true, d)
    d = spawn({"Bombs", d:GetPivot(), d, "Drone Pilot"})

    waitGold("Toxic Bombs", true, d)
    d = spawn({"Toxic Bombs", d:GetPivot(), d, "Drone Pilot"})

    waitGold("Death Heli", true, d)
    d = spawn({"Death Heli", d:GetPivot(), d, "Drone Pilot"})

    drones[i] = d
end

clearPreview()
