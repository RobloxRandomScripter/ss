-- 🔥 GLOBAL PATCH FOR GETMOUSE ERRORS
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

if typeof(plr) == "Instance" and not pcall(function() return plr:GetMouse() end) then
    plr.GetMouse = function()
        return setmetatable({}, {
            __index = function(_, key)
                if key == "X" then return UIS:GetMouseLocation().X end
                if key == "Y" then return UIS:GetMouseLocation().Y end
                if key:lower():find("down") then return UIS.InputBegan end
                if key:lower():find("up") then return UIS.InputEnded end
                return function() end
            end
        })
    end
end

-- Auto re-execute on server hop
local queue = (syn and syn.queue_on_teleport) or (queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or nil
if queue then
    queue([[
        loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/RobloxRandomScripter/ss/refs/heads/main/Script.lua"))()
    ]])
end

-- 🚀 Custom GUI System (replacing Fluent)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoObbyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TitleBar.Text = "AutoObby (Custom UI)"
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.Font = Enum.Font.SourceSansBold
TitleBar.TextSize = 20
TitleBar.Parent = MainFrame

-- 🔥 Simple draggable
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ✅ Fake Fluent API
local Window = {}
function Window:SelectTab(_) end
function Window:CreateTab(args)
    local tab = {}
    function tab:CreateToggle(name, opts)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, -20, 0, 40)
        Button.Position = UDim2.new(0, 10, 0, 40 + (#MainFrame:GetChildren() - 1) * 45)
        Button.Text = (opts.Title or name) .. (opts.Default and " [ON]" or " [OFF]")
        Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.Font = Enum.Font.SourceSansBold
        Button.TextSize = 18
        Button.Parent = MainFrame

        local state = opts.Default or false
        Button.MouseButton1Click:Connect(function()
            state = not state
            Button.Text = (opts.Title or name) .. (state and " [ON]" or " [OFF]")
            print("Toggle " .. name .. " changed to", state)
        end)

        return { Value = state }
    end
    return tab
end

-- ✅ Keep Options for compatibility
local Options = {}

-- Roblox Services
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Get Character
local function getCharacter()
    local char = plr.Character or plr.CharacterAdded:Wait()
    local humPart = char:WaitForChild("HumanoidRootPart", 5)
    return char, humPart
end
local char, humPart = getCharacter()
plr.CharacterAdded:Connect(function()
    char, humPart = getCharacter()
end)

-- 🔥 HTTP wrapper
local function httpRequest(options)
    local req = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
    if req then return req(options) else warn("AutoObby: No supported HTTP request function found!") return nil end
end

-- 🚀 Server Hop
local function serverHop()
    local servers = {}
    local cursor = ""
    repeat
        local success, result = pcall(function()
            return httpRequest({
                Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100&cursor=" .. cursor,
                Method = "GET",
                Headers = { ["Content-Type"] = "application/json" }
            })
        end)
        if success and result and result.StatusCode == 200 then
            local body = HttpService:JSONDecode(result.Body)
            for _, server in ipairs(body.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server)
                end
            end
            cursor = body.nextPageCursor or nil
        else
            cursor = nil
        end
    until not cursor or #servers >= 20

    if #servers > 0 then
        table.sort(servers, function(a, b) return a.playing < b.playing end)
        for _, server in ipairs(servers) do
            local success, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, plr)
            end)
            if success then return else task.wait(0.2) end
        end
    else
        TeleportService:Teleport(game.PlaceId, plr)
    end
end

-- 🌟 GUI Setup
local Tabs = { Main = Window:CreateTab { Title = "Main" } }
local AutoObby = Tabs.Main:CreateToggle("AutoObby", {Title = "Auto Complete Obby", Default = true})
local AutoHardObby = Tabs.Main:CreateToggle("AutoHardObby", {Title = "Auto Complete Hard Obby", Default = true})

-- 🏆 Chest Check
local collect = workspace:FindFirstChild("CollectableItems")
local chestsCollected = {regular = false, hard = false}
local function checkChests()
    if not collect then return false end
    local regularChestFound, hardChestFound = false, false
    for _, item in ipairs(collect:GetChildren()) do
        if item:GetAttribute("CannotSee") then continue end
        if item.Name:lower():find("chest") then
            if item.Name:lower():find("hard") or item.Name:lower():find("difficult") then
                hardChestFound = true
            else
                regularChestFound = true
            end
        end
    end
    chestsCollected.regular = not regularChestFound
    chestsCollected.hard = not hardChestFound
    if chestsCollected.regular and chestsCollected.hard then
        task.wait(1)
        serverHop()
    end
    return chestsCollected.regular and chestsCollected.hard
end

-- 🚀 Run AutoObbies
local function runAutoObbies()
    pcall(function()
        if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
        local lobby = workspace:FindFirstChild("Lobby")
        local obby = lobby and lobby:FindFirstChild("Obby")
        local obbyEndPart = obby and obby:FindFirstChild("ObbyEndPart")
        local hardObbyEndPart = obby and obby:FindFirstChild("HardObbyEndPart")
        if not obbyEndPart or not hardObbyEndPart then return end

        -- Teleport to obby
        plr.Character.HumanoidRootPart.CFrame = obbyEndPart.CFrame + Vector3.new(0, 3, 0)
        if firetouchinterest then
            firetouchinterest(plr.Character.HumanoidRootPart, obbyEndPart, 0)
            task.wait(0.05)
            firetouchinterest(plr.Character.HumanoidRootPart, obbyEndPart, 1)
        end
        task.wait(0.1)

        plr.Character.HumanoidRootPart.CFrame = hardObbyEndPart.CFrame + Vector3.new(0, 3, 0)
        if firetouchinterest then
            firetouchinterest(plr.Character.HumanoidRootPart, hardObbyEndPart, 0)
            task.wait(0.05)
            firetouchinterest(plr.Character.HumanoidRootPart, hardObbyEndPart, 1)
        end
        checkChests()
    end)
end

task.spawn(runAutoObbies)
task.spawn(function()
    while true do checkChests() task.wait(1) end
end)

print("AutoObby: Custom GUI initialized successfully ✅")
