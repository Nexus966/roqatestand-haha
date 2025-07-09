if not getgenv()._ or type(getgenv()._) ~= "string" or not getgenv()._:find("Add roqate to get latest update ok bai >.+ | If you pay for this script you get scammed, this script is completely free, if you remove this credit script wont work ok bai now") then
    game:GetService("Players").LocalPlayer:Kick("\n⚠️ Script tampering detected!\nThis script is free, don't remove credits.")
    while true do end 
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ChatService = game:GetService("Chat")
local TextChatService = game:GetService("TextChatService")
local localPlayer = Players.LocalPlayer

local FOLLOW_OFFSET = Vector3.new(0, 3, 5)
local MOVEMENT_SMOOTHNESS = 0.1
local PROTECTION_RADIUS = 15
local SUS_ANIMATION_R6 = "72042024"
local SUS_ANIMATION_R15 = "698251653"
local STAND_ANIMATION_ID = "10714347256"

local owners = {}
local heartbeatConnection = nil
local protectionConnection = nil
local standHumanoid = nil
local standPlatform = nil
local standAnimTrack = nil
local protectionActive = false
local flinging = false
local yeetForce = nil
local hidden = false
local hidePlatform = nil
local lastResponseTime = 0
local susTarget = nil
local susConnection = nil
local lastCommandTime = 0
local commandDelay = 0.5
local commandAbuseCount = {}

local function isR15(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.RigType == Enum.HumanoidRigType.R15
end

local function isOwner(player)
    for _, ownerName in ipairs(getgenv().Owners) do
        if player.Name == ownerName or (player.DisplayName and player.DisplayName == ownerName) then
            return true
        end
    end
    return false
end

local function isMainOwner(player)
    return player.Name == getgenv().Owners[1] or (player.DisplayName and player.DisplayName == getgenv().Owners[1])
end

local function isWhitelisted(player)
    if isOwner(player) then return true end
    local whitelist = getgenv().Configuration.whitelist or {}
    for _, name in ipairs(whitelist) do
        if player.Name == name or (player.DisplayName and player.DisplayName == name) then
            return true
        end
    end
    return false
end

local function createStandPlatform()
    if standPlatform then standPlatform:Destroy() end
    standPlatform = Instance.new("Part")
    standPlatform.Name = "StandPlatform"
    standPlatform.Anchored = true
    standPlatform.CanCollide = true
    standPlatform.Transparency = 1
    standPlatform.Size = Vector3.new(4, 1, 4)
    standPlatform.Parent = workspace
    return standPlatform
end

local function createHidePlatform()
    if hidePlatform then hidePlatform:Destroy() end
    hidePlatform = Instance.new("Part")
    hidePlatform.Name = "HidePlatform"
    hidePlatform.Anchored = true
    hidePlatform.CanCollide = true
    hidePlatform.Transparency = 0.5
    hidePlatform.Color = Color3.fromRGB(50, 50, 50)
    hidePlatform.Size = Vector3.new(10, 1, 10)
    hidePlatform.Parent = workspace
    return hidePlatform
end

local function disablePlayerMovement()
    if not localPlayer then return end
    pcall(function()
        localPlayer.DevEnableMouseLock = true
    end)
    if localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = false
            standHumanoid = humanoid
        end
    end
end

local function playStandAnimation()
    if not localPlayer.Character then return end
    local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if standAnimTrack then
        standAnimTrack:Stop()
        standAnimTrack = nil
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://"..STAND_ANIMATION_ID
    standAnimTrack = humanoid:LoadAnimation(anim)
    standAnimTrack.Priority = Enum.AnimationPriority.Action
    standAnimTrack:Play()
end

local function makeStandSpeak(message)
    if not localPlayer.Character then return end
    ChatService:Chat(localPlayer.Character:FindFirstChild("Head"), message, Enum.ChatColor.White)
    if TextChatService then
        TextChatService.TextChannels.RBXGeneral:SendAsync(message)
    end
end

local function findOwners()
    local foundOwners = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if isOwner(player) and player ~= localPlayer then
            table.insert(foundOwners, player)
        end
    end
    return foundOwners
end

local function findTarget(targetName)
    targetName = targetName:lower()
    local foundPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == localPlayer then continue end
        if player.Name:lower():sub(1, #targetName) == targetName then
            table.insert(foundPlayers, player)
        elseif player.DisplayName and player.DisplayName:lower():sub(1, #targetName) == targetName then
            table.insert(foundPlayers, player)
        end
    end
    if #foundPlayers == 1 then
        return foundPlayers[1]
    elseif #foundPlayers > 1 then
        makeStandSpeak("Multiple matches found!")
        return nil
    end
    return nil
end

local function getRoot(character)
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

local function flingPlayer(target)
    if not target or not target.Character or target == localPlayer or isWhitelisted(target) then return end
    if yeetForce then yeetForce:Destroy() end
    local targetRoot = getRoot(target.Character)
    local myRoot = getRoot(localPlayer.Character)
    if not targetRoot or not myRoot then return end
    yeetForce = Instance.new('BodyThrust', myRoot)
    yeetForce.Force = Vector3.new(9999,9999,9999)
    yeetForce.Name = "YeetForce"
    flinging = true
    makeStandSpeak("Target acquired!")
    spawn(function()
        repeat
            myRoot.CFrame = targetRoot.CFrame
            yeetForce.Location = targetRoot.Position
            RunService.Heartbeat:wait()
        until not target.Character:FindFirstChild("Head") or not flinging
        if yeetForce then
            yeetForce:Destroy()
            yeetForce = nil
        end
        flinging = false
    end)
end

local function findPlayerWithTool(toolName)
    toolName = toolName:lower()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == localPlayer then continue end
        if player.Character then
            for _, item in ipairs(player.Character:GetDescendants()) do
                if item:IsA("Tool") and item.Name:lower():find(toolName) then
                    return player
                end
            end
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                for _, item in ipairs(backpack:GetChildren()) do
                    if item:IsA("Tool") and item.Name:lower():find(toolName) then
                        return player
                    end
                end
            end
        end
    end
    return nil
end

local function findPlayersWithTool(toolName)
    local foundPlayers = {}
    toolName = toolName:lower()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == localPlayer then continue end
        if player.Character then
            for _, item in ipairs(player.Character:GetDescendants()) do
                if item:IsA("Tool") and item.Name:lower():find(toolName) then
                    table.insert(foundPlayers, player)
                    break
                end
            end
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                for _, item in ipairs(backpack:GetChildren()) do
                    if item:IsA("Tool") and item.Name:lower():find(toolName) then
                        table.insert(foundPlayers, player)
                        break
                    end
                end
            end
        end
    end
    return foundPlayers
end

local function startProtection()
    if protectionConnection then
        protectionConnection:Disconnect()
    end
    protectionActive = true
    makeStandSpeak("Protection activated!")
    protectionConnection = RunService.Heartbeat:Connect(function()
        if not localPlayer.Character or #owners == 0 then return end
        local myRoot = getRoot(localPlayer.Character)
        if not myRoot then return end
        for _, owner in ipairs(owners) do
            if owner.Character then
                local ownerRoot = getRoot(owner.Character)
                if ownerRoot then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= localPlayer and not isWhitelisted(player) and player.Character then
                            local targetRoot = getRoot(player.Character)
                            if targetRoot and (targetRoot.Position - ownerRoot.Position).Magnitude < PROTECTION_RADIUS then
                                flingPlayer(player)
                                break
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function stopProtection()
    protectionActive = false
    if protectionConnection then
        protectionConnection:Disconnect()
        protectionConnection = nil
    end
    makeStandSpeak("Protection deactivated!")
end

local function followOwners()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    createStandPlatform()
    disablePlayerMovement()
    playStandAnimation()
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if #owners == 0 or not localPlayer.Character then return end
        local myRoot = getRoot(localPlayer.Character)
        if not myRoot then return end
        for _, owner in ipairs(owners) do
            if owner.Character then
                local ownerRoot = getRoot(owner.Character)
                if ownerRoot then
                    local targetCF = ownerRoot.CFrame * CFrame.new(FOLLOW_OFFSET)
                    myRoot.CFrame = myRoot.CFrame:Lerp(targetCF, MOVEMENT_SMOOTHNESS)
                    if standPlatform then
                        standPlatform.CFrame = CFrame.new(myRoot.Position - Vector3.new(0, 3, 0))
                    end
                    break
                end
            end
        end
    end)
end

local function summonStand()
    if hidden then
        if hidePlatform then
            hidePlatform:Destroy()
            hidePlatform = nil
        end
        hidden = false
    end
    if #owners == 0 or not localPlayer.Character then return end
    local myHrp = getRoot(localPlayer.Character)
    if not myHrp then return end
    for _, owner in ipairs(owners) do
        if owner.Character then
            local ownerHrp = getRoot(owner.Character)
            if ownerHrp then
                myHrp.CFrame = ownerHrp.CFrame * CFrame.new(0, 0, FOLLOW_OFFSET.Z)
                disablePlayerMovement()
                playStandAnimation()
                break
            end
        end
    end
end

local function dismissStand()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    stopProtection()
    if standPlatform then
        standPlatform:Destroy()
        standPlatform = nil
    end
    if standAnimTrack then
        standAnimTrack:Stop()
        standAnimTrack = nil
    end
    if standHumanoid then
        standHumanoid.AutoRotate = true
    end
    if yeetForce then
        yeetForce:Destroy()
        yeetForce = nil
    end
    flinging = false
    makeStandSpeak("Resting for now...")
end

local function resetStand()
    if standPlatform then standPlatform:Destroy() end
    if yeetForce then yeetForce:Destroy() end
    flinging = false
    if localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
        localPlayer.CharacterAdded:Wait()
        if #owners > 0 then
            disablePlayerMovement()
            summonStand()
            makeStandSpeak("Reborn anew!")
        end
    else
        summonStand()
        makeStandSpeak("Reborn anew!")
    end
end

local function hideStand()
    if not localPlayer.Character then return end
    hidden = true
    local root = getRoot(localPlayer.Character)
    if not root then return end
    createHidePlatform()
    root.CFrame = CFrame.new(0, -500, 0)
    if hidePlatform then
        hidePlatform.CFrame = CFrame.new(0, -502, 0)
    end
    makeStandSpeak("Vanishing...")
end

local function stopSus()
    if susConnection then
        susConnection:Disconnect()
        susConnection = nil
    end
    if standAnimTrack then
        standAnimTrack:Stop()
        standAnimTrack = nil
    end
    susTarget = nil
    makeStandSpeak("Stopped sus behavior!")
    if #owners > 0 and localPlayer.Character then
        disablePlayerMovement()
    end
end
local function startSus(targetPlayer)
    if susTarget == targetPlayer then
        makeStandSpeak("Already sus-ing "..targetPlayer.Name.."!")
        return
    end
    stopSus()
    susTarget = targetPlayer
    makeStandSpeak("Initiating sus behavior on "..targetPlayer.Name.."!")
    
    if not localPlayer.Character then return end
    local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://"..(isR15(localPlayer) and SUS_ANIMATION_R15 or SUS_ANIMATION_R6)
    standAnimTrack = humanoid:LoadAnimation(anim)
    standAnimTrack.Priority = Enum.AnimationPriority.Action
    standAnimTrack:AdjustSpeed(isR15(localPlayer) and 4 or 6) 
    standAnimTrack:Play() 
    
    local lastLoopTime = tick()
    susConnection = RunService.Heartbeat:Connect(function()
        if not susTarget or not susTarget.Character or not localPlayer.Character then
            stopSus()
            return
        end
        
        local targetRoot = getRoot(susTarget.Character)
        local myRoot = getRoot(localPlayer.Character)
        if not targetRoot or not myRoot then return end
        
        local behindOffset = targetRoot.CFrame.LookVector * -3
        local targetPos = targetRoot.Position + behindOffset
        myRoot.CFrame = CFrame.new(targetPos, targetRoot.Position)
        
        if tick() - lastLoopTime > standAnimTrack.Length * 0.9 then
            standAnimTrack:Stop()
            standAnimTrack:Play() 
            lastLoopTime = tick()
        end
    end)
    
    localPlayer.CharacterRemoving:Connect(function()
        stopSus()
    end)
end

local function stealGun()
    if not localPlayer.Character then return end
    local currentGun = localPlayer.Character:FindFirstChild("Gun") or localPlayer.Backpack:FindFirstChild("Gun")
    if currentGun then
        makeStandSpeak("Already have a gun!")
        return
    end
    makeStandSpeak("Searching for gun...")
    local foundGun = nil
    local gunPosition = nil
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant.Name:lower() == "gun" and descendant:IsA("Tool") then
            foundGun = descendant
            gunPosition = descendant:FindFirstChild("Handle") and descendant.Handle.Position or descendant.Position
            break
        end
    end
    if not foundGun then
        makeStandSpeak("No gun found!")
        return
    end
    local myRoot = getRoot(localPlayer.Character)
    if not myRoot then return end
    makeStandSpeak("Found gun!")
    myRoot.CFrame = CFrame.new(gunPosition + Vector3.new(0, 3, 0))
    wait(0.5)
    foundGun.Parent = localPlayer.Character
    makeStandSpeak("Got gun!")
end

local function whitelistPlayer(playerName)
    table.insert(getgenv().Configuration.whitelist, playerName)
    makeStandSpeak("Added "..playerName.." to whitelist!")
end

local function addOwner(playerName)
    table.insert(getgenv().Owners, playerName)
    owners = findOwners()
    if #owners > 0 then
        followOwners()
    end
    makeStandSpeak("Added "..playerName.." as owner!")
end

local function removeOwner(playerName)
    for i, name in ipairs(getgenv().Owners) do
        if name == playerName then
            table.remove(getgenv().Owners, i)
            break
        end
    end
    owners = findOwners()
    makeStandSpeak("Removed "..playerName.." from owners!")
end

local function stringContainsAny(str, patterns)
    str = str:lower()
    for _, pattern in ipairs(patterns) do
        if str:find(pattern) then
            return true
        end
    end
    return false
end

local function checkCommandAbuse(speaker)
    if not isOwner(speaker) then return false end
    local currentTime = tick()
    commandAbuseCount[speaker.Name] = commandAbuseCount[speaker.Name] or {count = 0, lastTime = 0}
    local abuseData = commandAbuseCount[speaker.Name]
    
    if currentTime - abuseData.lastTime < 1 then
        abuseData.count = abuseData.count + 1
        if abuseData.count >= 1 then
            local warningsLeft = 3 - abuseData.count
            if warningsLeft > 0 then
                makeStandSpeak("Warning "..speaker.Name..": You have "..warningsLeft.." more warning(s) before removal!")
            else
                removeOwner(speaker.Name)
                makeStandSpeak(speaker.Name.." has been removed from admin for command abuse!")
                commandAbuseCount[speaker.Name] = nil
            end
            return true
        end
    else
        abuseData.count = 0
    end
    abuseData.lastTime = currentTime
    return false
end

local function respondToChat(speaker, message)
    if speaker == localPlayer then return end
    if tick() - lastResponseTime < 5 then return end
    local msg = message:lower()
    if msg:find("good boy") then
        makeStandSpeak("Yes I'm a good boy!")
        lastResponseTime = tick()
        return
    end
    if msg:find("roqate") then
        makeStandSpeak("All glory to Roqate!")
        lastResponseTime = tick()
        return
    end
    local responsePatterns = {
        {
            patterns = {"whats that", "what is that", "what is this", "what are you"},
            responses = {
                "I am The World!",
                "A manifestation of power!",
                "My king's will made manifest!"
            }
        },
        {
            patterns = {"exploit", "hack", "cheat", "exp"},
            responses = {
                "How dare you accuse my king! I don't exploit!",
                "This is pure stand power! I dont cheat!",
                "Such disrespect! I'm not a cheater!"
            }
        },
        {
            patterns = {"unfair", "not fair", "broken"},
            responses = {
                "Life isn't fair!",
                "My king plays by his own rules!",
                "Complain to the cosmos!"
            }
        },
        {
            patterns = {"how you do", "how did you", "how does this"},
            responses = {
                "Through the power of The World!",
                "Mysterious ways!",
                "Stand magic!"
            }
        },
        {
            patterns = {"script", "code", "made this", "who made"},
            responses = {
                "My existence is by royal decree!",
                "Only the worthy command such power!",
                "My king's will sustains me!"
            }
        },
        {
            patterns = {"roqate", "roq", "king"},
            responses = {
                "You speak of my glorious liege!",
                "All praise Roqate!",
                "My king's power knows no bounds!"
            }
        },
        {
            patterns = {"murder", "murderer", "killer", "murd"},
            responses = function()
                local murderers = findPlayersWithTool("Knife")
                if #murderers > 0 then
                    local names = ""
                    for i, player in ipairs(murderers) do
                        if isWhitelisted(player) then
                            return "I don't wanna snitch."
                        end
                        names = names .. player.Name
                        if i < #murderers then
                            names = names .. ", "
                        end
                    end
                    return "Murderer: " .. names .. "!"
                else
                    return "No murderer found..."
                end
            end
        },
        {
            patterns = {"sheriff", "sherif"},
            responses = function()
                local sheriffs = findPlayersWithTool("Gun")
                if #sheriffs > 0 then
                    local names = ""
                    for i, player in ipairs(sheriffs) do
                        if isWhitelisted(player) then
                            return "I don't wanna snitch."
                        end
                        names = names .. player.Name
                        if i < #sheriffs then
                            names = names .. ", "
                        end
                    end
                    return "Sheriff: " .. names .. "!"
                else
                    return "No law around here!"
                end
            end
        }
    }
    for _, responseGroup in ipairs(responsePatterns) do
        if stringContainsAny(msg, responseGroup.patterns) then
            local response
            if type(responseGroup.responses) == "function" then
                response = responseGroup.responses()
            else
                response = responseGroup.responses[math.random(1, #responseGroup.responses)]
            end
            makeStandSpeak(response)
            lastResponseTime = tick()
            return
        end
    end
end

local function processCommand(speaker, message)
    if not message then return end
    local commandPrefix = message:match("^[%.!]")
    if not commandPrefix then return end
    if tick() - lastCommandTime < commandDelay then return end
    lastCommandTime = tick()
    
    if not isOwner(speaker) then
        makeStandSpeak("Hey "..speaker.Name..", unfortunately you can't use the commands. Ask "..getgenv().Owners[1].." for them. You can pay 100 robux or 1 godly.")
        return
    end
    
    if checkCommandAbuse(speaker) then return end
    
    local args = {}
    for word in message:gmatch("%S+") do
        table.insert(args, word)
    end
    local cmd = args[1]:lower()

    if cmd == ".follow" and args[2] then
        local targetName = args[2]:lower()
        if targetName == "murder" then
            local target = findPlayerWithTool("Knife")
            if target then
                owners = {target}
                followOwners()
                makeStandSpeak("Tracking murderer!")
            else
                makeStandSpeak("No murderer found")
            end
        elseif targetName == "sheriff" then
            local target = findPlayerWithTool("Gun")
            if target then
                owners = {target}
                followOwners()
                makeStandSpeak("Following sheriff!")
            else
                makeStandSpeak("No sheriff found")
            end
        else
            local target = findTarget(table.concat(args, " ", 2))
            if target then
                owners = {target}
                followOwners()
                makeStandSpeak("Following "..target.Name)
            else
                makeStandSpeak("Target not found")
            end
        end
    elseif cmd == ".protect" and args[2] then
        if args[2]:lower() == "on" then
            startProtection()
        elseif args[2]:lower() == "off" then
            stopProtection()
        end
    elseif cmd == ".say" and args[2] then
        makeStandSpeak(table.concat(args, " ", 2))
    elseif cmd == ".reset" then
        resetStand()
    elseif cmd == ".hide" then
        hideStand()
    elseif cmd == ".dismiss" then
        dismissStand()
    elseif cmd == ".summon" then
        summonStand()
    elseif cmd == ".fling" and args[2] then
        local targetName = args[2]:lower()
        if targetName == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and not isWhitelisted(player) then
                    spawn(function() flingPlayer(player) end)
                end
            end
            makeStandSpeak("Launching everyone!")
        elseif targetName == "murder" then
            local target = findPlayerWithTool("Knife")
            if target and not isWhitelisted(target) then
                flingPlayer(target)
                makeStandSpeak("Eliminating murderer!")
            else
                makeStandSpeak("No murderer found")
            end
        elseif targetName == "sheriff" then
            local target = findPlayerWithTool("Gun")
            if target and not isWhitelisted(target) then
                flingPlayer(target)
                makeStandSpeak("Taking down sheriff!")
            else
                makeStandSpeak("No sheriff found")
            end
        else
            local target = findTarget(table.concat(args, " ", 2))
            if target and not isWhitelisted(target) then
                flingPlayer(target)
                makeStandSpeak("Target locked!")
            else
                makeStandSpeak("Target not found")
            end
        end
    elseif cmd == ".stealgun" then
        stealGun()
    elseif cmd == ".whitelist" and args[2] then
        local target = findTarget(table.concat(args, " ", 2))
        if target then
            whitelistPlayer(target.Name)
        else
            makeStandSpeak("Player not found")
        end
    elseif cmd == ".addowner" and args[2] then
        local target = findTarget(table.concat(args, " ", 2))
        if target then
            addOwner(target.Name)
        else
            makeStandSpeak("Player not found")
        end
    elseif cmd == ".addadmin" and args[2] then
        if not isMainOwner(speaker) then
            makeStandSpeak("Only "..getgenv().Owners[1].." can use this command!")
            return
        end
        local target = findTarget(table.concat(args, " ", 2))
        if target then
            addOwner(target.Name)
        else
            makeStandSpeak("Player not found")
        end
    elseif cmd == ".removeadmin" and args[2] then
        if not isMainOwner(speaker) then
            makeStandSpeak("Only "..getgenv().Owners[1].." can use this command!")
            return
        end
        local target = findTarget(table.concat(args, " ", 2))
        if target then
            removeOwner(target.Name)
        else
            makeStandSpeak("Player not found")
        end
    elseif cmd == ".sus" and args[2] then
        local targetName = args[2]:lower()
        if targetName == "murder" then
            local target = findPlayerWithTool("Knife")
            if target then
                startSus(target)
            else
                makeStandSpeak("No murderer found")
            end
        elseif targetName == "sheriff" then
            local target = findPlayerWithTool("Gun")
            if target then
                startSus(target)
            else
                makeStandSpeak("No sheriff found")
            end
        else
            local target = findTarget(table.concat(args, " ", 2))
            if target then
                startSus(target)
            else
                makeStandSpeak("Target not found")
            end
        end
    elseif cmd == ".stopsus" then
        stopSus()
    end
end

local function setupChatListeners()
    for _, player in ipairs(Players:GetPlayers()) do
        player.Chatted:Connect(function(message)
            respondToChat(player, message)
            processCommand(player, message)
        end)
    end
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            respondToChat(player, message)
            processCommand(player, message)
        end)
    end)
end

if localPlayer then
    owners = findOwners()
    if #owners > 0 then
        disablePlayerMovement()
        followOwners()
        makeStandSpeak(getgenv().Configuration.Msg)
    end
    setupChatListeners()
    script.Destroying:Connect(function()
        dismissStand()
        stopSus()
    end)
else
    warn("LocalPlayer not found!")
end
