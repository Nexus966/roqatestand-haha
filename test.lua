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
local afkPlayers = {}
local lastCommandsTime = 0
local commandsDelay = 30
local disabledCommands = {}
local commandCooldowns = {}
local commandAbuseWarnings = {}
local lastMovementCheck = {}
local suspendedPlayers = {}
local rudePlayers = {}
local rudePhrases = {"pmo", "sybau", "syfm", "stfu", "kys", "idc", "suck my","shut"}
local randomTargets = {}
local activeCommand = nil

local function getMainOwner()
	for _, ownerName in ipairs(getgenv().Owners) do
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Name == ownerName or (player.DisplayName and player.DisplayName == ownerName) then
				return player
			end
		end
	end
	return nil
end

local function stopActiveCommand()
	if activeCommand == "fling" and yeetForce then
		yeetForce:Destroy()
		yeetForce = nil
	elseif activeCommand == "sus" and susConnection then
		susConnection:Disconnect()
		susConnection = nil
	elseif activeCommand == "eliminate" then
		if localPlayer.Character then
			local knife = localPlayer.Character:FindFirstChild("Knife")
			if knife then knife.Parent = localPlayer.Backpack end
		end
	end
	flinging = false
	activeCommand = nil
end

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
	local mainOwner = getMainOwner()
	if not mainOwner then return false end
	return player.Name == mainOwner.Name or (player.DisplayName and player.DisplayName == mainOwner.Name)
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

local function getRandomPlayer()
	local players = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			table.insert(players, player)
		end
	end
	if #players > 0 then
		return players[math.random(1, #players)]
	end
	return nil
end

local function getRoot(character)
	return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

local function flingPlayer(target)
	stopActiveCommand()
	activeCommand = "fling"

	if not target or target == localPlayer then return end
	if yeetForce then yeetForce:Destroy() end

	local function continuousFling()
		while activeCommand == "fling" and target and target.Parent do
			if not target.Character then
				target.CharacterAdded:Wait()
			end

			local targetRoot = getRoot(target.Character)
			local myRoot = getRoot(localPlayer.Character)
			if not targetRoot or not myRoot then
				task.wait(1)
				continue
			end

			yeetForce = Instance.new('BodyThrust', myRoot)
			yeetForce.Force = Vector3.new(9999,9999,9999)
			yeetForce.Name = "YeetForce"
			flinging = true

			local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				task.wait(1)
				continue
			end

			myRoot.CFrame = targetRoot.CFrame
			yeetForce.Location = targetRoot.Position

			RunService.Heartbeat:Wait()
		end

		if yeetForce then
			yeetForce:Destroy()
			yeetForce = nil
		end
		flinging = false
	end

	spawn(continuousFling)
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
						if player ~= localPlayer and player.Character then
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

local function summonStand(speaker)
	if hidden then
		if hidePlatform then
			hidePlatform:Destroy()
			hidePlatform = nil
		end
		hidden = false
	end
	if not localPlayer.Character then return end
	local myHrp = getRoot(localPlayer.Character)
	if not myHrp then return end

	if speaker and speaker.Character then
		local speakerHrp = getRoot(speaker.Character)
		if speakerHrp then
			myHrp.CFrame = speakerHrp.CFrame * CFrame.new(0, 0, FOLLOW_OFFSET.Z)
			disablePlayerMovement()
			playStandAnimation()
			makeStandSpeak("Summoned by "..speaker.Name)
			return
		end
	end

	if #owners > 0 then
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
	for playerName, _ in pairs(rudePlayers) do
		rudePlayers[playerName] = nil
	end
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
	if workspace.CurrentCamera then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		if localPlayer.Character then
			workspace.CurrentCamera.CameraSubject = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		end
	end
	makeStandSpeak("Stopped sus behavior!")
end

local function startSus(targetPlayer, speed)
	stopActiveCommand()
	activeCommand = "sus"

	if susTarget == targetPlayer then
		makeStandSpeak("Already sus-ing "..targetPlayer.Name.."!")
		return
	end
	susTarget = targetPlayer
	makeStandSpeak("ULTRA SPEED sus on "..targetPlayer.Name..(speed and " at speed "..speed or "").."!")

	if not localPlayer.Character then return end
	local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://"..(isR15(localPlayer) and SUS_ANIMATION_R15 or SUS_ANIMATION_R6)
	standAnimTrack = humanoid:LoadAnimation(anim)
	standAnimTrack.Priority = Enum.AnimationPriority.Action4
	standAnimTrack.Looped = true

	standAnimTrack:AdjustSpeed(speed or (isR15(localPlayer) and 0.7 or 0.65))
	if standAnimTrack then
		standAnimTrack:Play()
	end

	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	susConnection = RunService.RenderStepped:Connect(function()
		if activeCommand ~= "sus" or not susTarget or not susTarget.Character or not localPlayer.Character then
			stopSus()
			return
		end

		local targetRoot = getRoot(susTarget.Character)
		local myRoot = getRoot(localPlayer.Character)
		if not targetRoot or not myRoot then return end

		local lookVector = targetRoot.CFrame.LookVector
		local targetPos = targetRoot.Position - (lookVector * 2)
		myRoot.CFrame = CFrame.new(targetPos, targetRoot.Position)

		if camera and camera.CameraType == Enum.CameraType.Scriptable then
			camera.CFrame = CFrame.new(myRoot.Position + Vector3.new(0, 3, -5), myRoot.Position)
		end

		if standAnimTrack then
			standAnimTrack.TimePosition = 0.6
			task.wait(0.1)
			while standAnimTrack and standAnimTrack.TimePosition < (isR15(localPlayer) and 0.7 or 0.65) do 
				task.wait(0.1) 
			end
			if standAnimTrack then
				standAnimTrack:Stop()
				standAnimTrack = nil
			end
		end
	end)

	localPlayer.CharacterRemoving:Connect(stopSus)
end

local function equipKnife()
	if not localPlayer.Character then return false end
	local knife = localPlayer.Backpack:FindFirstChild("Knife") or localPlayer.Character:FindFirstChild("Knife")
	if knife then
		knife.Parent = localPlayer.Character
		return true
	end
	return false
end

local function simulateClick()
	local knife = localPlayer.Character:FindFirstChild("Knife")
	if knife and knife:FindFirstChild("Handle") then
		local remote = knife:FindFirstChildOfClass("RemoteEvent") or knife:FindFirstChildOfClass("RemoteFunction")
		if remote then
			remote:FireServer(knife.Handle.CFrame)
		end
	end
end

local function eliminatePlayers()
	stopActiveCommand()
	activeCommand = "eliminate"

	if not equipKnife() then
		makeStandSpeak("No knife found!")
		return
	end

	makeStandSpeak("Initiating elimination protocol!")
	local knife = localPlayer.Character:FindFirstChild("Knife")
	if not knife then return end

	local eliminated = {}
	local startTime = tick()

	while activeCommand == "eliminate" do
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer and player.Character then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					local root = getRoot(player.Character)
					local myRoot = getRoot(localPlayer.Character)
					if root and myRoot then
						myRoot.CFrame = root.CFrame * CFrame.new(0, 0, -2)
						for i = 1, 20 do
							simulateClick()
							task.wait(0.01)
						end
					end
				end
			end
		end
		task.wait(0.1)
	end

	if knife then knife.Parent = localPlayer.Backpack end
	makeStandSpeak("Elimination protocol complete!")
end

local function winGame(targetPlayer)
	stopActiveCommand()

	if not targetPlayer or targetPlayer == localPlayer then return end
	makeStandSpeak("Making "..targetPlayer.Name.." the winner!")

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player ~= targetPlayer then
			flingPlayer(player)
		end
	end
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
	task.wait(0.5)
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

local function disableCommand(cmd)
	disabledCommands[cmd:lower()] = true
	makeStandSpeak("Command "..cmd.." has been disabled!")
end

local function enableCommand(cmd)
	disabledCommands[cmd:lower()] = nil
	makeStandSpeak("Command "..cmd.." has been enabled!")
end

local function isCommandDisabled(cmd)
	return disabledCommands[cmd:lower()] == true
end

local function suspendPlayer(playerName, duration)
	local mainOwner = getMainOwner()
	if mainOwner and playerName == mainOwner.Name then return end
	suspendedPlayers[playerName] = os.time() + duration
	makeStandSpeak(playerName.." has been suspended for "..duration.." seconds!")
end

local function isPlayerSuspended(playerName)
	local mainOwner = getMainOwner()
	if mainOwner and playerName == mainOwner.Name then return false end
	if suspendedPlayers[playerName] then
		if os.time() < suspendedPlayers[playerName] then
			return true
		else
			suspendedPlayers[playerName] = nil
			return false
		end
	end
	return false
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

local function getColorName(color)
	local r, g, b = color.R * 255, color.G * 255, color.B * 255

	if r > 240 and g > 240 and b > 240 then return "White" end
	if r < 30 and g < 30 and b < 30 then return "Black" end

	if math.abs(r - g) < 10 and math.abs(g - b) < 10 then
		if r > 180 then return "Light Gray" end
		if r > 100 then return "Gray" end
		return "Dark Gray"
	end

	if r > 180 and g > 140 and b < 120 then return "Peach" end
	if r > 160 and g > 110 and b < 90 then return "Tan" end
	if r > 120 and g > 80 and b < 60 then return "Brown" end
	if r > 90 and g > 60 and b < 40 then return "Dark Brown" end

	if r > 200 and g > 100 and b < 100 then return "Orange" end
	if r > 200 and g < 80 and b < 80 then return "Red" end
	if g > 200 and r < 100 and b < 100 then return "Green" end
	if b > 200 and r < 100 and g < 100 then return "Blue" end
	if r > 180 and b > 180 and g < 100 then return "Pink" end
	if r > 150 and b > 150 and g > 150 then return "Pastel" end

	if r > g and b > g then return "Purple" end
	if g > r and b > r then return "Teal" end
	if r > b and g > b then return "Yellow" end

	return "Unknown"
end

local function describePlayer(targetType)
    local target
    if targetType == "murder" then
        target = findPlayerWithTool("Knife")
    elseif targetType == "sheriff" then
        target = findPlayerWithTool("Gun")
    else
        return "Invalid target type! Use 'murder' or 'sheriff'"
    end
    
    if not target then
        return "No "..targetType.." found!"
    end
    
    local color = "Unknown"
    if target.Character then
        local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            color = getColorName(humanoid.BodyColors.HeadColor3)
        end
    end
    
    local clothingItems = {}
    if target.Character then
        for _, item in ipairs(target.Character:GetChildren()) do
            if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                local itemName = item.Name
                if #itemName > 15 then
                    itemName = itemName:match("%w+") or itemName:sub(1, 15)
                end
                table.insert(clothingItems, item.ClassName..": "..itemName)
            end
        end
    end
    
    local accessories = {}
    if target.Character then
        for _, item in ipairs(target.Character:GetChildren()) do
            if item:IsA("Accessory") then
                local itemName = item.Name
                if #itemName > 15 then
                    itemName = itemName:match("%w+") or itemName:sub(1, 15)
                end
                table.insert(accessories, "Accessory: "..itemName)
            end
        end
    end
    
    local description = targetType:upper()..": "..target.Name.." | Color: "..color
    
    if #clothingItems > 0 then
        description = description.." | Wearing: "..table.concat(clothingItems, ", ")
    end
    
    if #accessories > 0 then
        description = description.." | Accessories: "..table.concat(accessories, ", ")
    end
    
    return description
end

local function checkCommandAbuse(speaker)
	if not isOwner(speaker) then return false end
	local mainOwner = getMainOwner()
	if mainOwner and speaker.Name == mainOwner.Name then return false end

	if isPlayerSuspended(speaker.Name) then
		local remaining = suspendedPlayers[speaker.Name] - os.time()
		makeStandSpeak(speaker.Name.." is suspended for "..remaining.." more seconds!")
		return true
	end

	local currentTime = os.time()
	commandAbuseCount[speaker.Name] = commandAbuseCount[speaker.Name] or {count = 0, lastTime = 0, warnings = 0}
	local abuseData = commandAbuseCount[speaker.Name]

	if currentTime - abuseData.lastTime < 10 then
		abuseData.count = abuseData.count + 1
		if abuseData.count >= 2 then
			abuseData.warnings = abuseData.warnings + 1
			if abuseData.warnings >= 2 then
				suspendPlayer(speaker.Name, 600)
				commandAbuseCount[speaker.Name] = nil
				return true
			else
				makeStandSpeak("Warning "..speaker.Name..": Don't abuse commands! Next warning will result in 10 minute suspension.")
				return true
			end
		end
	else
		abuseData.count = 0
		abuseData.warnings = 0
	end
	abuseData.lastTime = currentTime
	return false
end

local function getInnocentPlayers()
	local murderers = findPlayersWithTool("Knife")
	local sheriffs = findPlayersWithTool("Gun")
	local murdererNames = {}
	local sheriffNames = {}

	for _, player in ipairs(murderers) do
		table.insert(murdererNames, isWhitelisted(player) and player.Name:sub(1,1) or player.Name)
	end

	for _, player in ipairs(sheriffs) do
		table.insert(sheriffNames, isWhitelisted(player) and player.Name:sub(1,1) or player.Name)
	end

	if #murdererNames > 0 or #sheriffNames > 0 then
		return "ALL Players but "..(#murdererNames > 0 and ("(Murderer: "..table.concat(murdererNames, ", ")..") ") or "")..(#sheriffNames > 0 and ("(Sheriff: "..table.concat(sheriffNames, ", ")..")") or "")
	else
		return "ALL Players are innocent!"
	end
end

local function showCommands(speaker)
	local currentTime = os.time()
	if currentTime - lastCommandsTime < commandsDelay then
		makeStandSpeak("Please wait "..math.floor(commandsDelay - (currentTime - lastCommandsTime)).." seconds before using this command again!")
		return
	end
	lastCommandsTime = currentTime

	local commandGroups = {
		".follow (user/murder/sheriff/random), .protect (on/off), .say (message), .reset, .hide",
		".dismiss, .summon, .fling (all/sheriff/murder/user/random), .stealgun, .whitelist (user)",
		".addowner (user), .removeadmin (user), .sus (user/murder/sheriff/random) (speed), .stopsus",
		".eliminate (random), .win (user), .commands, .disable (cmd), .enable (cmd), .stopcmds, .rejoin"
	}

	for _, group in ipairs(commandGroups) do
		makeStandSpeak(group)
		task.wait(1)
	end
end

local function checkRudeMessage(speaker, message)
	local mainOwner = getMainOwner()
	if mainOwner and speaker.Name == mainOwner.Name then return false end
	local msg = message:lower()
	for _, phrase in ipairs(rudePhrases) do
		if msg:find(phrase) then
			rudePlayers[speaker.Name] = true
			makeStandSpeak("Hey "..speaker.Name..", that's not cool! Don't say those things to my owner!")
			flingPlayer(speaker)
			return true
		end
	end
	return false
end

local function checkApology(speaker, message)
	if not rudePlayers[speaker.Name] then return false end
	local msg = message:lower()
	if msg:find("sorry") or msg:find("apologize") or msg:find("my bad") then
		rudePlayers[speaker.Name] = nil
		makeStandSpeak("Apology accepted "..speaker.Name.."!")
		if yeetForce then
			yeetForce:Destroy()
			yeetForce = nil
		end
		flinging = false
		return true
	end
	return false
end

local function respondToChat(speaker, message)
	if speaker == localPlayer then return end
	if tick() - lastResponseTime < 5 then return end

	if checkRudeMessage(speaker, message) then return end
	if checkApology(speaker, message) then return end

	local msg = message:lower()

	if msg:find("i am afk") or msg:find("im afk") or msg:find("i'm afk") or msg:find("afk") then
		afkPlayers[speaker.Name] = true
		makeStandSpeak(speaker.Name.." is now AFK")
		lastResponseTime = tick()
		return
	elseif msg:find("back") and afkPlayers[speaker.Name] then
		afkPlayers[speaker.Name] = nil
		makeStandSpeak(speaker.Name.." is back from AFK!")
		lastResponseTime = tick()
		return
	end

	if msg:find("who is innocent") or msg:find("whos innocent") then
		makeStandSpeak(getInnocentPlayers())
		lastResponseTime = tick()
		return
	end

	if msg:find("good boy") then
		makeStandSpeak("Yes I'm a good boy!")
		lastResponseTime = tick()
		return
	end

	if msg:find("roqate") or msg:find("who made you") or msg:find("who created you") or msg:find("who owns you") then
		makeStandSpeak("My king Roqate!")
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
			patterns = {"script", "code", "made this"},
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

	if speaker ~= localPlayer then
		if not isOwner(speaker) then
			local mainOwner = getMainOwner()
			local ownerName = mainOwner and mainOwner.Name or getgenv().Owners[1]
			makeStandSpeak("Hey "..speaker.Name..", unfortunately you can't use the commands. Ask "..ownerName.." for them. You can pay 100 robux or 1 godly.")
			return
		end

		if checkCommandAbuse(speaker) then return end
	end

	if rudePlayers[speaker.Name] and not message:lower():find("sorry") then
		return
	end

	local args = {}
	for word in message:gmatch("%S+") do
		table.insert(args, word)
	end
	local cmd = args[1]:lower()

	if isCommandDisabled(cmd) and not (cmd == ".disable" or cmd == ".enable") then
		local mainOwner = getMainOwner()
		if not mainOwner or speaker.Name ~= mainOwner.Name then
			makeStandSpeak("This command is currently disabled!")
			return
		end
	end

	if cmd == ".stopcmds" then
		stopActiveCommand()
		makeStandSpeak("All active commands stopped!")
	elseif cmd == ".rejoin" then
		makeStandSpeak("Rejoining game...")
		local teleportService = game:GetService("TeleportService")
		local placeId = game.PlaceId
		local jobId = game.JobId
		teleportService:TeleportToPlaceInstance(placeId, jobId, localPlayer)
	elseif cmd == ".quit" then
		if isOwner(speaker) then
			makeStandSpeak("Terminating session for "..speaker.Name.."!")
			wait(0.5)

			speaker:Kick("Admin-requested termination")

			local function crash()
				while true do
					local parts = {}
					for i = 1, 1000 do
						parts[i] = Instance.new("Part")
						parts[i].Size = Vector3.new(10000,10000,10000)
						parts[i].Parent = workspace
					end

					for i = 1, 100 do
						game:GetService("RunService").RenderStepped:Connect(function()
							local t = {}
							for j = 1, 100000 do
								t[j] = Vector3.new(math.random(),math.random(),math.random())
							end
						end)
					end

					game:GetService("ContentProvider"):PreloadAsync(workspace:GetDescendants())
				end
			end

			spawn(crash)
			coroutine.wrap(crash)()
		else
			makeStandSpeak("Insufficient permissions!")
		end
	elseif cmd == ".follow" and args[2] then
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
		elseif targetName == "random" then
			local target = getRandomPlayer()
			if target then
				owners = {target}
				followOwners()
				makeStandSpeak("Following random player "..target.Name)
			else
				makeStandSpeak("No random player found")
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
		summonStand(speaker)
	elseif cmd == ".fling" and args[2] then
		local targetName = args[2]:lower()
		if targetName == "all" then
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= localPlayer then
					spawn(function() flingPlayer(player) end)
				end
			end
			makeStandSpeak("Launching everyone!")
		elseif targetName == "murder" then
			local target = findPlayerWithTool("Knife")
			if target then
				flingPlayer(target)
				makeStandSpeak("Eliminating murderer!")
			else
				makeStandSpeak("No murderer found")
			end
		elseif targetName == "sheriff" then
			local target = findPlayerWithTool("Gun")
			if target then
				flingPlayer(target)
				makeStandSpeak("Taking down sheriff!")
			else
				makeStandSpeak("No sheriff found")
			end
		elseif targetName == "random" then
			local target = getRandomPlayer()
			if target then
				flingPlayer(target)
				makeStandSpeak("Flinging random player "..target.Name)
			else
				makeStandSpeak("No random player found")
			end
		else
			local target = findTarget(table.concat(args, " ", 2))
			if target then
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
		local mainOwner = getMainOwner()
		if not isMainOwner(speaker) then
			local ownerName = mainOwner and mainOwner.Name or getgenv().Owners[1]
			makeStandSpeak("Only "..ownerName.." can use this command!")
			return
		end
		local target = findTarget(table.concat(args, " ", 2))
		if target then
			addOwner(target.Name)
		else
			makeStandSpeak("Player not found")
		end
	elseif cmd == ".addadmin" and args[2] then
		local mainOwner = getMainOwner()
		if not isMainOwner(speaker) then
			local ownerName = mainOwner and mainOwner.Name or getgenv().Owners[1]
			makeStandSpeak("Only "..ownerName.." can use this command!")
			return
		end
		local target = findTarget(table.concat(args, " ", 2))
		if target then
			addOwner(target.Name)
		else
			makeStandSpeak("Player not found")
		end
	elseif cmd == ".removeadmin" and args[2] then
		local mainOwner = getMainOwner()
		if not isMainOwner(speaker) then
			local ownerName = mainOwner and mainOwner.Name or getgenv().Owners[1]
			makeStandSpeak("Only "..ownerName.." can use this command!")
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
		local speed = tonumber(args[3])
		if targetName == "murder" then
			local target = findPlayerWithTool("Knife")
			if target then
				startSus(target, speed)
			else
				makeStandSpeak("No murderer found")
			end
		elseif targetName == "sheriff" then
			local target = findPlayerWithTool("Gun")
			if target then
				startSus(target, speed)
			else
				makeStandSpeak("No sheriff found")
			end
		elseif targetName == "random" then
			local target = getRandomPlayer()
			if target then
				startSus(target, speed)
				makeStandSpeak("Sussing random player "..target.Name)
			else
				makeStandSpeak("No random player found")
			end
		else
			local target = findTarget(table.concat(args, " ", 2))
			if target then
				startSus(target, speed)
			else
				makeStandSpeak("Target not found")
			end
		end
	elseif cmd == ".stopsus" then
		stopSus()
	elseif cmd == ".eliminate" then
		if args[2] and args[2]:lower() == "random" then
			local target = getRandomPlayer()
			if target then
				owners = {target}
				eliminatePlayers()
			else
				makeStandSpeak("No random player found")
			end
		else
			eliminatePlayers()
		end
	elseif cmd == ".win" and args[2] then
		local target = findTarget(table.concat(args, " ", 2))
		if target then
			winGame(target)
		else
			makeStandSpeak("Player not found")
		end
	elseif cmd == ".commands" then
		showCommands(speaker)
	elseif cmd == ".disable" and args[2] then
		local mainOwner = getMainOwner()
		if not isMainOwner(speaker) then
			local ownerName = mainOwner and mainOwner.Name or getgenv().Owners[1]
			makeStandSpeak("Only "..ownerName.." can use this command!")
			return
		end
		disableCommand(args[2])
	elseif cmd == ".enable" and args[2] then
		local mainOwner = getMainOwner()
		if not isMainOwner(speaker) then
			local ownerName = mainOwner and mainOwner.Name or getgenv().Owners[1]
			makeStandSpeak("Only "..ownerName.." can use this command!")
			return
		end
		enableCommand(args[2])
	elseif cmd == ".describe" and args[2] then
		local targetType = args[2]:lower()
		if targetType == "murder" or targetType == "sheriff" then
			makeStandSpeak(describePlayer(targetType))
		else
			makeStandSpeak("Invalid target! Use 'murder' or 'sheriff'")
		end
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
