local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ChatService = game:GetService("Chat")
local TextChatService = game:GetService("TextChatService")

local isStudio = game:GetService("RunService"):IsStudio()
local OWNER_NAME = getgenv().Owner or (isStudio and "Player1" or "Roqate")
local localPlayer = Players.LocalPlayer

local FOLLOW_OFFSET = Vector3.new(0, 3, 5)
local MOVEMENT_SMOOTHNESS = 0.2
local PROTECTION_RADIUS = 15
local STAND_ANIMATION_ID = "10714347256"

local owner = nil
local heartbeatConnection = nil
local chattedConnection = nil
local protectionConnection = nil
local standHumanoid = nil
local standPlatform = nil
local standAnimTrack = nil
local protectionActive = false
local flinging = false
local yeetForce = nil
local hidden = false
local hidePlatform = nil
local allChatConnections = {}
local lastResponseTime = 0

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

local function loadAnimation(humanoid)
    if standAnimTrack then standAnimTrack:Stop() end
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://"..STAND_ANIMATION_ID
    standAnimTrack = humanoid:LoadAnimation(animation)
    standAnimTrack.Priority = Enum.AnimationPriority.Action
    standAnimTrack:Play()
    standAnimTrack.Looped = true
end

local function disablePlayerMovement()
    if not localPlayer then return end
    pcall(function()
        localPlayer.DevEnableMouseLock = true
        UserInputService.MoveConnected = false
    end)
    if localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = false
            standHumanoid = humanoid
            loadAnimation(humanoid)
        end
    end
end

local function makeStandSpeak(message)
    if not localPlayer.Character then return end
    ChatService:Chat(localPlayer.Character:FindFirstChild("Head"), message, Enum.ChatColor.White)
    if TextChatService then
        TextChatService.TextChannels.RBXGeneral:SendAsync(message)
    end
end

local function findOwner()
    if isStudio then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name == "Player1" and player ~= localPlayer then
                return player
            end
        end
        return nil
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if (player.Name == OWNER_NAME or player.DisplayName == OWNER_NAME) and player ~= localPlayer then
            return player
        end
    end
    return nil
end

local function findTarget(targetName)
    targetName = targetName:lower()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == localPlayer then continue end
        if player.Name:lower():find(targetName) then
            return player
        end
        if player.DisplayName and player.DisplayName:lower():find(targetName) then
            return player
        end
    end
    return nil
end

local function getRoot(character)
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

local function flingPlayer(target)
    if not target or not target.Character or target == localPlayer then return end
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
    makeStandSpeak("Protection activated! No harm shall come to my king!")
    protectionConnection = RunService.Heartbeat:Connect(function()
        if not localPlayer.Character or not owner or not owner.Character then return end
        local myRoot = getRoot(localPlayer.Character)
        local ownerRoot = getRoot(owner.Character)
        if not myRoot or not ownerRoot then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player ~= owner and player.Character then
                local targetRoot = getRoot(player.Character)
                if targetRoot and (targetRoot.Position - ownerRoot.Position).Magnitude < PROTECTION_RADIUS then
                    flingPlayer(player)
                    break
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

local function followOwner()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    createStandPlatform()
    if localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            loadAnimation(humanoid)
        end
    end
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not owner or not owner.Character or not localPlayer.Character then return end
        local ownerHrp = getRoot(owner.Character)
        local myHrp = getRoot(localPlayer.Character)
        if not ownerHrp or not myHrp then return end
        local targetCFrame = ownerHrp.CFrame * CFrame.new(FOLLOW_OFFSET)
        targetCFrame = CFrame.new(targetCFrame.Position, ownerHrp.Position + ownerHrp.CFrame.LookVector * 10)
        myHrp.CFrame = myHrp.CFrame:Lerp(targetCFrame, MOVEMENT_SMOOTHNESS)
        if standPlatform then
            standPlatform.CFrame = CFrame.new(myHrp.Position - Vector3.new(0, 3, 0))
        end
        local ownerHumanoid = owner.Character:FindFirstChildOfClass("Humanoid")
        if standHumanoid and ownerHumanoid then
            standHumanoid:ChangeState(ownerHumanoid:GetState())
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
    if not owner or not owner.Character then return end
    local ownerHrp = getRoot(owner.Character)
    if not ownerHrp then return end
    if localPlayer.Character then
        local myHrp = getRoot(localPlayer.Character)
        if myHrp then
            local targetCFrame = ownerHrp.CFrame * CFrame.new(FOLLOW_OFFSET)
            myHrp.CFrame = targetCFrame
            loadAnimation(localPlayer.Character:FindFirstChildOfClass("Humanoid"))
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
    UserInputService.MoveConnected = true
    makeStandSpeak("Resting for now... but always watching")
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

        if owner and owner.Character then
            disablePlayerMovement()
            summonStand()
            makeStandSpeak("Reborn anew! Ready to serve!")
        end
    else
        summonStand()
        makeStandSpeak("Reborn anew! Ready to serve!")
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
    makeStandSpeak("Vanishing into the void... but still watching")
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

local function respondToChat(speaker, message)
    if speaker == localPlayer then return end
    if tick() - lastResponseTime < 5 then return end

    local msg = message:lower()

    local responsePatterns = {
        {
            patterns = {"whats that", "what is that", "what is this", "what are you"},
            responses = {
                "I am The World, the ultimate stand!",
                "A manifestation of pure power!",
                "My king's will made manifest!"
            }
        },
        {
            patterns = {"exploit", "hack", "cheat", "exp"},
            responses = {
                "How dare you accuse my king!",
                "This is pure stand power!",
                "Such disrespect will not be tolerated!"
            }
        },
        {
            patterns = {"unfair", "not fair", "broken"},
            responses = {
                "Life isn't fair, mortal!",
                "My king plays by his own rules!",
                "Complain to the cosmos!"
            }
        },
        {
            patterns = {"how you do", "how did you", "how does this"},
            responses = {
                "Through the power of The World!",
                "Mysterious ways beyond your understanding!",
                "Stand magic is beyond mortal comprehension!"
            }
        },
        {
            patterns = {"script", "code", "made this", "who made"},
            responses = {
                "My existence is by royal decree!",
                "Only the worthy command such power!",
                "My king's will alone sustains me!"
            }
        },
        {
            patterns = {"roqate", "your master", "your king"},
            responses = {
                "You speak of my glorious liege!",
                "All praise the mighty Roqate!",
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
                        names = names .. player.Name
                        if i < #murderers then
                            names = names .. ", "
                        end
                    end
                    return "The murderer is: " .. names .. "! Watch your back!"
                else
                    return "No murderer found... or are they hiding?"
                end
            end
        },
        {
            patterns = {"sheriff", "cop", "police"},
            responses = function()
                local sheriffs = findPlayersWithTool("Gun")
                if #sheriffs > 0 then
                    local names = ""
                    for i, player in ipairs(sheriffs) do
                        names = names .. player.Name
                        if i < #sheriffs then
                            names = names .. ", "
                        end
                    end
                    return "The sheriff is: " .. names .. "! Better behave!"
                else
                    return "No law around here! It's the wild west!"
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

local function setupChatListeners()
    for _, connection in ipairs(allChatConnections) do
        connection:Disconnect()
    end
    allChatConnections = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            table.insert(allChatConnections, player.Chatted:Connect(function(message)
                respondToChat(player, message)
            end))
        end
    end

    table.insert(allChatConnections, Players.PlayerAdded:Connect(function(player)
        table.insert(allChatConnections, player.Chatted:Connect(function(message)
            respondToChat(player, message)
        end))
    end))
end

local function mouse1click()
    if not localPlayer or not localPlayer:GetMouse() then return end
    
    local mouse = localPlayer:GetMouse()
    local tool = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Tool")
    
    if tool then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://3189777795"
                local track = animator:LoadAnimation(animation)
                track:Play()
            end
        end
        
        local handle = tool:FindFirstChild("Handle")
        if handle then
            local sound = handle:FindFirstChildOfClass("Sound")
            if sound then
                sound:Play()
            end
        end
    end
end

local function processCommand(message)
    if not message or not message:sub(1, 1) == "." then return end
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
                OWNER_NAME = target.Name
                owner = target
                followOwner()
                makeStandSpeak("Tracking the murderer! They won't escape!")
            else
                makeStandSpeak("No murderer found... scanning again")
            end
        elseif targetName == "sheriff" then
            local target = findPlayerWithTool("Gun")
            if target then
                OWNER_NAME = target.Name
                owner = target
                followOwner()
                makeStandSpeak("Following the sheriff! Maintaining order!")
            else
                makeStandSpeak("No sheriff found... scanning again")
            end
        else
            local searchName = table.concat(args, " ", 2):lower()
            local foundPlayer = nil
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    if player.Name:lower():sub(1, #searchName) == searchName or 
                       (player.DisplayName and player.DisplayName:lower():sub(1, #searchName) == searchName) then
                        foundPlayer = player
                        break
                    end
                end
            end
            
            if foundPlayer then
                OWNER_NAME = foundPlayer.Name
                owner = foundPlayer
                followOwner()
                makeStandSpeak("Following "..foundPlayer.Name.." with absolute loyalty!")
            else
                makeStandSpeak("Target not found... scanning again")
            end
        end
    elseif cmd == ".eliminate" and args[2] then
        local targetType = args[2]:lower()
        
        if targetType == "all" then
            makeStandSpeak("Initiating elimination protocol for all players!")
            
            spawn(function()
                local originalOwner = owner
                local originalOffset = FOLLOW_OFFSET
                
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= localPlayer and player.Character then
                        local knife = localPlayer.Backpack:FindFirstChild("Knife") or 
                                     localPlayer.Character:FindFirstChild("Knife")
                        
                        if knife then
                            local targetRoot = getRoot(player.Character)
                            local myRoot = getRoot(localPlayer.Character)
                            
                            if targetRoot and myRoot then
                                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
                                
                                knife.Parent = localPlayer.Character
                                wait(0.1)
                                
                                local mouse = localPlayer:GetMouse()
                                if mouse then
                                    for i = 1, 3 do
                                        mouse1click()
                                        wait(0.3)
                                    end
                                end
                                
                                wait(1)
                            end
                        end
                    end
                end
                
                makeStandSpeak("Elimination complete! Good game!")
                
                if originalOwner then
                    owner = originalOwner
                    followOwner()
                end
            end)
            
        elseif targetType == "murder" then
            makeStandSpeak("Hunting down the murderer!")
            
            spawn(function()
                local target = findPlayerWithTool("Knife")
                if target and target.Character then
                    local gun = localPlayer.Backpack:FindFirstChild("Gun") or 
                                 localPlayer.Character:FindFirstChild("Gun")
                    
                    if gun then
                        local targetRoot = getRoot(target.Character)
                        local myRoot = getRoot(localPlayer.Character)
                        
                        if targetRoot and myRoot then
                            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
                            
                            gun.Parent = localPlayer.Character
                            wait(0.1)
                            
                            local mouse = localPlayer:GetMouse()
                            if mouse then
                                for i = 1, 5 do
                                    mouse1click()
                                    wait(0.5)
                                end
                            end
                            
                            makeStandSpeak("Murderer eliminated! Justice served!")
                        end
                    else
                        makeStandSpeak("No gun found in inventory!")
                    end
                else
                    makeStandSpeak("No murderer found to eliminate!")
                end
            end)
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
        makeStandSpeak("Appearing at my king's side!")
    elseif cmd == ".fling" and args[2] then
        local targetName = args[2]:lower()
        if targetName == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    spawn(function() flingPlayer(player) end)
                end
            end
            makeStandSpeak("Launching everyone to the stratosphere!")
        elseif targetName == "murder" then
            local target = findPlayerWithTool("Knife")
            if target then
                flingPlayer(target)
                makeStandSpeak("Eliminating the murderer! No witnesses!")
            else
                makeStandSpeak("No murderer found... they must be hiding")
            end
        elseif targetName == "sheriff" then
            local target = findPlayerWithTool("Gun")
            if target then
                flingPlayer(target)
                makeStandSpeak("Taking down the sheriff! Anarchy reigns!")
            else
                makeStandSpeak("No law around here! The wild west continues!")
            end
        else
            local target = findTarget(table.concat(args, " ", 2))
            if target then
                flingPlayer(target)
                makeStandSpeak("Target locked! Say hello to the sky!")
            else
                makeStandSpeak("Target not found... scanning again")
            end
        end
    end
end

if localPlayer then
    if isStudio and localPlayer.Name == "Player2" then
        disablePlayerMovement()
        owner = findOwner()
        if owner then
            followOwner()
            makeStandSpeak("The World stands ready to serve!")
        end
    elseif not isStudio then
        disablePlayerMovement()
        owner = findOwner()
        if owner then
            followOwner()
            makeStandSpeak("The World stands ready to serve!")
        end
    end

    setupChatListeners()

    if owner then
        chattedConnection = owner.Chatted:Connect(function(message)
            processCommand(message)
        end)
    end

    script.Destroying:Connect(function()
        dismissStand()
        if chattedConnection then
            chattedConnection:Disconnect()
        end
        for _, connection in ipairs(allChatConnections) do
            connection:Disconnect()
        end
    end)
else
    warn("LocalPlayer not found!")
end
