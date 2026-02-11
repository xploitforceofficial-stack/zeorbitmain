-- ==================================================
-- SCRIPT: ZeOrbitV4 Game Hub (Enhanced with Instant Kill & Fling)
-- ==================================================

if game.PlaceId ~= 10449761463 then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "❌ ZeOrbitV4",
        Text = "This script only works in The Strongest Battlegrounds!",
        Duration = 5
    })
    task.wait(1.5)
    game:Shutdown()
    return
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

-- Load WindUI Library
local WindUI
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
    
    if ok then
        WindUI = result
    else
        return
    end
end

-- =======================================================
-- GLOBAL VARIABLES
-- =======================================================
-- Orbit
local orbitConnection = nil
local isOrbiting = false
local lastOrbitTarget = nil
local orbitRadius = 4.6
local orbitSpeed = 100
local defaultOrbitRadius = 4.6

-- View
local viewingTarget = nil
local isViewing = false

-- Auto Skill
local isAutoSkillEnabled = false
local autoSkillThread = nil
local keys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}

-- Teleport Low
local isTeleportLowEnabled = false
local teleportLowPart = nil
local teleportLowWalls = {}
local targetHpPercent = 30
local returnHpPercent = 80
local isAtSafeSpot = false
local teleportLowThread = nil
local originalPosition = nil

-- Skin
local MY_USER_ID = player.UserId
local activeColor = Color3.fromRGB(180, 0, 255)
local activeSequence = ColorSequence.new(activeColor)
local rainbowEnabled = false
local handAuraEnabled = false
local hueValue = 0
local skinMonitorConnection = nil
local rainbowHeartbeatConnection = nil
local skinInitialized = false

-- Instant Kill
local instantKillEnabled = false
local instantKillTarget = nil
local instantKillThread = nil

-- Fling
local flingTarget = nil
local isFlinging = false
local flingConnection = nil
local isFlingAll = false
local flingAllConnection = nil
local touchFlingEnabled = false
local touchFlingConnection = nil

-- Place Teleport
local currentPlace = nil
local originalPlayerPosition = nil

-- Server
local isRejoining = false

-- UI State
local isMinimized = false

-- Blacklist Bagian Tubuh
local skinWhitelist = {
    ["Head"] = true, ["Torso"] = true, ["Left Arm"] = true, ["Right Arm"] = true,
    ["Left Leg"] = true, ["Right Leg"] = true, ["LeftHand"] = true, ["RightHand"] = true,
    ["LeftLowerArm"] = true, ["RightLowerArm"] = true, ["LeftUpperArm"] = true, ["RightUpperArm"] = true,
    ["LeftLowerLeg"] = true, ["RightLowerLeg"] = true, ["LeftUpperLeg"] = true, ["RightUpperLeg"] = true,
    ["UpperTorso"] = true, ["LowerTorso"] = true, ["HumanoidRootPart"] = true
}

-- Community Links
local COMMUNITY_LINKS = {
    WhatsApp = "https://chat.whatsapp.com/I8hG44FLgrRAwQcS3lvEft",
    Discord = "https://discord.gg/eDbaHKEf7G"
}

-- =======================================================
-- CREATE CUSTOM WINDOW WITH CONTROL BUTTONS
-- =======================================================
-- Create ScreenGui untuk kontrol tambahan
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZeOrbitV4CustomControls"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Window untuk WindUI
local Window = WindUI:CreateWindow({
    Title = "ZeOrbitV4",
    Author = "© vinzee",
    Folder = "ZeOrbit",
    Icon = "rbxassetid://108939127221214",
    NewElements = true,
    
    OpenButton = {
        Title = "ZeOrbitV4",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.6,
        Color = ColorSequence.new(
            Color3.fromHex("#BA00FF"),
            Color3.fromHex("#00FFFF")
        )
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Default",
    },
})

-- Add version tag
Window:Tag({
    Title = "v4.0",
    Icon = "star",
    Color = Color3.fromHex("#BA00FF"),
    Border = true,
})

-- =======================================================
-- CREATE TABS
-- =======================================================
local OrbitTab = Window:Tab({
    Title = "Orbit",
    Icon = "orbit",
    IconColor = Color3.fromHex("#00FFFF"),
    Border = true,
})

local FlingTab = Window:Tab({
    Title = "Fling",
    Icon = "wind",
    IconColor = Color3.fromHex("#FF305D"),
    Border = true,
})

local ToolsTab = Window:Tab({
    Title = "Tools",
    Icon = "settings",
    IconColor = Color3.fromHex("#30FF6A"),
    Border = true,
})

local KillTab = Window:Tab({
    Title = "Kill",
    Icon = "skull",
    IconColor = Color3.fromHex("#FF305D"),
    Border = true,
})

local PlaceTab = Window:Tab({
    Title = "Place",
    Icon = "map-pin",
    IconColor = Color3.fromHex("#9B59B6"),
    Border = true,
})

local SkinTab = Window:Tab({
    Title = "Skin",
    Icon = "palette",
    IconColor = Color3.fromHex("#BA00FF"),
    Border = true,
})

local ServerTab = Window:Tab({
    Title = "Server",
    Icon = "server",
    IconColor = Color3.fromHex("#FFA500"),
    Border = true,
})

local CommunityTab = Window:Tab({
    Title = "Community",
    Icon = "users",
    IconColor = Color3.fromHex("#3498DB"),
    Border = true,
})

-- =======================================================
-- INSTANT KILL SYSTEM (YOUR LOGIC)
-- =======================================================
local function GetClosestPlayer()
    local closest = nil
    local dist = 1000
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hp = p.Character:FindFirstChild("Humanoid")
            if hp and hp.Health > 0 then
                local d = (player.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = p.Character
                end
            end
        end
    end
    return closest
end

local function startInstantKill()
    if instantKillEnabled then return end
    
    instantKillEnabled = true
    
    instantKillThread = RunService.Heartbeat:Connect(function()
        if not instantKillEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        local target
        if instantKillTarget and instantKillTarget.Character and instantKillTarget.Character:FindFirstChild("HumanoidRootPart") then
            -- Jika ada target spesifik yang dipilih
            target = instantKillTarget.Character
        else
            -- Jika tidak ada target spesifik, cari yang terdekat
            target = GetClosestPlayer()
        end
        
        local root = player.Character.HumanoidRootPart
        local hum = player.Character.Humanoid
        
        if target and target:FindFirstChild("HumanoidRootPart") then
            -- Posisi: -4 unit di bawah target agar aman (Underground)
            local targetPos = target.HumanoidRootPart.CFrame * CFrame.new(0, -4, 0)
            root.CFrame = targetPos
            
            -- Anti-Fall & Anti-Physics
            root.Velocity = Vector3.new(0, 0, 0)
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            
            -- Aimbot Kamera
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, target.HumanoidRootPart.Position)
            
            -- Auto M1 (Serang dari bawah)
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(0,0))
        end
    end)
end

local function stopInstantKill()
    instantKillEnabled = false
    
    if instantKillThread then
        instantKillThread:Disconnect()
        instantKillThread = nil
    end
    
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    
    VirtualUser:Button1Up(Vector2.new(0,0))
end

-- =======================================================
-- FLING SYSTEM (YOUR LOGIC)
-- =======================================================
local function GetPlayer(Name)
    Name = Name:lower()
    if Name == "random" then
        local GetPlayers = Players:GetPlayers()
        if table.find(GetPlayers, player) then 
            table.remove(GetPlayers, table.find(GetPlayers, player)) 
        end
        return GetPlayers[math.random(#GetPlayers)]
    else
        for _, x in next, Players:GetPlayers() do
            if x ~= player then
                if x.Name:lower():match("^" .. Name) then
                    return x
                elseif x.DisplayName:lower():match("^" .. Name) then
                    return x
                end
            end
        end
    end
    return nil
end

local function Message(_Title, _Text, Time)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = _Title, Text = _Text, Duration = Time})
    end)
end

local function SkidFling(TargetPlayer, AllBool)
    local Character = player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid
    local TRootPart
    local THead
    local Accessory
    local Handle

    if not TCharacter then
        return Message("Error Occurred", "Target's character is not available", 5)
    end

    THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        if THumanoid and THumanoid.Sit and not AllBool then
            return Message("Error Occurred", "Target is sitting", 5)
        end
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif not THead and Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end
        
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0

            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart and not THead then
            SFBasePart(TRootPart)
        elseif not TRootPart and THead then
            SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then
            SFBasePart(Handle)
        else
            return Message("Error Occurred", "Target is missing everything", 5)
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
        repeat
            RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
            Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
            Humanoid:ChangeState("GettingUp")
            table.foreach(Character:GetChildren(), function(_, x)
                if x:IsA("BasePart") then
                    x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                end
            end)
            task.wait()
        until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
    else
        return Message("Error Occurred", "Random error", 5)
    end
end

getgenv().FPDH = workspace.FallenPartsDestroyHeight

local function FlingTargetPlayer(targetName, isAll)
    if not getgenv().Welcome then
        Message("Fling", "Enjoy Fling all", 5)
        getgenv().Welcome = true
    end

    if isAll then
        for _, x in next, Players:GetPlayers() do
            if x ~= player then
                pcall(function()
                    SkidFling(x, true)
                end)
            end
        end
    else
        local targetPlayer = GetPlayer(targetName)
        if targetPlayer and targetPlayer ~= player then
            if targetPlayer.UserId ~= 1414978355 then
                pcall(function()
                    SkidFling(targetPlayer, false)
                end)
            else
                Message("Error Occurred", "This user is whitelisted! (Owner)", 5)
            end
        else
            Message("Error Occurred", "Username Invalid or Self", 5)
        end
    end
end

-- TOUCH FLING LOGIC
local function startTouchFling()
    if touchFlingEnabled then return end
    
    touchFlingEnabled = true
    local lp = player
    local movel = 0.1
    
    touchFlingConnection = RunService.Heartbeat:Connect(function()
        if not touchFlingEnabled then return end
        
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            local vel = hrp.Velocity
            hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end)
end

local function stopTouchFling()
    touchFlingEnabled = false
    
    if touchFlingConnection then
        touchFlingConnection:Disconnect()
        touchFlingConnection = nil
    end
end

-- =======================================================
-- CORE FUNCTIONS (REST OF YOUR EXISTING CODE)
-- =======================================================

-- Safe Spot Creation
local function createSafeSpot()
    if teleportLowPart and teleportLowPart.Parent then
        teleportLowPart:Destroy()
    end
    
    for _, wall in ipairs(teleportLowWalls) do
        if wall and wall.Parent then
            wall:Destroy()
        end
    end
    teleportLowWalls = {}
    
    teleportLowPart = Instance.new("Part")
    teleportLowPart.Name = "ZeOrbitSafeSpot"
    teleportLowPart.Size = Vector3.new(500, 5, 500)
    teleportLowPart.Anchored = true
    teleportLowPart.CanCollide = true
    teleportLowPart.Transparency = 0.7
    teleportLowPart.Color = Color3.fromRGB(0, 255, 0)
    teleportLowPart.Material = Enum.Material.Neon
    teleportLowPart.Position = Vector3.new(0, -500, 0)
    teleportLowPart.Parent = workspace
    
    local decal = Instance.new("Decal")
    decal.Name = "ZeOrbitLogo"
    decal.Face = Enum.NormalId.Top
    decal.Texture = "rbxassetid://88757106740516"
    decal.Parent = teleportLowPart
    
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 2
    pointLight.Range = 300
    pointLight.Color = Color3.fromRGB(0, 255, 0)
    pointLight.Shadows = true
    pointLight.Parent = teleportLowPart
    
    return teleportLowPart
end

createSafeSpot()

-- =======================================================
-- LOGIC FUNCTIONS (REST OF YOUR EXISTING CODE)
-- =======================================================

-- Orbit Functions
local function startOrbit(targetPlayer)
    if orbitConnection then
        orbitConnection:Disconnect()
        orbitConnection = nil
    end

    local localCharacter = player.Character
    local targetCharacter = targetPlayer.Character
    if not (localCharacter and targetCharacter) then 
        return 
    end

    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not (localRoot and targetRoot) then 
        return 
    end

    local angle = 0
    isOrbiting = true
    lastOrbitTarget = targetPlayer
    
    orbitConnection = RunService.Heartbeat:Connect(function(delta)
        localCharacter = player.Character
        targetCharacter = targetPlayer.Character
        
        if not (localCharacter and targetCharacter and targetCharacter.Parent) then
            if orbitConnection then
                orbitConnection:Disconnect()
                orbitConnection = nil
                isOrbiting = false
            end
            return
        end

        localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
        targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        if not (localRoot and targetRoot) then return end

        angle = angle + (delta * orbitSpeed)
        local offset = Vector3.new(math.cos(angle) * orbitRadius, 0, math.sin(angle) * orbitRadius)
        local pos = targetRoot.Position + offset
        localRoot.CFrame = CFrame.lookAt(pos, targetRoot.Position)
    end)
end

local function stopOrbit()
    if orbitConnection then
        orbitConnection:Disconnect()
        orbitConnection = nil
    end
    isOrbiting = false
    lastOrbitTarget = nil
end

-- View Functions
local function startView(targetPlayer)
    if targetPlayer ~= player and targetPlayer.Character then
        viewingTarget = targetPlayer
        isViewing = true
        Camera.CameraType = Enum.CameraType.Scriptable
    end
end

local function stopView()
    viewingTarget = nil
    isViewing = false
    Camera.CameraType = Enum.CameraType.Custom
    if player.Character then
        local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            Camera.CameraSubject = humanoid
        end
    end
end

-- Auto Skill Functions
local function startAutoSkill()
    isAutoSkillEnabled = true
    
    autoSkillThread = task.spawn(function()
        while isAutoSkillEnabled do
            local key = keys[math.random(1, #keys)]
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
            task.wait(0.05)
        end
    end)
end

local function stopAutoSkill()
    isAutoSkillEnabled = false
    if autoSkillThread then
        task.cancel(autoSkillThread)
        autoSkillThread = nil
    end
end

-- Teleport Low Functions
local function getPlayerHealth()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            return humanoid.Health, humanoid.MaxHealth
        end
    end
    return 0, 100
end

local function teleportToSafeSpot()
    local character = player.Character
    if character and teleportLowPart then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            originalPosition = humanoidRootPart.CFrame
            
            local randomX = math.random(-200, 200)
            local randomZ = math.random(-200, 200)
            local targetPosition = teleportLowPart.Position + Vector3.new(randomX, 3, randomZ)
            
            humanoidRootPart.CFrame = CFrame.new(targetPosition)
            isAtSafeSpot = true
            
            return true
        end
    end
    return false
end

local function teleportToOriginalPosition()
    if originalPosition and player.Character then
        local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.CFrame = originalPosition
            isAtSafeSpot = false
            return true
        end
    end
    return false
end

local function startTeleportLow()
    isTeleportLowEnabled = true
    
    if teleportLowPart then
        teleportLowPart.Transparency = 0.3
    end
    
    teleportLowThread = task.spawn(function()
        while isTeleportLowEnabled do
            local currentHealth, maxHealth = getPlayerHealth()
            local healthPercent = maxHealth > 0 and (currentHealth / maxHealth) * 100 or 0
            
            if not isAtSafeSpot then
                if healthPercent <= targetHpPercent and currentHealth > 0 then
                    if teleportToSafeSpot() then
                        while isTeleportLowEnabled and isAtSafeSpot do
                            local newHealth, newMaxHealth = getPlayerHealth()
                            local newHealthPercent = newMaxHealth > 0 and (newHealth / newMaxHealth) * 100 or 0
                            
                            if newHealthPercent >= returnHpPercent then
                                teleportToOriginalPosition()
                                break
                            end
                            
                            task.wait(0.5)
                        end
                    end
                end
            else
                local newHealth, newMaxHealth = getPlayerHealth()
                local newHealthPercent = newMaxHealth > 0 and (newHealth / newMaxHealth) * 100 or 0
                
                if newHealthPercent >= returnHpPercent then
                    teleportToOriginalPosition()
                end
            end
            
            task.wait(0.5)
        end
        
        if isAtSafeSpot then
            teleportToOriginalPosition()
        end
        
        if teleportLowPart then
            teleportLowPart.Transparency = 0.7
        end
    end)
end

local function stopTeleportLow()
    isTeleportLowEnabled = false
    
    if teleportLowThread then
        task.cancel(teleportLowThread)
        teleportLowThread = nil
    end
end

-- Place Teleport Functions
local function saveOriginalPosition()
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            originalPlayerPosition = humanoidRootPart.CFrame
            return true
        end
    end
    return false
end

local function teleportToPart(part)
    if not part then return false end
    
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    -- Save original position if not already saved
    if not originalPlayerPosition then
        saveOriginalPosition()
    end
    
    -- Teleport ke part dengan offset di atasnya
    local targetCFrame = part.CFrame * CFrame.new(0, 5, 0)
    humanoidRootPart.CFrame = targetCFrame
    
    currentPlace = part.Name
    return true
end

local function findAndTeleportToPlace(placeName)
    local targetParts = {}
    
    -- Cari "Atoms" di folder Cutscenes (Models)
    if placeName == "Atoms" then
        local cutscenesFolder = workspace:FindFirstChild("Cutscenes")
        if cutscenesFolder then
            local atomsModel = cutscenesFolder:FindFirstChild("Atoms")
            if atomsModel and atomsModel:IsA("Model") then
                -- Cari semua parts di dalam model Atoms
                for _, part in ipairs(atomsModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        table.insert(targetParts, part)
                    end
                end
            end
        end
    
    -- Cari "Death Cutscene" di folder Cutscenes
    elseif placeName == "Death Cutscene" then
        local cutscenesFolder = workspace:FindFirstChild("Cutscenes")
        if cutscenesFolder then
            local deathCutscene = cutscenesFolder:FindFirstChild("Death Cutscene")
            if deathCutscene then
                -- Jika ini adalah model, cari parts di dalamnya
                if deathCutscene:IsA("Model") then
                    for _, part in ipairs(deathCutscene:GetDescendants()) do
                        if part:IsA("BasePart") then
                            table.insert(targetParts, part)
                        end
                    end
                elseif deathCutscene:IsA("BasePart") then
                    table.insert(targetParts, deathCutscene)
                end
            end
        end
    
    -- Cari "Part" di folder Map/GrassTop
    elseif placeName == "Part" then
        local mapFolder = workspace:FindFirstChild("Map")
        if mapFolder then
            local grassTopFolder = mapFolder:FindFirstChild("GrassTop")
            if grassTopFolder then
                -- Cari semua part dengan nama "Part" di dalam GrassTop
                for _, item in ipairs(grassTopFolder:GetChildren()) do
                    if item:IsA("BasePart") and item.Name == "Part" then
                        table.insert(targetParts, item)
                    end
                end
            end
        end
    end
    
    -- Teleport ke part pertama yang ditemukan
    if #targetParts > 0 then
        local partToTeleport = targetParts[1]
        if placeName == "Part" and #targetParts > 1 then
            -- Untuk Part, pilih random
            partToTeleport = targetParts[math.random(1, #targetParts)]
        end
        return teleportToPart(partToTeleport)
    end
    
    return false
end

local function backToOriginalPlace()
    if not originalPlayerPosition then return false end
    
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    humanoidRootPart.CFrame = originalPlayerPosition
    currentPlace = nil
    return true
end

-- Skin Functions
local function isColorBlue(col)
    return col.B > col.R and col.B > col.G
end

local function isMyObject(v)
    if v:IsDescendantOf(player.Character) then return true end
    
    local ancestor = v.Parent
    while ancestor and ancestor ~= game do
        if ancestor.Name == player.Name or ancestor.Name == tostring(MY_USER_ID) then
            return true
        end
        ancestor = ancestor.Parent
    end
    
    return false
end

local function applyTargetColor(v)
    if not v or not v.Parent then return end
    if not handAuraEnabled and not rainbowEnabled then return end
    
    if not isMyObject(v) then return end
    
    if v:IsA("BasePart") and skinWhitelist[v.Name] then return end
    
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
        local success, kp = pcall(function() return v.Color.Keypoints end)
        if success and (isColorBlue(kp[1].Value) or v.Name == "PurpleTrail") then
            v.Color = activeSequence
        end
    elseif v:IsA("Light") or (v:IsA("BasePart") and not skinWhitelist[v.Name]) or v:IsA("MeshPart") then
        if isColorBlue(v.Color) then
            v.Color = activeColor
        end
    elseif v:IsA("Texture") or v:IsA("Decal") then
        if isColorBlue(v.Color3) then
            v.Color3 = activeColor
        end
    end
end

local function addTrailToPart(part)
    if not part or part.Name == "Head" or part:FindFirstChild("PurpleTrail") then return end
    if not part:IsDescendantOf(player.Character) then return end
    
    local att0 = Instance.new("Attachment", part)
    att0.Name = "TrailAtt0"
    att0.Position = Vector3.new(0, 0.5, 0)
    local att1 = Instance.new("Attachment", part)
    att1.Name = "TrailAtt1"
    att1.Position = Vector3.new(0, -0.5, 0)
    
    local trail = Instance.new("Trail", part)
    trail.Name = "PurpleTrail"
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Color = activeSequence
    trail.Lifetime = 0.4
    trail.LightEmission = 1
    trail.Transparency = NumberSequence.new(0.2, 1)
    trail.WidthScale = NumberSequence.new(0.4)
end

local function removeTrailFromPart(part)
    if not part then return end
    
    local trail = part:FindFirstChild("PurpleTrail")
    if trail then trail:Destroy() end
    
    local att0 = part:FindFirstChild("TrailAtt0")
    local att1 = part:FindFirstChild("TrailAtt1")
    if att0 then att0:Destroy() end
    if att1 then att1:Destroy() end
end

local function initializeSkinSystem()
    if skinInitialized then return end
    
    skinInitialized = true
    
    if not skinMonitorConnection then
        skinMonitorConnection = workspace.DescendantAdded:Connect(function(obj)
            if handAuraEnabled and obj:IsA("BasePart") and (obj.Name:find("Hand") or obj.Name:find("Arm")) and obj:IsDescendantOf(player.Character) then
                addTrailToPart(obj)
            end
            applyTargetColor(obj)
        end)
    end
    
    if player.Character then
        for _, v in ipairs(player.Character:GetDescendants()) do
            applyTargetColor(v)
        end
    end
    
    if rainbowEnabled and not rainbowHeartbeatConnection then
        rainbowHeartbeatConnection = RunService.Heartbeat:Connect(function(dt)
            if rainbowEnabled then
                hueValue = (hueValue + (dt * 1.0)) % 1
                activeColor = Color3.fromHSV(hueValue, 0.8, 1)
                activeSequence = ColorSequence.new(activeColor)
                
                if player.Character then
                    for _, v in ipairs(player.Character:GetDescendants()) do
                        if not skinWhitelist[v.Name] then
                            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                                v.Color = activeSequence
                            elseif v:IsA("Light") or v:IsA("BasePart") then
                                v.Color = activeColor
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function cleanupSkinSystem()
    if not skinInitialized then return end
    
    if skinMonitorConnection then
        skinMonitorConnection:Disconnect()
        skinMonitorConnection = nil
    end
    
    if rainbowHeartbeatConnection then
        rainbowHeartbeatConnection:Disconnect()
        rainbowHeartbeatConnection = nil
    end
    
    skinInitialized = false
end

local function toggleHandAura(state)
    handAuraEnabled = state
    
    if handAuraEnabled then
        initializeSkinSystem()
        
        if player.Character then
            for _, part in ipairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") and (part.Name:find("Hand") or part.Name:find("Arm")) then
                    addTrailToPart(part)
                end
            end
        end
    else
        if player.Character then
            for _, part in ipairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    removeTrailFromPart(part)
                end
            end
        end
        
        if not rainbowEnabled then
            cleanupSkinSystem()
        end
    end
end

local function toggleRainbowAura(state)
    rainbowEnabled = state
    
    if rainbowEnabled then
        initializeSkinSystem()
        
        if not rainbowHeartbeatConnection then
            rainbowHeartbeatConnection = RunService.Heartbeat:Connect(function(dt)
                if rainbowEnabled then
                    hueValue = (hueValue + (dt * 1.0)) % 1
                    activeColor = Color3.fromHSV(hueValue, 0.8, 1)
                    activeSequence = ColorSequence.new(activeColor)
                    
                    if player.Character then
                        for _, v in ipairs(player.Character:GetDescendants()) do
                            if not skinWhitelist[v.Name] then
                                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                                    v.Color = activeSequence
                                elseif v:IsA("Light") or v:IsA("BasePart") then
                                    v.Color = activeColor
                                end
                            end
                        end
                    end
                end
            end)
        end
    else
        if rainbowHeartbeatConnection then
            rainbowHeartbeatConnection:Disconnect()
            rainbowHeartbeatConnection = nil
        end
        
        if not handAuraEnabled then
            cleanupSkinSystem()
        end
    end
end

local function setRandomColor()
    local hue = math.random()
    activeColor = Color3.fromHSV(hue, 0.8, 1)
    activeSequence = ColorSequence.new(activeColor)
    
    if handAuraEnabled or rainbowEnabled then
        if player.Character then
            for _, v in ipairs(player.Character:GetDescendants()) do
                if not skinWhitelist[v.Name] then
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                        v.Color = activeSequence
                    elseif v:IsA("Light") or v:IsA("BasePart") then
                        v.Color = activeColor
                    end
                end
            end
        end
    end
end

-- Server Functions
local function hopToRandomServer()
    local placeId = game.PlaceId
    
    task.spawn(function()
        task.wait(1)
        TeleportService:Teleport(placeId)
    end)
end

local function rejoinServer()
    local jobId = game.JobId
    local placeId = game.PlaceId
    
    if jobId and #jobId > 0 then
        task.spawn(function()
            task.wait(1)
            TeleportService:TeleportToPlaceInstance(placeId, jobId)
        end)
    else
        TeleportService:Teleport(placeId)
    end
end

-- =======================================================
-- UI COMPONENTS
-- =======================================================

-- Camera View Logic
RunService.RenderStepped:Connect(function()
    if viewingTarget and viewingTarget.Character then
        local part = viewingTarget.Character:FindFirstChild("HumanoidRootPart") or viewingTarget.Character:FindFirstChild("UpperTorso")
        if part and part.Position then
            local offset = Vector3.new(0, 3, -8)
            Camera.CFrame = CFrame.new(part.Position + offset, part.Position)
        end
    end
end)

-- =======================================================
-- FLING TAB (POSISI 2 - SETELAH TAB ORBIT)
-- =======================================================
local flingMainSection = FlingTab:Section({
    Title = "Select Player & Fling",
    Box = true,
})

-- Variables untuk menyimpan player yang dipilih untuk fling
local flingSelectedPlayer = nil

-- Player Selection Dropdown untuk Fling
local function updateFlingDropdown()
    local playersInGame = Players:GetPlayers()
    local dropdownValues = {}
    
    for _, p in ipairs(playersInGame) do
        if p ~= player then
            table.insert(dropdownValues, {
                Title = p.Name,
                Desc = "Select for Fling",
                Icon = "target",
                Value = p
            })
        end
    end
    
    return dropdownValues
end

-- Create dropdown untuk Fling
local flingPlayerDropdown = flingMainSection:Dropdown({
    Title = "Select Player",
    Desc = "Choose a player to fling",
    Values = updateFlingDropdown(),
    Value = nil,
    AllowNone = true,
    Callback = function(selected)
        if selected then
            flingSelectedPlayer = selected.Value
            flingTarget = flingSelectedPlayer
        else
            flingSelectedPlayer = nil
            flingTarget = nil
        end
    end
})

flingMainSection:Space()

-- Fling Selected Player Button
flingMainSection:Button({
    Title = "Fling Selected Player",
    Icon = "wind",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        if flingSelectedPlayer then
            FlingTargetPlayer(flingSelectedPlayer.Name, false)
        else
            Message("Error", "Please select a player first", 3)
        end
    end
})

FlingTab:Space()

-- Fling All Section
local flingAllSection = FlingTab:Section({
    Title = "Mass Fling",
    Box = true,
})

-- Fling All Players Button
flingAllSection:Button({
    Title = "Fling All Players",
    Icon = "users",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        FlingTargetPlayer(nil, true)
    end
})

FlingTab:Space()

-- Touch Fling Section
local touchFlingSection = FlingTab:Section({
    Title = "Touch Fling",
    Box = true,
})

-- Touch Fling Toggle
local touchFlingToggle = touchFlingSection:Toggle({
    Title = "Touch Fling",
    Desc = "Enable touch-based flinging",
    Value = false,
    Callback = function(state)
        if state then
            startTouchFling()
        else
            stopTouchFling()
        end
    end
})

-- Auto update fling player dropdown
task.spawn(function()
    while true do
        flingPlayerDropdown:Refresh(updateFlingDropdown())
        task.wait(5)
    end
end)

-- =======================================================
-- ORBIT TAB (SAMA SEPERTI SEBELUMNYA)
-- =======================================================
local orbitMainSection = OrbitTab:Section({
    Title = "Player Controls",
    Box = true,
})

-- Variables untuk menyimpan player yang dipilih
local selectedPlayer = nil

-- Player Selection Dropdown
local function updatePlayerDropdown()
    local playersInGame = Players:GetPlayers()
    local dropdownValues = {}
    
    for _, p in ipairs(playersInGame) do
        if p ~= player then
            table.insert(dropdownValues, {
                Title = p.Name,
                Desc = "Click to select",
                Icon = "user",
                Value = p
            })
        end
    end
    
    return dropdownValues
end

-- Create dropdown
local orbitPlayerDropdown = orbitMainSection:Dropdown({
    Title = "Select Player",
    Desc = "Choose a player to orbit or view",
    Values = updatePlayerDropdown(),
    Value = nil,
    AllowNone = true,
    Callback = function(selected)
        if selected then
            selectedPlayer = selected.Value
        else
            selectedPlayer = nil
        end
    end
})

OrbitTab:Space()

-- Orbit Settings Section
local orbitSettingsSection = OrbitTab:Section({
    Title = "Orbit Settings",
    Box = true,
})

-- Variable untuk slider
local radiusSliderValue = orbitRadius

-- Orbit Radius Slider
local radiusSlider = orbitSettingsSection:Slider({
    Title = "Orbit Radius",
    Desc = "Distance from target (1-1000)",
    Step = 1,
    Value = {
        Min = 1,
        Max = 1000,
        Default = orbitRadius,
    },
    Callback = function(value)
        radiusSliderValue = value
        orbitRadius = value
    end
})

orbitSettingsSection:Space()

-- Reset Radius Button
orbitSettingsSection:Button({
    Title = "Reset Radius",
    Icon = "refresh-cw",
    Color = Color3.fromHex("#FFA500"),
    Justify = "Center",
    Callback = function()
        orbitRadius = defaultOrbitRadius
        radiusSliderValue = defaultOrbitRadius
        radiusSlider:Set(defaultOrbitRadius)
    end
})

OrbitTab:Space()

-- Control Buttons Group
local orbitControlGroup = OrbitTab:Group({})

-- Start Orbit Button
orbitControlGroup:Button({
    Title = "Start Orbit",
    Icon = "orbit",
    Color = Color3.fromHex("#00FFFF"),
    Justify = "Center",
    Callback = function()
        if selectedPlayer then
            startOrbit(selectedPlayer)
        end
    end
})

orbitControlGroup:Space()

-- Start View Button
orbitControlGroup:Button({
    Title = "Start View",
    Icon = "eye",
    Color = Color3.fromHex("#305dff"),
    Justify = "Center",
    Callback = function()
        if selectedPlayer then
            startView(selectedPlayer)
        end
    end
})

OrbitTab:Space()

-- Stop Buttons Group
local stopControlGroup = OrbitTab:Group({})

-- Stop Orbit Button
stopControlGroup:Button({
    Title = "Stop Orbit",
    Icon = "square",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        stopOrbit()
    end
})

stopControlGroup:Space()

-- Stop View Button
stopControlGroup:Button({
    Title = "Stop View",
    Icon = "eye-off",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        stopView()
    end
})

-- Auto update player dropdown
task.spawn(function()
    while true do
        orbitPlayerDropdown:Refresh(updatePlayerDropdown())
        task.wait(5)
    end
end)

-- =======================================================
-- KILL TAB (DENGAN SELECT PLAYER)
-- =======================================================
local killMainSection = KillTab:Section({
    Title = "Instant Kill System",
    Box = true,
})

-- Variables untuk menyimpan player yang dipilih untuk instant kill
local killSelectedPlayer = nil

-- Player Selection Dropdown untuk Instant Kill
local function updateKillDropdown()
    local playersInGame = Players:GetPlayers()
    local dropdownValues = {}
    
    for _, p in ipairs(playersInGame) do
        if p ~= player then
            table.insert(dropdownValues, {
                Title = p.Name,
                Desc = "Select for Instant Kill",
                Icon = "target",
                Value = p
            })
        end
    end
    
    return dropdownValues
end

-- Create dropdown untuk Instant Kill
local killPlayerDropdown = killMainSection:Dropdown({
    Title = "Select Target",
    Desc = "Choose a player to instant kill",
    Values = updateKillDropdown(),
    Value = nil,
    AllowNone = true,
    Callback = function(selected)
        if selected then
            killSelectedPlayer = selected.Value
            instantKillTarget = killSelectedPlayer
        else
            killSelectedPlayer = nil
            instantKillTarget = nil
        end
    end
})

killMainSection:Space()

-- Instant Kill Selected Player Button
killMainSection:Button({
    Title = "Instant Kill Selected",
    Icon = "skull",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        if killSelectedPlayer then
            -- Mengaktifkan instant kill untuk player tertentu
            if not instantKillEnabled then
                startInstantKill()
            end
        else
            Message("Error", "Please select a player first", 3)
        end
    end
})

killMainSection:Space()

-- Instant Kill Toggle (Auto closest player)
local instantKillToggle = killMainSection:Toggle({
    Title = "INSTANT KILL AUTO",
    Desc = "Enable instant kill on closest player",
    Value = false,
    Callback = function(state)
        if state then
            instantKillTarget = nil -- Reset target untuk mode auto
            startInstantKill()
        else
            stopInstantKill()
        end
    end
})

killMainSection:Space()

-- Status Display
local instantKillStatus = killMainSection:Paragraph({
    Title = "Status: Idle",
    Desc = "Waiting for activation",
    Image = "skull",
    Color = "Red",
})

-- Auto update status dan dropdown
task.spawn(function()
    while true do
        killPlayerDropdown:Refresh(updateKillDropdown())
        
        if instantKillEnabled then
            if instantKillTarget then
                instantKillStatus:Update({
                    Title = "Status: ACTIVE (Targeted)",
                    Desc = "Targeting: " .. (instantKillTarget and instantKillTarget.Name or "None"),
                    Color = "Green",
                })
            else
                instantKillStatus:Update({
                    Title = "Status: ACTIVE (Auto)",
                    Desc = "Targeting closest player",
                    Color = "Green",
                })
            end
        else
            instantKillStatus:Update({
                Title = "Status: Idle",
                Desc = "Waiting for activation",
                Color = "Red",
            })
        end
        task.wait(0.5)
    end
end)

-- =======================================================
-- TOOLS TAB
-- =======================================================
local toolsMainSection = ToolsTab:Section({
    Title = "Auto Features",
    Box = true,
})

-- Auto Skill Toggle
local autoSkillToggle = toolsMainSection:Toggle({
    Title = "Auto Skill",
    Desc = "Automatically use skills 1-4",
    Value = false,
    Callback = function(state)
        if state then
            startAutoSkill()
        else
            stopAutoSkill()
        end
    end
})

-- Teleport Low Section
ToolsTab:Space()

local teleportSection = ToolsTab:Section({
    Title = "Teleport Low System",
    Box = true,
})

-- Teleport Low Toggle
local teleportToggle = teleportSection:Toggle({
    Title = "Teleport Low",
    Desc = "Teleport to safe spot when HP is low",
    Value = false,
    Callback = function(state)
        if state then
            startTeleportLow()
        else
            stopTeleportLow()
        end
    end
})

teleportSection:Space()

-- HP Settings
teleportSection:Slider({
    Title = "Teleport When HP ≤",
    Step = 1,
    Value = {
        Min = 1,
        Max = 100,
        Default = targetHpPercent,
    },
    Callback = function(value)
        targetHpPercent = value
    end
})

teleportSection:Space()

teleportSection:Slider({
    Title = "Return When HP ≥",
    Step = 1,
    Value = {
        Min = 1,
        Max = 100,
        Default = returnHpPercent,
    },
    Callback = function(value)
        returnHpPercent = value
    end
})

-- =======================================================
-- PLACE TAB
-- =======================================================
local placeMainSection = PlaceTab:Section({
    Title = "Place Teleport System",
    Box = true,
})

-- Save original position button
placeMainSection:Button({
    Title = "Save Current Position",
    Icon = "save",
    Color = Color3.fromHex("#30FF6A"),
    Justify = "Center",
    Callback = function()
        if saveOriginalPosition() then
            currentPlace = "Original Position Saved"
        end
    end
})

PlaceTab:Space()

-- Place Selection Section
local placeSelectionSection = PlaceTab:Section({
    Title = "Select Place to Teleport",
    Box = true,
})

-- Atoms Button
placeSelectionSection:Button({
    Title = "Atoms",
    Desc = "Teleport to Atoms",
    Icon = "atom",
    Color = Color3.fromHex("#00FFFF"),
    Justify = "Center",
    Callback = function()
        if findAndTeleportToPlace("Atoms") then
            currentPlace = "Atoms"
        end
    end
})

placeSelectionSection:Space()

-- Death Cutscene Button
placeSelectionSection:Button({
    Title = "Death Cutscene",
    Desc = "Teleport to Death Cutscene",
    Icon = "skull",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        if findAndTeleportToPlace("Death Cutscene") then
            currentPlace = "Death Cutscene"
        end
    end
})

placeSelectionSection:Space()

-- Part (GrassTop) Button
placeSelectionSection:Button({
    Title = "GrassTop Part",
    Desc = "Teleport to GrassTop Part",
    Icon = "square",
    Color = Color3.fromHex("#30FF6A"),
    Justify = "Center",
    Callback = function()
        if findAndTeleportToPlace("Part") then
            currentPlace = "GrassTop Part"
        end
    end
})

PlaceTab:Space()

-- Back to Place Section
local backToPlaceSection = PlaceTab:Section({
    Title = "Return Functions",
    Box = true,
})

-- Back to Original Place Button
backToPlaceSection:Button({
    Title = "Back to Original Place",
    Icon = "rotate-ccw",
    Color = Color3.fromHex("#305dff"),
    Justify = "Center",
    Callback = function()
        if backToOriginalPlace() then
            currentPlace = "Original Place"
        end
    end
})

-- Current Place Status
PlaceTab:Paragraph({
    Title = "Current Place: " .. (currentPlace or "None"),
    Desc = "Use buttons above to teleport",
    Image = "map-pin",
    Color = "Blue",
})

-- Update current place status
task.spawn(function()
    while true do
        PlaceTab:GetElements().Paragraph:Update({
            Title = "Current Place: " .. (currentPlace or "None"),
            Desc = "Use buttons above to teleport",
        })
        task.wait(1)
    end
end)

-- =======================================================
-- SKIN TAB
-- =======================================================
local skinMainSection = SkinTab:Section({
    Title = "Skin Modifier",
    Box = true,
})

-- Hand Aura Toggle
local handAuraToggle = skinMainSection:Toggle({
    Title = "Hand Aura",
    Desc = "Add purple trails to hands",
    Value = false,
    Callback = function(state)
        toggleHandAura(state)
    end
})

skinMainSection:Space()

-- Rainbow Aura Toggle
local rainbowAuraToggle = skinMainSection:Toggle({
    Title = "Rainbow Aura",
    Desc = "Cycle through rainbow colors",
    Value = false,
    Callback = function(state)
        toggleRainbowAura(state)
    end
})

skinMainSection:Space()

-- Random Color Button
skinMainSection:Button({
    Title = "Random Color",
    Icon = "shuffle",
    Color = Color3.fromHex("#305dff"),
    Justify = "Center",
    Callback = function()
        setRandomColor()
    end
})

-- =======================================================
-- SERVER TAB
-- =======================================================
local serverMainSection = ServerTab:Section({
    Title = "Server Information",
    Box = true,
})

-- Server Info Display
local serverInfoParagraph = serverMainSection:Paragraph({
    Title = "Server ID: " .. tostring(game.JobId),
    Desc = "Players: " .. tostring(#Players:GetPlayers()) .. "/20",
    Image = "server",
})

ServerTab:Space()

-- Server Control Group
local serverControlGroup = ServerTab:Group({})

-- Hop Server Button
serverControlGroup:Button({
    Title = "Hop Server",
    Icon = "refresh-cw",
    Color = Color3.fromHex("#305dff"),
    Justify = "Center",
    Callback = function()
        hopToRandomServer()
    end
})

serverControlGroup:Space()

-- Rejoin Server Button
serverControlGroup:Button({
    Title = "Rejoin Server",
    Icon = "rotate-ccw",
    Color = Color3.fromHex("#FFA500"),
    Justify = "Center",
    Callback = function()
        rejoinServer()
    end
})

-- Auto update server info
task.spawn(function()
    while true do
        serverInfoParagraph:Update({
            Title = "Server ID: " .. tostring(game.JobId),
            Desc = "Players: " .. tostring(#Players:GetPlayers()) .. "/20",
        })
        task.wait(5)
    end
end)

-- =======================================================
-- COMMUNITY TAB
-- =======================================================
local communityMainSection = CommunityTab:Section({
    Title = "Community Links",
    Box = true,
})

-- Community Description
communityMainSection:Paragraph({
    Title = "Join Our Community",
    Desc = "Connect with other players and get updates",
    Image = "users",
    Color = "Blue",
})

CommunityTab:Space()

-- Community Links Section
local communityLinksSection = CommunityTab:Section({
    Title = "Available Platforms",
    Box = true,
})

-- WhatsApp Button
communityLinksSection:Button({
    Title = "WhatsApp Group",
    Desc = "Join our WhatsApp community",
    Icon = "message-circle",
    Color = Color3.fromHex("#25D366"),
    Justify = "Center",
    Callback = function()
        if setclipboard then
            setclipboard(COMMUNITY_LINKS.WhatsApp)
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "✅ Success",
                Text = "WhatsApp link copied to clipboard!",
                Duration = 3
            })
        end
    end
})

communityLinksSection:Space()

-- Discord Button
communityLinksSection:Button({
    Title = "Discord Server",
    Desc = "Join our Discord community",
    Icon = "message-square",
    Color = Color3.fromHex("#5865F2"),
    Justify = "Center",
    Callback = function()
        if setclipboard then
            setclipboard(COMMUNITY_LINKS.Discord)
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "✅ Success",
                Text = "Discord link copied to clipboard!",
                Duration = 3
            })
        end
    end
})

-- =======================================================
-- CUSTOM CONTROL BUTTONS SECTION
-- =======================================================
local controlSection = Window:Section({
    Title = "Window Controls",
})

-- Control Buttons Group
local windowControlGroup = controlSection:Group({})

-- Minimize Button
windowControlGroup:Button({
    Title = "Minimize",
    Icon = "minimize-2",
    Color = Color3.fromHex("#FFA500"),
    Justify = "Center",
    Callback = function()
        Window:Minimize()
    end
})

windowControlGroup:Space()

-- Close Button
windowControlGroup:Button({
    Title = "Close",
    Icon = "x",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        Window:Destroy()
        if screenGui then
            screenGui:Destroy()
        end
    end
})

-- =======================================================
-- INITIAL NOTIFICATION
-- =======================================================
task.wait(1)
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "✅ ZeOrbitV4 Enhanced Loaded",
    Text = "Succes\nClick the ZeOrbitV4 button to open menu.",
    Duration = 5
})

print("ZeOrbitV4 Enhanced Script Loaded Successfully!")
