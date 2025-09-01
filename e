while true do
    --[[
      AutoObby and AutoHardObby GUI for Be NPC or Die with Persistent GUI and Robust Server Hopping
    ]]
    if game.GameId == 4019583467 and game.PlaceId == 11276071411 then
        local success, Library = pcall(function()
            return loadstring(
                game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau")
            )()
        end)
        if not success then
            warn("AutoObby: Failed to load Fluent library: " .. tostring(Library))
            return
        end

        local success, Window = pcall(function()
            return Library:CreateWindow {
                Title = "AutoObby",
                SubTitle = "for Be NPC or Die",
                TabWidth = 160,
                Size = UDim2.fromOffset(400, 200),
                Resize = true,
                MinSize = Vector2.new(300, 150),
                Acrylic = true,
                Theme = "Dark",
                MinimizeKey = Enum.KeyCode.LeftControl
            }
        end)
        if not success then
            warn("AutoObby: Failed to create GUI window: " .. tostring(Window))
            return
        end

        local players = game:GetService("Players")
        local plr = players.LocalPlayer
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")

        local function getCharacter()
            local char = plr.Character or plr.CharacterAdded:Wait()
            local humPart = char:WaitForChild("HumanoidRootPart", 5)
            return char, humPart
        end

        local char, humPart = getCharacter()

        plr.CharacterAdded:Connect(function()
            char, humPart = getCharacter()
        end)

        -- Queue script reload on teleport to persist GUI
        local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
        if queueteleport then
            local scriptUrl = "https://raw.githubusercontent.com/Bac0nHck/Scripts/refs/heads/main/AutoObbyHardPersistentGUI.luau"
            queueteleport("loadstring(game:HttpGet('" .. scriptUrl .. "'))()")
            print("AutoObby: Script queued for next teleport automatically")
        else
            warn("AutoObby: Exploit does not support queue_on_teleport")
        end

        -- 🔥 Universal HTTP request wrapper
        local function httpRequest(options)
            local req = (syn and syn.request) or (http and http.request) or request or (fluxus and fluxus.request)
            if req then
                return req(options)
            else
                warn("AutoObby: No supported HTTP request function found in your executor!")
                return nil
            end
        end

        -- 🚀 Faster Server Hop
        local function serverHop()
            local servers = {}
            local cursor = ""

            repeat
                local success, result = pcall(function()
                    return httpRequest({
                        Url = "https://games.roblox.com/v1/games/" .. game.PlaceId ..
                            "/servers/Public?sortOrder=Asc&limit=100&cursor=" .. cursor,
                        Method = "GET",
                        Headers = {
                            ["Content-Type"] = "application/json"
                        }
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
                    warn("AutoObby: Failed to fetch servers, retrying...")
                    cursor = nil
                end
            until not cursor or #servers >= 20

            if #servers > 0 then
                table.sort(servers, function(a, b)
                    return a.playing < b.playing
                end)

                for _, server in ipairs(servers) do
                    local success, err = pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, plr)
                    end)
                    if success then
                        print("AutoObby: Hopping to server with " .. server.playing .. " players")
                        return
                    else
                        warn("AutoObby: Failed teleport: " .. tostring(err))
                        task.wait(0.2)
                    end
                end
            else
                warn("AutoObby: Still no servers found after fetch attempts 😭")
                -- fallback: teleport to same game, let Roblox decide
                TeleportService:Teleport(game.PlaceId, plr)
            end
        end

        local Tabs = {
            Main = Window:CreateTab {
                Title = "Main",
                Icon = "house"
            }
        }
        local Options = Library.Options

        local AutoObby = Tabs.Main:CreateToggle("AutoObby", {Title = "Auto Complete Obby", Default = true, Disabled = true})
        local AutoHardObby = Tabs.Main:CreateToggle("AutoHardObby", {Title = "Auto Complete Hard Obby", Default = true, Disabled = true})

        -- Track chest collection
        local collect = workspace:FindFirstChild("CollectableItems")
        local chestsCollected = {regular = false, hard = false}

        local function checkChests()
            if not collect then
                warn("AutoObby: CollectableItems not found in workspace")
                return false
            end

            local regularChestFound = false
            local hardChestFound = false

            for _, item in ipairs(collect:GetChildren()) do
                if item:GetAttribute("CannotSee") then
                    continue
                end
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
                print("AutoObby: Both chests collected, initiating server hop")
                serverHop()
            end

            return chestsCollected.regular and chestsCollected.hard
        end

        -- Combined function for fast continuous teleportation to both obbies
        local function runAutoObbies()
            while true do
                pcall(function()
                    if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
                        warn("AutoObby: Player or character not ready")
                        return
                    end

                    local lobby = workspace:FindFirstChild("Lobby")
                    local obby = lobby and lobby:FindFirstChild("Obby")
                    local obbyEndPart = obby and obby:FindFirstChild("ObbyEndPart")
                    local hardObbyEndPart = obby and obby:FindFirstChild("HardObbyEndPart")
                    if not obbyEndPart or not hardObbyEndPart then
                        warn("AutoObby: ObbyEndPart or HardObbyEndPart not found in workspace.Lobby.Obby")
                        return
                    end

                    -- Teleport to regular obby
                    plr.Character.HumanoidRootPart.CFrame = obbyEndPart.CFrame + Vector3.new(0, 3, 0)
                    if firetouchinterest then
                        firetouchinterest(plr.Character.HumanoidRootPart, obbyEndPart, 0)
                        task.wait(0.05)
                        firetouchinterest(plr.Character.HumanoidRootPart, obbyEndPart, 1)
                    end
                    print("AutoObby: Teleported to ObbyEndPart")

                    -- Teleport to hard obby
                    plr.Character.HumanoidRootPart.CFrame = hardObbyEndPart.CFrame + Vector3.new(0, 3, 0)
                    if firetouchinterest then
                        firetouchinterest(plr.Character.HumanoidRootPart, hardObbyEndPart, 0)
                        task.wait(0.05)
                        firetouchinterest(plr.Character.HumanoidRootPart, hardObbyEndPart, 1)
                    end
                    print("AutoObby: Teleported to HardObbyEndPart")

                    checkChests()
                end)
                task.wait(0.1)
            end
        end

        task.spawn(runAutoObbies)

        task.spawn(function()
            while true do
                checkChests()
                task.wait(1)
            end
        end)

        print("AutoObby: GUI initialized successfully")
        Window:SelectTab(1)
    end

    task.wait(5) -- ⏳ wait 5 seconds, then re-execute everything again
end
