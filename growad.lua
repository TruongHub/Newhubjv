```lua
-- [[ Grow a Garden - Hỗ Trợ Đầy Đủ Tính Năng & Chuyển Sang Wind UI ]]
-- Người viết & Sửa lỗi: Moondiety x Vuk (Nâng cấp giao diện Wind UI mới)

-- Services hệ thống
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local lp = Players.LocalPlayer
local minimizeUI = Enum.KeyCode.RightAlt

-- Khởi tạo Wind UI library
local WindUI = loadstring(game:HttpGet("https://treehub.tech/windui"))()

-- Tạo Cửa sổ chính (Main Window)
local Window = WindUI:CreateWindow({
    Title = "Grow a garden",
    SubTitle = "Phiên bản Wind UI nâng cấp",
    Size = UDim2.fromOffset(560, 480),
    Theme = "Amethyst", -- Chủ đề màu tím Amethyst sang trọng
    MinimizeKey = minimizeUI
})

-- Tạo các Tab điều hướng
local Tabs = {
    Home = Window:AddTab({ Title = "Trang Chủ", Icon = "rbxassetid://6026568198" }),
    Auto = Window:AddTab({ Title = "Tự Động", Icon = "rbxassetid://6031763426" }),
    Misc = Window:AddTab({ Title = "Hỗ Trợ", Icon = "rbxassetid://6034509993" }),
    Shops = Window:AddTab({ Title = "Cửa Hàng", Icon = "rbxassetid://6023426922" }),
    Ability = Window:AddTab({ Title = "Kỹ Năng", Icon = "rbxassetid://6034287525" }),
    Guis = Window:AddTab({ Title = "Giao Diện", Icon = "rbxassetid://6034795531" }),
    Events = Window:AddTab({ Title = "Sự Kiện", Icon = "rbxassetid://6034856082" }),
    Settings = Window:AddTab({ Title = "Cài Đặt", Icon = "rbxassetid://6031289116" })
}

-- [[ Các hàm tiện ích hỗ trợ ]]
local function parseMoney(moneyStr)
    if not moneyStr then return 0 end
    moneyStr = tostring(moneyStr):gsub("Â¢", ""):gsub(",", ""):gsub(" ", ""):gsub("%$", "")
    local multiplier = 1
    if moneyStr:lower():find("k") then
        multiplier = 1000
        moneyStr = moneyStr:lower():gsub("k", "")
    elseif moneyStr:lower():find("m") then
        multiplier = 1000000
        moneyStr = moneyStr:lower():gsub("m", "")
    end
    return (tonumber(moneyStr) or 0) * multiplier
end

-- Tìm chỉ số tiền tệ (Sheckles) của người chơi một cách an toàn
local leaderstats = lp:WaitForChild("leaderstats", 5)
local shecklesStat = leaderstats and (leaderstats:FindFirstChild("Sheckles") or leaderstats:FindFirstChild("Money"))

local function getPlayerMoney()
    return parseMoney((shecklesStat and shecklesStat.Value) or 0)
end

local function isInventoryFull()
    local backpack = lp:FindFirstChild("Backpack")
    if not backpack then return false end
    return #backpack:GetChildren() >= 200
end

-- [[ TAB TRANG CHỦ (HOME) ]]
Tabs.Home:AddParagraph({
    Title = "Thành viên phát triển",
    Content = "Được phát triển bởi Moondiety x Vuk. Toàn bộ các tính năng đã được kiểm tra và tối ưu hóa trên nền tảng Wind UI."
})

Tabs.Home:AddButton({
    Title = "Tham gia máy chủ Discord",
    Content = "Sao chép liên kết vào bộ nhớ tạm",
    Callback = function()
        setclipboard("https://discord.gg/wZ4hBXSrxY")
        WindUI:Notify({
            Title = "Thành Công!",
            Content = "Đã sao chép link Discord. Hãy dán vào trình duyệt để tham gia.",
            Duration = 5
        })
    end
})

Tabs.Home:AddButton({
    Title = "Kích hoạt Anti-AFK (Chống treo máy)",
    Content = "Ngăn chặn bị ngắt kết nối khi không hoạt động",
    Callback = function()
        local success, err = pcall(function()
            if getgc then
                for _, v in next, getgc(true) do
                    if typeof(v) == "function" and islclosure(v) then
                        local info = debug.getinfo(v)
                        if info and info.source and string.find(info.source, "Idled") then
                            local s, _ = pcall(function()
                                if getfenv(v).script == lp then
                                    if v.Disable then v.Disable(v) end
                                    if v.Disconnect then v.Disconnect(v) end
                                end
                            end)
                        end
                    end
                end
            else
                lp.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end
        end)
        if success then
            WindUI:Notify({ Title = "Hệ thống", Content = "Đã kích hoạt Anti-AFK thành công!", Duration = 5 })
        else
            warn("Lỗi Anti-AFK: ", err)
        end
    end
})

-- [[ TAB TỰ ĐỘNG (AUTO) ]]

-- Section: Tự động mua trang bị
local BuyGearsSection = Tabs.Auto:AddSection("Tự Động Mua Trang Bị")

local AllGears = {
    "All", "Watering Can", "Trading Ticket", "Trowel", "Recall Wrench", "Basic Sprinkler", 
    "Advanced Sprinkler", "Medium Toy", "Medium Treat", "Godly Sprinkler", "Magnifying Glass", 
    "Tanning Mirror", "Master Sprinkler", "Cleaning Spray", "Favorite Tool", "Harvest Tool", 
    "Friendship Pot", "Grandmaster Sprinkler", "Levelup Lollipop"
}

local SelectedGears = {}

local GearDropdown = BuyGearsSection:AddDropdown("Chọn trang bị muốn mua", AllGears, function(Value)
    SelectedGears = typeof(Value) == "table" and Value or {Value}
end)

local autoBuySelectedGear = false
BuyGearsSection:AddToggle("Tự động mua trang bị đã chọn", false, function(state)
    autoBuySelectedGear = state
    if state then
        task.spawn(function()
            while autoBuySelectedGear do
                if #SelectedGears > 0 then
                    if table.find(SelectedGears, "All") then
                        for i = 2, #AllGears do
                            if not autoBuySelectedGear then break end
                            ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyGearStock"):FireServer(AllGears[i])
                            task.wait(0.05)
                        end
                    else
                        for _, gear in ipairs(SelectedGears) do
                            if not autoBuySelectedGear then break end
                            ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyGearStock"):FireServer(gear)
                            task.wait(0.2)
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end)

-- Section: Tự động mua trứng thú cưng
local BuyEggsSection = Tabs.Auto:AddSection("Tự Động Mua Trứng")

local eggList = {
    "Common Egg", "Common Summer Egg", "Rare Summer Egg", "Mythical Egg", "Paradise Summer Egg", "Bee Egg", "Bug Egg"
}
local SelectedEggs = {}

BuyEggsSection:AddDropdown("Chọn loại trứng muốn mua", { "All", unpack(eggList) }, function(Value)
    SelectedEggs = typeof(Value) == "table" and Value or {Value}
end)

local autoBuyEggs = false
BuyEggsSection:AddToggle("Tự động mua trứng đã chọn", false, function(state)
    autoBuyEggs = state
    if state then
        task.spawn(function()
            while autoBuyEggs do
                local toBuy = table.find(SelectedEggs, "All") and eggList or SelectedEggs
                for _, eggName in ipairs(toBuy) do
                    if not autoBuyEggs then break end
                    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyPetEgg"):FireServer(eggName)
                    task.wait(0.5)
                end
                task.wait(0.1)
            end
        end)
    end
end)

-- Section: Tự động thu hoạch
local HarvestSection = Tabs.Auto:AddSection("Tự Động Thu Hoạch")

local harvestSpeed = 0.1
HarvestSection:AddInput("Tốc độ thu hoạch (Giây)", "0.1", function(value)
    local num = tonumber(value)
    if num and num > 0 then
        harvestSpeed = num
    else
        harvestSpeed = 0.1
    end
end)

local autoHarvest = false
HarvestSection:AddToggle("Kích hoạt tự động thu hoạch", false, function(state)
    autoHarvest = state
    if state then
        task.spawn(function()
            local getFarm = require(ReplicatedStorage.Modules.GetFarm)
            local byteNetReliable = ReplicatedStorage:WaitForChild("ByteNetReliable")
            local bufferData = buffer.fromstring("\1\1\0\1")

            local minWeight, maxWeight = 0, 9999

            local function harvestFilter(obj)
                local w = obj:FindFirstChild("Weight")
                if not w or not tonumber(w.Value) then return false end
                local val = tonumber(w.Value)
                return val >= minWeight and val <= maxWeight
            end

            while autoHarvest do
                local farm = getFarm(lp)
                if farm and farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical") then
                    for _, plant in ipairs(farm.Important.Plants_Physical:GetChildren()) do
                        if not autoHarvest then break end

                        if harvestFilter(plant) then
                            byteNetReliable:FireServer(bufferData, { plant })
                            task.wait(harvestSpeed)
                        end

                        local fruits = plant:FindFirstChild("Fruits", true)
                        if fruits then
                            for _, fruit in ipairs(fruits:GetChildren()) do
                                if not autoHarvest then break end
                                if harvestFilter(fruit) then
                                    byteNetReliable:FireServer(bufferData, { fruit })
                                    task.wait(harvestSpeed)
                                end
                            end
                        end
                    end
                else
                    warn("Không tìm thấy khu vườn (Plants_Physical). Đang thử lại...")
                end
                task.wait(0.5)
            end
        end)
    end
end)

-- Section: Tự động bán
local AutoSellSection = Tabs.Auto:AddSection("Tự Động Bán")

local autoSellEnabled = false
local function sellItems()
    local steven = workspace.NPCS:FindFirstChild("Steven")
    if not steven then return false end
    
    local char = lp.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local originalPosition = hrp.CFrame
    hrp.CFrame = steven.HumanoidRootPart.CFrame * CFrame.new(0, 3, 3)
    task.wait(0.5)
    
    for _ = 1, 5 do
        pcall(function()
            ReplicatedStorage.GameEvents.Sell_Inventory:FireServer()
        end)
        task.wait(0.15)
    end
    
    hrp.CFrame = originalPosition
    return true
end

AutoSellSection:AddToggle("Tự động dịch chuyển & bán vật phẩm", false, function(state)
    autoSellEnabled = state
    if state then
        task.spawn(function()
            while autoSellEnabled do
                sellItems()
                task.wait(5) -- Tránh spam liên tục gây lỗi hoặc kích hoạt anti-cheat
            end
        end)
    end
end)


-- [[ TAB HỖ TRỢ (MISC) ]]

-- Section: Chế tạo tự động
local CraftSection = Tabs.Misc:AddSection("Tự Động Chế Tạo Vật Phẩm")
local CraftingService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("CraftingGlobalObjectService")

getgenv().usedUUIDs = getgenv().usedUUIDs or {}

local function inputToolByName(name, index, itemType, Workbench, WorkbenchName, exactMatch)
    itemType = itemType or "Holdable"
    local backpack = lp:WaitForChild("Backpack")
    
    local function cleanToolName(str)
        str = str:gsub("%s*x%d+$", "")      -- Loại bỏ chỉ số số lượng kiểu " x123"
        str = str:gsub("%s*%[.-%]%s*", "")  -- Loại bỏ ngoặc vuông chứa số lượng
        return str
    end
    
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            if not getgenv().ignoreBlacklist then
                local lower = tool.Name:lower()
                if lower:find("seed") or lower:find("rahhhh") then
                    continue
                end
            end
            
            local toolNameToCheck = cleanToolName(tool.Name)
            local matched = exactMatch and (toolNameToCheck == name) or toolNameToCheck:find(name)
            
            if matched then
                local uuid = tool:GetAttribute("c")
                if uuid and not table.find(getgenv().usedUUIDs, uuid) then
                    local args = {
                        "InputItem",
                        Workbench,
                        WorkbenchName,
                        index,
                        {
                            ItemType = itemType,
                            ItemData = { UUID = uuid }
                        }
                    }
                    CraftingService:FireServer(unpack(args))
                    table.insert(getgenv().usedUUIDs, uuid)
                    task.wait(0.25)
                    return true
                end
            end
        end
    end
    return false
end

local function triggerProximityPrompt(workbench)
    task.wait(1.5)
    for _, descendant in ipairs(workbench:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Name == "CraftingProximityPrompt" then
            fireproximityprompt(descendant)
            task.wait(2)
            fireproximityprompt(descendant)
            break
        end
    end
end

-- Danh sách các hàm chế tạo cụ thể (Đã sửa sạch toàn bộ lỗi chính tả/thiếu biến)
local function craftLightningRod()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Lightning Rod")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Basic Sprinkler", 1, "Sprinkler", Workbench, WorkbenchName)
    success = success and inputToolByName("Advanced Sprinkler", 2, "Sprinkler", Workbench, WorkbenchName)
    success = success and inputToolByName("Godly Sprinkler", 3, "Sprinkler", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Lightning Rod")
    end
end

local function craftReclaimer()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Reclaimer")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Common Egg", 1, "PetEgg", Workbench, WorkbenchName)
    success = success and inputToolByName("Harvest Tool", 2, "Harvest Tool", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Reclaimer")
    end
end

local function craftTropicalMist()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Tropical Mist Sprinkler")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Coconut", 1, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Dragon Fruit", 2, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Mango", 3, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Godly Sprinkler", 4, "Sprinkler", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Tropical Mist Sprinkler")
    end
end

local function craftBerryBlusher()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Berry Blusher Sprinkler")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Grape", 1, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Blueberry", 2, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Strawberry", 3, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Godly Sprinkler", 4, "Sprinkler", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Berry Blusher Sprinkler")
    end
end

local function craftSweetSoaker()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Sweet Soaker Sprinkler")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Watermelon", 1, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Watermelon", 2, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Watermelon", 3, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Master Sprinkler", 4, "Sprinkler", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Sweet Soaker Sprinkler")
    end
end

local function craftFlowerFroster()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Flower Froster Sprinkler")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Orange Tulip", 1, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Daffodil", 2, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Advanced Sprinkler", 3, "Sprinkler", Workbench, WorkbenchName)
    success = success and inputToolByName("Basic Sprinkler", 4, "Sprinkler", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Flower Froster Sprinkler")
    end
end

local function craftSpiceSpritzer()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Spice Spritzer Sprinkler")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Pepper", 1, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Ember Lily", 2, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Cacao", 3, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Master Sprinkler", 4, "Sprinkler", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Spice Spritzer Sprinkler")
    end
end

local function craftStalkSprout()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Stalk Sprout Sprinkler")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Bamboo", 1, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Beanstalk", 2, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Mushroom", 3, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Advanced Sprinkler", 4, "Sprinkler", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Stalk Sprout Sprinkler")
    end
end

local function craftMutationSprayChoc()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Mutation Spray Choc")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Cleaning Spray", 1, "SprayBottle", Workbench, WorkbenchName)
    success = success and inputToolByName("Cacao", 2, nil, Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Mutation Spray Choc")
    end
end

local function craftMutationSprayChilled()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Mutation Spray Chilled")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Cleaning Spray", 1, "SprayBottle", Workbench, WorkbenchName)
    success = success and inputToolByName("Godly Sprinkler", 2, "Sprinkler", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Mutation Spray Chilled")
    end
end

local function craftMutationSprayShocked()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Mutation Spray Shocked")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Cleaning Spray", 1, "SprayBottle", Workbench, WorkbenchName)
    success = success and inputToolByName("Lightning Rod", 2, "Lightning Rod", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Mutation Spray Shocked")
    end
end

local function craftAntiBeeEgg()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Anti Bee Egg")
    task.wait(0.5)
    local success = inputToolByName("Bee Egg", 1, "PetEgg", Workbench, WorkbenchName, true)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Anti Bee Egg")
    end
end

local function craftSmallToy()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    local prevIgnore = getgenv().ignoreBlacklist
    getgenv().ignoreBlacklist = true
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Small Toy")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Common Egg", 1, "PetEgg", Workbench, WorkbenchName, true)
    success = success and inputToolByName("Coconut Seed", 2, "Seed", Workbench, WorkbenchName)
    success = success and inputToolByName("Coconut", 3, nil, Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Small Toy")
    end
    getgenv().ignoreBlacklist = prevIgnore
end

local function craftSmallTreat()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    local prevIgnore = getgenv().ignoreBlacklist
    getgenv().ignoreBlacklist = true
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Small Treat")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Common Egg", 1, "PetEgg", Workbench, WorkbenchName, true)
    success = success and inputToolByName("Dragon Fruit Seed", 2, "Seed", Workbench, WorkbenchName)
    success = success and inputToolByName("Blueberry", 3, nil, Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Small Treat")
    end
    getgenv().ignoreBlacklist = prevIgnore
end

local function craftPackBee()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("EventCraftingWorkBench")
    local WorkbenchName = "GearEventWorkbench"
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Pack Bee")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Anti Bee Egg", 1, "PetEgg", Workbench, WorkbenchName)
    success = success and inputToolByName("Sunflower", 2, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Purple Dahlia", 3, nil, Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên để chế tạo Pack Bee")
    end
end

-- Chế tạo hạt giống sự kiện
local function craftHorsetailSeed()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("SeedEventCraftingWorkBench")
    local WorkbenchName = "SeedEventWorkbench"
    local prevIgnore = getgenv().ignoreBlacklist
    getgenv().ignoreBlacklist = true
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Horsetail")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Stonebite Seed", 1, "Seed", Workbench, WorkbenchName)
    success = success and inputToolByName("Bamboo", 2, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Corn", 3, nil, Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên chế tạo hạt giống Horsetail")
    end
    getgenv().ignoreBlacklist = prevIgnore
end

local function craftLingonBerrySeed()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("SeedEventCraftingWorkBench")
    local WorkbenchName = "SeedEventWorkbench"
    local prevIgnore = getgenv().ignoreBlacklist
    getgenv().ignoreBlacklist = true
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Lingonberry")
    task.wait(0.5)
    local success = true
    
    success = success and inputToolByName("Blueberry Seed", 1, "Seed", Workbench, WorkbenchName)
    task.wait(0.3)
    success = success and inputToolByName("Blueberry Seed", 2, "Seed", Workbench, WorkbenchName)
    task.wait(0.3)
    success = success and inputToolByName("Blueberry Seed", 3, "Seed", Workbench, WorkbenchName)
    task.wait(0.3)
    success = success and inputToolByName("Horsetail", 4, nil, Workbench, WorkbenchName)
    
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên chế tạo hạt giống Lingon Berry")
    end
    getgenv().ignoreBlacklist = prevIgnore
end

local function craftAmberSpineSeed()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("SeedEventCraftingWorkBench")
    local WorkbenchName = "SeedEventWorkbench"
    local prevIgnore = getgenv().ignoreBlacklist
    getgenv().ignoreBlacklist = true
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Amber Spine")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Cactus Seed", 1, "Seed", Workbench, WorkbenchName)
    success = success and inputToolByName("Pumpkin", 2, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Horsetail", 3, nil, Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên chế tạo hạt giống Amber Spine")
    end
    getgenv().ignoreBlacklist = prevIgnore
end

local function craftGrandVolcaniaSeed()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("SeedEventCraftingWorkBench")
    local WorkbenchName = "SeedEventWorkbench"
    local prevIgnore = getgenv().ignoreBlacklist
    getgenv().ignoreBlacklist = true
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Grand Volcania")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Ember Lily", 1, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Ember Lily", 2, nil, Workbench, WorkbenchName)
    success = success and inputToolByName("Dinosaur Egg", 3, "PetEgg", Workbench, WorkbenchName)
    success = success and inputToolByName("Ancient Seed Pack", 4, "Seed Pack", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên chế tạo hạt giống Grand Volcania")
    end
    getgenv().ignoreBlacklist = prevIgnore
end

local function craftPeaceLilySeed()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("SeedEventCraftingWorkBench")
    local WorkbenchName = "SeedEventWorkbench"
    local prevIgnore = getgenv().ignoreBlacklist
    getgenv().ignoreBlacklist = true
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Peace Lily")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Rafflesia Seed", 1, "Seed", Workbench, WorkbenchName)
    success = success and inputToolByName("Cauliflower Seed", 2, "Seed", Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên chế tạo hạt giống Peace Lily")
    end
    getgenv().ignoreBlacklist = prevIgnore
end

local function craftAloeVeraSeed()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("SeedEventCraftingWorkBench")
    local WorkbenchName = "SeedEventWorkbench"
    local prevIgnore = getgenv().ignoreBlacklist
    getgenv().ignoreBlacklist = true
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Aloe Vera")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Peace Lily Seed", 1, "Seed", Workbench, WorkbenchName)
    success = success and inputToolByName("Prickly Pear", 2, nil, Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên chế tạo hạt giống Aloe Vera")
    end
    getgenv().ignoreBlacklist = prevIgnore
end

local function craftGuanabanaSeed()
    getgenv().usedUUIDs = {}
    local Workbench = workspace:WaitForChild("CraftingTables"):WaitForChild("SeedEventCraftingWorkBench")
    local WorkbenchName = "SeedEventWorkbench"
    local prevIgnore = getgenv().ignoreBlacklist
    getgenv().ignoreBlacklist = true
    CraftingService:FireServer("SetRecipe", Workbench, WorkbenchName, "Guanabana")
    task.wait(0.5)
    local success = true
    success = success and inputToolByName("Aloe Vera Seed", 1, "Seed", Workbench, WorkbenchName)
    success = success and inputToolByName("Prickly Pear Seed", 2, "Seed", Workbench, WorkbenchName)
    success = success and inputToolByName("Banana", 3, nil, Workbench, WorkbenchName)
    if success then
        task.wait(0.2)
        triggerProximityPrompt(Workbench)
    else
        warn("Thiếu tài nguyên chế tạo hạt giống Guanabana")
    end
    getgenv().ignoreBlacklist = prevIgnore
end

-- Tùy chọn giao diện chế tạo
local selectedCraftItem = "Lightning Rod"
local ItemDropdown = CraftSection:AddDropdown("Chọn công thức trang bị", {
    "Lightning Rod", "Reclaimer", "Tropical Mist Sprinkler", "Berry Blusher Sprinkler",
    "Sweet Soaker Sprinkler", "Flower Froster Sprinkler", "Spice Spritzer Sprinkler",
    "Stalk Sprout Sprinkler", "Mutation Spray Choc", "Mutation Spray Chilled",
    "Mutation Spray Shocked", "Anti Bee Egg", "Small Toy", "Small Treat", "Pack Bee"
}, function(value)
    selectedCraftItem = value
end)

local autoCraftItems = false
local craftTimes = {
    ["Lightning Rod"] = 46, ["Reclaimer"] = 26, ["Tropical Mist Sprinkler"] = 61,
    ["Berry Blusher Sprinkler"] = 61, ["Spice Spritzer Sprinkler"] = 61,
    ["Flower Froster Sprinkler"] = 61, ["Stalk Sprout Sprinkler"] = 61,
    ["Sweet Soaker Sprinkler"] = 61, ["Mutation Spray Choc"] = 13,
    ["Mutation Spray Chilled"] = 6, ["Mutation Spray Shocked"] = 31,
    ["Anti Bee Egg"] = 121, ["Small Toy"] = 11, ["Small Treat"] = 11, ["Pack Bee"] = 241
}

local function getCraftFunction(name)
    local map = {
        ["Lightning Rod"] = craftLightningRod,
        ["Reclaimer"] = craftReclaimer,
        ["Tropical Mist Sprinkler"] = craftTropicalMist,
        ["Berry Blusher Sprinkler"] = craftBerryBlusher,
        ["Sweet Soaker Sprinkler"] = craftSweetSoaker,
        ["Flower Froster Sprinkler"] = craftFlowerFroster,
        ["Spice Spritzer Sprinkler"] = craftSpiceSpritzer,
        ["Stalk Sprout Sprinkler"] = craftStalkSprout,
        ["Mutation Spray Choc"] = craftMutationSprayChoc,
        ["Mutation Spray Chilled"] = craftMutationSprayChilled,
        ["Mutation Spray Shocked"] = craftMutationSprayShocked,
        ["Anti Bee Egg"] = craftAntiBeeEgg,
        ["Small Toy"] = craftSmallToy,
        ["Small Treat"] = craftSmallTreat,
        ["Pack Bee"] = craftPackBee
    }
    return map[name]
end

CraftSection:AddToggle("Tự động chế tạo trang bị chọn", false, function(state)
    autoCraftItems = state
    if state then
        task.spawn(function()
            while autoCraftItems do
                local func = getCraftFunction(selectedCraftItem)
                if func then
                    func()
                end
                local waitTime = (craftTimes[selectedCraftItem] or 15) * 60
                local start = tick()
                while tick() - start < waitTime do
                    if not autoCraftItems then break end
                    task.wait(1)
                end
            end
        end)
    end
end)

local selectedSeedRecipe = "Horsetail Seed"
local SeedDropdown = CraftSection:AddDropdown("Chọn công thức hạt giống", {
    "Horsetail Seed", "Lingon Berry Seed", "Amber Spine Seed", "Grand Volcania Seed", 
    "Peace Lily Seed", "Aloe Vera Seed", "Guanabana Seed"
}, function(value)
    selectedSeedRecipe = value
end)

local autoCraftSeeds = false
local seedCraftTimes = {
    ["Horsetail Seed"] = 16, ["Lingon Berry Seed"] = 16, ["Amber Spine Seed"] = 31,
    ["Grand Volcania Seed"] = 46, ["Peace Lily Seed"] = 11, ["Aloe Vera Seed"] = 11, ["Guanabana Seed"] = 11
}

local function getSeedCraftFunction(name)
    local map = {
        ["Horsetail Seed"] = craftHorsetailSeed,
        ["Lingon Berry Seed"] = craftLingonBerrySeed,
        ["Amber Spine Seed"] = craftAmberSpineSeed,
        ["Grand Volcania Seed"] = craftGrandVolcaniaSeed,
        ["Peace Lily Seed"] = craftPeaceLilySeed,
        ["Aloe Vera Seed"] = craftAloeVeraSeed,
        ["Guanabana Seed"] = craftGuanabanaSeed
    }
    return map[name]
end

CraftSection:AddToggle("Tự động chế tạo hạt giống chọn", false, function(state)
    autoCraftSeeds = state
    if state then
        task.spawn(function()
            while autoCraftSeeds do
                local func = getSeedCraftFunction(selectedSeedRecipe)
                if func then
                    func()
                end
                local waitTime = (seedCraftTimes[selectedSeedRecipe] or 15) * 60
                local start = tick()
                while tick() - start < waitTime do
                    if not autoCraftSeeds then break end
                    task.wait(1)
                end
            end
        end)
    end
end)

-- Section: Cho thú cưng ăn tự động
local PetSection = Tabs.Misc:AddSection("Cho Thú Cưng Ăn")

local feedMethod = "Closest"
PetSection:AddDropdown("Phương thức cho ăn", { "Closest", "All" }, function(value)
    feedMethod = value
end)

local function feedPets()
    local pets = workspace:WaitForChild("PetsPhysical", 5)
    if not pets then return end

    if feedMethod == "Closest" then
        local nearest, dist = nil, math.huge
        for _, v in ipairs(pets:GetChildren()) do
            if v:IsA("Part") and v:GetAttribute("OWNER") == lp.Name then
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (v.Position - hrp.Position).Magnitude
                    if d < dist then
                        nearest, dist = v, d
                    end
                end
            end
        end

        if nearest then
            ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("ActivePetService"):FireServer("Feed", nearest:GetAttribute("UUID"))
        end
    elseif feedMethod == "All" then
        for _, v in ipairs(pets:GetChildren()) do
            if v:IsA("Part") and v:GetAttribute("OWNER") == lp.Name and v:GetAttribute("UUID") then
                ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("ActivePetService"):FireServer("Feed", v:GetAttribute("UUID"))
                task.wait(0.1)
            end
        end
    end
end

local autoFeedActive = false
PetSection:AddToggle("Tự động cho ăn", false, function(state)
    autoFeedActive = state
    if state then
        task.spawn(function()
            while autoFeedActive do
                pcall(feedPets)
                task.wait(1.5)
            end
        end)
    end
end)

-- Section: Các tính năng linh tinh khác
local OtherMiscSection = Tabs.Misc:AddSection("Các Tính Năng Phụ")

OtherMiscSection:AddToggle("Ẩn thông báo góc trên", false, function(state)
    local notificationGui = lp:WaitForChild("PlayerGui"):FindFirstChild("Top_Notification")
    local frame = notificationGui and notificationGui:FindFirstChild("Frame")
    if frame then
        frame.Visible = not state
    end
end)

local hasFixLagRun = false
OtherMiscSection:AddButton({
    Title = "Giảm Lag (Chỉ chạy 1 lần)",
    Content = "Xóa rác đồ họa để tăng mượt mà",
    Callback = function()
        if not hasFixLagRun then
            hasFixLagRun = true
            pcall(function()
                loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Fix-lag-all-game-24449"))()
                WindUI:Notify({ Title = "Giảm Lag", Content = "Đã chạy cấu hình giảm lag tối ưu!", Duration = 5 })
            end)
        else
            WindUI:Notify({ Title = "Thông báo", Content = "Tính năng giảm lag chỉ có thể chạy một lần mỗi phiên chơi.", Duration = 5 })
        end
    end
})


-- [[ TAB KỸ NĂNG (ABILITY) ]]
local AbilitySection = Tabs.Ability:AddSection("Hỗ Trợ Di Chuyển")

local flyEnabled = false
local flySpeed = 48
local bodyVelocity, bodyGyro
local flightConnection

local function ToggleFly(state)
    flyEnabled = state
    local char = lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if flyEnabled then
        bodyGyro = Instance.new("BodyGyro")
        bodyVelocity = Instance.new("BodyVelocity")
        bodyGyro.P = 9000
        bodyGyro.MaxTorque = Vector3.new(999999, 999999, 999999)
        bodyGyro.CFrame = char.HumanoidRootPart.CFrame
        bodyGyro.Parent = char.HumanoidRootPart

        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(999999, 999999, 999999)
        bodyVelocity.Parent = char.HumanoidRootPart

        humanoid.PlatformStand = true

        flightConnection = RunService.Heartbeat:Connect(function()
            if not flyEnabled or not char:FindFirstChild("HumanoidRootPart") then
                if flightConnection then flightConnection:Disconnect() end
                return
            end

            local cam = workspace.CurrentCamera.CFrame
            local moveVec = Vector3.new()

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += Vector3.new(0, flySpeed, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec -= Vector3.new(0, flySpeed, 0) end

            if moveVec.Magnitude > 0 then
                moveVec = moveVec.Unit * flySpeed
            end

            bodyVelocity.Velocity = moveVec
            bodyGyro.CFrame = cam
        end)
    else
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        humanoid.PlatformStand = false
        if flightConnection then
            flightConnection:Disconnect()
            flightConnection = nil
        end
    end
end

AbilitySection:AddToggle("Kích hoạt chế độ Bay (Fly)", false, function(state)
    ToggleFly(state)
end)

AbilitySection:AddSlider("Tốc độ bay", 10, 150, 48, function(value)
    flySpeed = value
end)

-- Noclip & Infinite Jump
local noclipEnabled = false
local noclipConnection
AbilitySection:AddToggle("Kích hoạt đi xuyên tường (Noclip)", false, function(state)
    noclipEnabled = state
    if noclipEnabled then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = lp.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end)

local infJumpEnabled = false
AbilitySection:AddToggle("Kích hoạt nhảy vô tận", false, function(state)
    infJumpEnabled = state
end)

UserInputService.JumpRequest:Connect(function()
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if infJumpEnabled and hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)


-- [[ TAB CỬA HÀNG (SHOPS) ]]
local ShopVisualSection = Tabs.Shops:AddSection("Mở Nhanh Giao Diện Game")

ShopVisualSection:AddToggle("Mở Cửa Hàng Hạt Giống", false, function(state)
    local shop = lp.PlayerGui:FindFirstChild("Seed_Shop")
    if shop then shop.Enabled = state end
end)

ShopVisualSection:AddToggle("Mở Cửa Hàng Trang Bị", false, function(state)
    local gear = lp.PlayerGui:FindFirstChild("Gear_Shop")
    if gear then gear.Enabled = state end
end)

ShopVisualSection:AddToggle("Mở Nhiệm Vụ Hàng Ngày", false, function(state)
    local quest = lp.PlayerGui:FindFirstChild("DailyQuests_UI")
    if quest then quest.Enabled = state end
end)

ShopVisualSection:AddToggle("Xóa xác nhận khi phá cây (Xẻng nhanh)", false, function(state)
    local confirmFrame = lp.PlayerGui:FindFirstChild("ShovelPrompt")
    if confirmFrame and confirmFrame:FindFirstChild("ConfirmFrame") then
        confirmFrame.ConfirmFrame.Visible = not state
    end
end)


-- [[ TAB SỰ KIỆN (EVENTS) ]]
local DinoMachineSection = Tabs.Events:AddSection("Cỗ Máy Khủng Long (Dino Machine)")

DinoMachineSection:AddToggle("Tự Động Gửi DNA Thú Cưng", false, function(state)
    getgenv().autoSendPets = state
    if state then
        task.spawn(function()
            while getgenv().autoSendPets do
                ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("DinoMachineService_RE"):FireServer("MachineInteract")
                task.wait(1)
            end
        end)
    end
end)

DinoMachineSection:AddToggle("Tự Động Nhận Thưởng DNA", false, function(state)
    getgenv().autoSubmitFruit = state
    if state then
        task.spawn(function()
            while getgenv().autoSubmitFruit do
                ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("DinoMachineService_RE"):FireServer("ClaimReward")
                task.wait(1)
            end
        end)
    end
end)

-- Chế tạo Dino Event
local DinoCraftSection = Tabs.Events:AddSection("Chế Tạo Đồ Sự Kiện Dino")
local DinoWorkbench = workspace:WaitForChild("DinoEvent", 5) and workspace.DinoEvent:WaitForChild("DinoCraftingTable", 5)

local function fireDinoEventPrompts()
    if not workspace:FindFirstChild("DinoEvent") then return end
    for _, p in ipairs(workspace.DinoEvent:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.Name == "CraftingProximityPrompt" then
            fireproximityprompt(p)
            task.wait(1.5)
            fireproximityprompt(p)
            break
        end
    end
end

local function craftDinoEvent(recipeName, reqName, reqIndex, reqType)
    if not DinoWorkbench then return end
    getgenv().usedUUIDs = {}
    CraftingService:FireServer("SetRecipe", DinoWorkbench, "DinoEventWorkbench", recipeName)
    task.wait(0.5)
    inputToolByName(reqName, reqIndex, reqType, DinoWorkbench, "DinoEventWorkbench")
    task.wait(1)
    fireDinoEventPrompts()
end

local selectedDinoRecipe = "Mutation Spray Amber"
DinoCraftSection:AddDropdown("Chọn vật phẩm Dino", { "Mutation Spray Amber", "Ancient Seed Pack", "Dino Crate", "Archaeologist Crate" }, function(value)
    selectedDinoRecipe = value
end)

local autoDinoActive = false
local dinoTimers = { ["Mutation Spray Amber"] = 61, ["Ancient Seed Pack"] = 61, ["Dino Crate"] = 31, ["Archaeologist Crate"] = 31 }

DinoCraftSection:AddToggle("Tự động chế tạo đồ Dino", false, function(state)
    autoDinoActive = state
    if state then
        task.spawn(function()
            while autoDinoActive do
                if selectedDinoRecipe == "Mutation Spray Amber" then
                    getgenv().usedUUIDs = {}
                    CraftingService:FireServer("SetRecipe", DinoWorkbench, "DinoEventWorkbench", "Mutation Spray Amber")
                    task.wait(0.5)
                    inputToolByName("Cleaning Spray", 1, "SprayBottle", DinoWorkbench, "DinoEventWorkbench")
                    inputToolByName("Dinosaur Egg", 2, "PetEgg", DinoWorkbench, "DinoEventWorkbench")
                    task.wait(1)
                    fireDinoEventPrompts()
                elseif selectedDinoRecipe == "Ancient Seed Pack" then
                    craftDinoEvent("Ancient Seed Pack", "Dinosaur Egg", 1, "PetEgg")
                elseif selectedDinoRecipe == "Dino Crate" then
                    craftDinoEvent("Dino Crate", "Dinosaur Egg", 1, "PetEgg")
                elseif selectedDinoRecipe == "Archaeologist Crate" then
                    craftDinoEvent("Archaeologist Crate", "Dinosaur Egg", 1, "PetEgg")
                end
                
                local waitSecs = (dinoTimers[selectedDinoRecipe] or 30) * 60
                local start = tick()
                while tick() - start < waitSecs do
                    if not autoDinoActive then break end
                    task.wait(1)
                end
            end
        end)
    end
end)


-- [[ TAB GIAO DIỆN (GUIS) ]]
local GuiButtonSection = Tabs.Guis:AddSection("Nút Dịch Chuyển Nhanh")

local tpEventBtn
GuiButtonSection:AddToggle("Hiển thị nút TP đến Sự Kiện", false, function(value)
    local playerGui = lp:WaitForChild("PlayerGui")
    if value then
        if not playerGui:FindFirstChild("EventGui") then
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "EventGui"
            screenGui.ResetOnSpawn = false
            screenGui.Parent = playerGui

            local tpButton = Instance.new("ImageButton")
            tpButton.Name = "TPToEventButton"
            tpButton.Size = UDim2.new(0, 160, 0, 30)
            tpButton.Position = UDim2.new(0.5, -80, 0.05, 0)
            tpButton.BackgroundColor3 = Color3.fromRGB(255, 230, 80)
            tpButton.Image = "rbxassetid://9438453826"
            tpButton.ScaleType = Enum.ScaleType.Slice
            tpButton.Parent = screenGui

            local corner = Instance.new("UICorner", tpButton)
            corner.CornerRadius = UDim.new(0, 10)

            local label = Instance.new("TextLabel")
            label.Parent = tpButton
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "TP đến Sự Kiện"
            label.Font = Enum.Font.FredokaOne
            label.TextScaled = true
            label.TextColor3 = Color3.fromRGB(25, 25, 25)

            tpButton.MouseButton1Click:Connect(function()
                local char = lp.Character or lp.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")
                hrp.CFrame = CFrame.new(Vector3.new(-104.11, 0.9, -12.10))
            end)
        end
    else
        local existingGui = playerGui:FindFirstChild("EventGui")
        if existingGui then existingGui:Destroy() end
    end
end)

GuiButtonSection:AddToggle("Hiển thị nút dịch chuyển GEAR", false, function(value)
    local playerGui = lp:WaitForChild("PlayerGui")
    if value then
        if not playerGui:FindFirstChild("GearGui") then
            local gui = Instance.new("ScreenGui")
            gui.Name = "GearGui"
            gui.ResetOnSpawn = false
            gui.Parent = playerGui

            local button = Instance.new("TextButton")
            button.Name = "GearButton"
            button.Text = "GEAR TELEPORT"
            button.TextSize = 14
            button.Font = Enum.Font.GothamBold
            button.Size = UDim2.new(0, 120, 0, 30)
            button.Position = UDim2.new(0.3, 0, 0.05, 0)
            button.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            button.TextColor3 = Color3.new(1, 1, 1)
            button.Parent = gui

            local targetPosition = Vector3.new(-285.41, 2.77, -13.98)
            local lookDirection = Vector3.new(-285.41, 2.77, -20)

            button.MouseButton1Click:Connect(function()
                local character = lp.Character or lp.CharacterAdded:Wait()
                local hrp = character:WaitForChild("HumanoidRootPart")
                hrp.CFrame = CFrame.lookAt(targetPosition, lookDirection)
            end)
        end
    else
        local existingGui = playerGui:FindFirstChild("GearGui")
        if existingGui then existingGui:Destroy() end
    end
end)


-- [[ TẠO NÚT TRÒN DI ĐỘNG ĐỂ ẨN/HIỆN MENU CHÍNH ]]
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DraggableClickableImageGui"
screenGui.Parent = CoreGui

local imageButton = Instance.new("ImageButton")
imageButton.Size = UDim2.new(0, 50, 0, 50)
imageButton.Position = UDim2.new(0, 10, 1, -160)
imageButton.BackgroundTransparency = 1
imageButton.Image = "rbxassetid://133495621202705"
imageButton.Parent = screenGui
imageButton.Active = true
imageButton.Selectable = true

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent = imageButton

local uiScale = Instance.new("UIScale")
uiScale.Parent = imageButton

local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local hoverTween = TweenService:Create(uiScale, tweenInfo, { Scale = 1.1 })
local leaveTween = TweenService:Create(uiScale, tweenInfo, { Scale = 1 })

imageButton.MouseEnter:Connect(function() hoverTween:Play() end)
imageButton.MouseLeave:Connect(function() leaveTween:Play() end)

-- Thuật toán kéo thả và tương tác chạm/bấm mượt mà
local dragging = false
local dragStart, startPos, dragInput
local clickThreshold = 10

local function playFlickerOnce()
    task.spawn(function()
        imageButton.ImageTransparency = 0.2
        task.wait(0.15)
        imageButton.ImageTransparency = 0.6
        task.wait(0.15)
        local fadeTween = TweenService:Create(imageButton, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            ImageTransparency = 0
        })
        fadeTween:Play()
    end)
end

local function toggleUI()
    -- Giao diện Wind UI hỗ trợ đóng mở thông qua việc ẩn/hiện Window Frame
    local container = CoreGui:FindFirstChild("WindUI") or CoreGui:FindFirstChild("ScreenGui")
    if container then
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Frame") then
                obj.Visible = not obj.Visible
            end
        end
    end
end

imageButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = imageButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                local moved = (input.Position - dragStart).Magnitude
                if moved < clickThreshold then
                    playFlickerOnce()
                    toggleUI()
                end
            end
        end)
    end
end)

imageButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        local newPosition = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        local moveTween = TweenService:Create(imageButton, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Position = newPosition })
        moveTween:Play()
    end
end)

-- Gửi thông báo nạp thành công
WindUI:Notify({
    Title = "Hệ thống Moondiety",
    Content = "Menu Grow a Garden đã được chuyển sang Wind UI thành công!",
    Duration = 5
})

```
