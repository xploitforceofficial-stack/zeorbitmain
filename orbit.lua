-- ==================================================
-- SCRIPT: ZeOrbitV4 Game Hub (ULTRA OPTIMIZED)
-- FIX: Skin system only checks body parts when aura is ON
-- FIX: Fling system menggunakan logika dari ZeFlingV2
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
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

-- Load WindUI Library (optimized)
local WindUI = (function()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua", true))()
    end)
    return success and result or nil
end)()
if not WindUI then return end

-- =======================================================
-- LOGO GUI UNTUK BUKA/TUTUP (DAPAT DIGESER)
-- =======================================================
local logoGui = Instance.new("ScreenGui")
logoGui.Name = "ZeOrbitLogoDraggable"
logoGui.ResetOnSpawn = false
logoGui.Parent = player:WaitForChild("PlayerGui", 5)

local logoButton = Instance.new("ImageButton")
logoButton.Name = "LogoButton"
logoButton.Size = UDim2.new(0, 60, 0, 60)
logoButton.Position = UDim2.new(0.5, -30, 0.5, -30)
logoButton.BackgroundTransparency = 1
logoButton.Image = "rbxassetid://108939127221214"
logoButton.ImageColor3 = Color3.fromRGB(180, 0, 255)
logoButton.ScaleType = Enum.ScaleType.Fit
logoButton.Parent = logoGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent = logoButton

-- Animasi kecil
local tweenService = game:GetService("TweenService")
local hoverTween = tweenService:Create(logoButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 70, 0, 70)})
local unhoverTween = tweenService:Create(logoButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)})

logoButton.MouseEnter:Connect(function()
    hoverTween:Play()
end)

logoButton.MouseLeave:Connect(function()
    unhoverTween:Play()
end)

-- Fitur drag/geser bebas
local dragging = false
local dragInput, dragStart, startPos

logoButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = logoButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

logoButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        logoButton.Position = newPos
    end
end)

-- Fungsi untuk membuka/tutup GUI utama (HANYA VIA LOGO)
local guiVisible = true
logoButton.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    if Window then
        if guiVisible then
            Window:Open()
        else
            Window:Minimize()
        end
    end
end)

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
local targetHpPercent = 30
local returnHpPercent = 80
local isAtSafeSpot = false
local teleportLowThread = nil
local originalPosition = nil

-- Skin - ULTRA OPTIMIZED
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

-- Fling - Menggunakan logika dari ZeFlingV2
local flingTarget = nil
local touchFlingEnabled = false
local touchFlingThread = nil
local touchFlingConnection = nil

-- Place Teleport
local currentPlace = nil
local originalPlayerPosition = nil

-- Blacklist - OPTIMIZED: Constant table, no runtime modifications
local skinWhitelist = {
    Head = true, Torso = true, ["Left Arm"] = true, ["Right Arm"] = true,
    ["Left Leg"] = true, ["Right Leg"] = true, LeftHand = true, RightHand = true,
    LeftLowerArm = true, RightLowerArm = true, LeftUpperArm = true, RightUpperArm = true,
    LeftLowerLeg = true, RightLowerLeg = true, LeftUpperLeg = true, RightUpperLeg = true,
    UpperTorso = true, LowerTorso = true, HumanoidRootPart = true
}

-- Community Links
local COMMUNITY_LINKS = {
    WhatsApp = "https://chat.whatsapp.com/I8hG44FLgrRAwQcS3lvEft",
    Discord = "https://discord.gg/eDbaHKEf7G"
}

-- Save FPDH
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- =======================================================
-- CREATE CUSTOM WINDOW (TANPA OPEN BUTTON BAWAAN)
-- =======================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZeOrbitV4CustomControls"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui", 5)

local Window = WindUI:CreateWindow({
    Title = "ZeOrbitV4",
    Author = "© vinzee",
    Folder = "ZeOrbit",
    Icon = "rbxassetid://108939127221214",
    NewElements = true,
    OpenButton = {
        Enabled = false -- MATIKAN OPEN BUTTON BAWAAN
    },
    Topbar = { Height = 44, ButtonsType = "Default" }
})

Window:Tag({ Title = "v4.0", Icon = "star", Color = Color3.fromHex("#BA00FF"), Border = true })

-- =======================================================
-- CREATE TABS
-- =======================================================
local OrbitTab = Window:Tab({ Title = "Orbit", Icon = "orbit", IconColor = Color3.fromHex("#00FFFF"), Border = true })
local FlingTab = Window:Tab({ Title = "Fling", Icon = "wind", IconColor = Color3.fromHex("#FF305D"), Border = true })
local ToolsTab = Window:Tab({ Title = "Tools", Icon = "settings", IconColor = Color3.fromHex("#30FF6A"), Border = true })
local KillTab = Window:Tab({ Title = "Kill", Icon = "skull", IconColor = Color3.fromHex("#FF305D"), Border = true })
local PlaceTab = Window:Tab({ Title = "Place", Icon = "map-pin", IconColor = Color3.fromHex("#9B59B6"), Border = true })
local SkinTab = Window:Tab({ Title = "Skin", Icon = "palette", IconColor = Color3.fromHex("#BA00FF"), Border = true })
local ServerTab = Window:Tab({ Title = "Server", Icon = "server", IconColor = Color3.fromHex("#FFA500"), Border = true })
local CommunityTab = Window:Tab({ Title = "Community", Icon = "users", IconColor = Color3.fromHex("#3498DB"), Border = true })

-- =======================================================
-- OPTIMIZED UTILITY FUNCTIONS
-- =======================================================
local function Message(Title, Text, Duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = Title, Text = Text, Duration = Duration or 5 })
    end)
end

local function getRootPart(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.RootPart
end

-- =======================================================
-- INSTANT KILL SYSTEM
-- =======================================================
local function GetClosestPlayer()
    local closest, dist = nil, 1000
    local myChar, myRoot = player.Character, nil
    if not myChar then return nil end
    
    myRoot = getRootPart(myChar)
    if not myRoot then return nil end
    
    local myPos = myRoot.Position
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local d = (myPos - root.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = char
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
        if not instantKillEnabled then return end
        
        local myChar = player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChild("Humanoid")
        if not (myRoot and myHum) then return end
        
        local target
        if instantKillTarget and instantKillTarget.Character then
            target = instantKillTarget.Character
        else
            target = GetClosestPlayer()
        end
        
        if target and target:FindFirstChild("HumanoidRootPart") then
            myRoot.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, -4, 0)
            myRoot.Velocity = Vector3.new(0, 0, 0)
            myHum:ChangeState(Enum.HumanoidStateType.Physics)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.HumanoidRootPart.Position)
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
    local myHum = player.Character and player.Character:FindFirstChild("Humanoid")
    if myHum then myHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    VirtualUser:Button1Up(Vector2.new(0,0))
end

-- =======================================================
-- FLING SYSTEM - LOGIKA DARI ZEFLINGV2
-- =======================================================

-- Get Player function
local function GetPlayer(Name)
    Name = Name:lower()
    if Name == "random" then
        local GetPlayers = Players:GetPlayers()
        if table.find(GetPlayers, player) then table.remove(GetPlayers, table.find(GetPlayers, player)) end
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

-- Main SkidFling function - Final Version
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
        return
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
            return
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

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
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
            until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or 
                  TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or 
                  THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
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
            return
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
        repeat
            RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
            Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
            Humanoid:ChangeState("GettingUp")
            for _, x in pairs(Character:GetChildren()) do
                if x:IsA("BasePart") then
                    x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                end
            end
            task.wait()
        until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
    else
        return
    end
end

-- Fling Target function
local function FlingTarget(targetName, isAll)
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
            end
        end
    end
end

-- =======================================================
-- TOUCH FLING SYSTEM - LOGIKA DARI TOUCH FLING GUI
-- =======================================================
local function startTouchFling()
    if touchFlingEnabled then return end
    touchFlingEnabled = true
    
    touchFlingThread = task.spawn(function()
        local movel = 0.1
        
        while touchFlingEnabled do
            RunService.Heartbeat:Wait()
            local c = player.Character
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
        end
    end)
end

local function stopTouchFling()
    touchFlingEnabled = false
    if touchFlingThread then
        task.cancel(touchFlingThread)
        touchFlingThread = nil
    end
end

-- =======================================================
-- CORE FUNCTIONS
-- =======================================================
local function createSafeSpot()
    if teleportLowPart and teleportLowPart.Parent then
        teleportLowPart:Destroy()
    end
    
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

-- Orbit Functions
local function startOrbit(targetPlayer)
    if orbitConnection then
        orbitConnection:Disconnect()
        orbitConnection = nil
    end

    isOrbiting = true
    lastOrbitTarget = targetPlayer
    local angle = 0
    
    orbitConnection = RunService.Heartbeat:Connect(function(delta)
        local localChar = player.Character
        local targetChar = targetPlayer.Character
        
        if not (localChar and targetChar and targetChar.Parent) then
            stopOrbit()
            return
        end

        local localRoot = getRootPart(localChar)
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if not (localRoot and targetRoot) then return end

        angle = angle + (delta * orbitSpeed)
        local offset = Vector3.new(math.cos(angle) * orbitRadius, 0, math.sin(angle) * orbitRadius)
        localRoot.CFrame = CFrame.lookAt(targetRoot.Position + offset, targetRoot.Position)
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
    local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if hum then Camera.CameraSubject = hum end
end

-- Auto Skill Functions
local function startAutoSkill()
    isAutoSkillEnabled = true
    autoSkillThread = task.spawn(function()
        while isAutoSkillEnabled do
            local key = keys[math.random(1, #keys)]
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
            task.wait(0.1)
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
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    return hum and hum.Health, hum and hum.MaxHealth or 0
end

local function teleportToSafeSpot()
    local root = getRootPart(player.Character)
    if root and teleportLowPart then
        originalPosition = root.CFrame
        root.CFrame = CFrame.new(teleportLowPart.Position + Vector3.new(math.random(-200, 200), 3, math.random(-200, 200)))
        isAtSafeSpot = true
        return true
    end
    return false
end

local function teleportToOriginalPosition()
    local root = getRootPart(player.Character)
    if originalPosition and root then
        root.CFrame = originalPosition
        isAtSafeSpot = false
        return true
    end
    return false
end

local function startTeleportLow()
    isTeleportLowEnabled = true
    if teleportLowPart then teleportLowPart.Transparency = 0.3 end
    
    teleportLowThread = task.spawn(function()
        while isTeleportLowEnabled do
            local health, maxHealth = getPlayerHealth()
            local healthPercent = maxHealth > 0 and (health / maxHealth) * 100 or 0
            
            if not isAtSafeSpot then
                if healthPercent <= targetHpPercent and health > 0 then
                    if teleportToSafeSpot() then
                        while isTeleportLowEnabled and isAtSafeSpot do
                            local newHealth, newMaxHealth = getPlayerHealth()
                            if newMaxHealth > 0 and (newHealth / newMaxHealth) * 100 >= returnHpPercent then
                                teleportToOriginalPosition()
                                break
                            end
                            task.wait(1)
                        end
                    end
                end
            else
                local newHealth, newMaxHealth = getPlayerHealth()
                if newMaxHealth > 0 and (newHealth / newMaxHealth) * 100 >= returnHpPercent then
                    teleportToOriginalPosition()
                end
            end
            task.wait(1)
        end
        if isAtSafeSpot then teleportToOriginalPosition() end
        if teleportLowPart then teleportLowPart.Transparency = 0.7 end
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
    local root = getRootPart(player.Character)
    if root then
        originalPlayerPosition = root.CFrame
        return true
    end
    return false
end

local function teleportToPart(part)
    if not part then return false end
    local root = getRootPart(player.Character)
    if not root then return false end
    if not originalPlayerPosition then saveOriginalPosition() end
    root.CFrame = part.CFrame * CFrame.new(0, 5, 0)
    currentPlace = part.Name
    return true
end

local function findAndTeleportToPlace(placeName)
    local targetParts = {}
    local cutscenesFolder = workspace:FindFirstChild("Cutscenes")
    local mapFolder = workspace:FindFirstChild("Map")
    
    if placeName == "Atoms" and cutscenesFolder then
        local atomsModel = cutscenesFolder:FindFirstChild("Atoms")
        if atomsModel and atomsModel:IsA("Model") then
            for _, part in ipairs(atomsModel:GetDescendants()) do
                if part:IsA("BasePart") then table.insert(targetParts, part) end
            end
        end
    elseif placeName == "Death Cutscene" and cutscenesFolder then
        local deathCutscene = cutscenesFolder:FindFirstChild("Death Cutscene")
        if deathCutscene then
            if deathCutscene:IsA("Model") then
                for _, part in ipairs(deathCutscene:GetDescendants()) do
                    if part:IsA("BasePart") then table.insert(targetParts, part) end
                end
            elseif deathCutscene:IsA("BasePart") then
                table.insert(targetParts, deathCutscene)
            end
        end
    elseif placeName == "Part" and mapFolder then
        local grassTopFolder = mapFolder:FindFirstChild("GrassTop")
        if grassTopFolder then
            for _, item in ipairs(grassTopFolder:GetChildren()) do
                if item:IsA("BasePart") and item.Name == "Part" then
                    table.insert(targetParts, item)
                end
            end
        end
    end
    
    if #targetParts > 0 then
        local part = placeName == "Part" and targetParts[math.random(1, #targetParts)] or targetParts[1]
        return teleportToPart(part)
    end
    return false
end

local function backToOriginalPlace()
    local root = getRootPart(player.Character)
    if originalPlayerPosition and root then
        root.CFrame = originalPlayerPosition
        currentPlace = nil
        return true
    end
    return false
end

-- =======================================================
-- SKIN SYSTEM - ULTRA OPTIMIZED
-- =======================================================

-- Simple color check
local function isColorBlue(col)
    return col.B > col.R and col.B > col.G
end

-- Check if object belongs to player
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

-- Apply color to a single object - ONLY CALLED WHEN AURA ACTIVE
local function applyColorToObject(v)
    if not v or not v.Parent then return end
    if v:IsA("BasePart") and skinWhitelist[v.Name] then return end
    
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
        local success, kp = pcall(function() return v.Color.Keypoints end)
        if success and (isColorBlue(kp[1].Value) or v.Name == "PurpleTrail") then
            v.Color = activeSequence
        end
    elseif (v:IsA("Light") or (v:IsA("BasePart") and not skinWhitelist[v.Name]) or v:IsA("MeshPart")) and isColorBlue(v.Color) then
        v.Color = activeColor
    elseif (v:IsA("Texture") or v:IsA("Decal")) and isColorBlue(v.Color3) then
        v.Color3 = activeColor
    end
end

-- Add trail to hand part
local function addTrailToPart(part)
    if not part or part.Name == "Head" or part:FindFirstChild("PurpleTrail") or not part:IsDescendantOf(player.Character) then 
        return 
    end
    
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

-- Remove trail from part
local function removeTrailFromPart(part)
    if not part then return end
    local trail = part:FindFirstChild("PurpleTrail")
    if trail then trail:Destroy() end
    local att0 = part:FindFirstChild("TrailAtt0")
    local att1 = part:FindFirstChild("TrailAtt1")
    if att0 then att0:Destroy() end
    if att1 then att1:Destroy() end
end

-- ============ SKIN ACTIVE STATE FUNCTIONS ============

-- Apply colors to ALL eligible parts in character (only when aura active)
local function applyAllColors()
    if not (handAuraEnabled or rainbowEnabled) then return end
    local char = player.Character
    if not char then return end
    
    for _, v in pairs(char:GetDescendants()) do
        if not skinWhitelist[v.Name] then
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                v.Color = activeSequence
            elseif (v:IsA("Light") or v:IsA("BasePart") or v:IsA("MeshPart")) and isColorBlue(v.Color) then
                v.Color = activeColor
            elseif (v:IsA("Texture") or v:IsA("Decal")) and isColorBlue(v.Color3) then
                v.Color3 = activeColor
            end
        end
    end
end

-- Add trails to all hand parts (only when hand aura active)
local function addAllHandTrails()
    if not handAuraEnabled then return end
    local char = player.Character
    if not char then return end
    
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and (part.Name:find("Hand") or part.Name:find("Arm")) then
            addTrailToPart(part)
        end
    end
end

-- Remove all trails (when hand aura disabled)
local function removeAllTrails()
    local char = player.Character
    if not char then return end
    
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            removeTrailFromPart(part)
        end
    end
end

-- ============ SKIN INITIALIZATION ============

-- Descendant handler - ONLY CONNECTED WHEN AURA ACTIVE
local descendantHandler
descendantHandler = function(obj)
    if not (handAuraEnabled or rainbowEnabled) then return end
    if not isMyObject(obj) then return end
    
    if handAuraEnabled and obj:IsA("BasePart") and (obj.Name:find("Hand") or obj.Name:find("Arm")) then
        addTrailToPart(obj)
    end
    
    if not skinWhitelist[obj.Name] then
        applyColorToObject(obj)
    end
end

-- Rainbow heartbeat - ONLY CONNECTED WHEN RAINBOW ACTIVE
local function rainbowUpdate(dt)
    if rainbowEnabled then
        hueValue = (hueValue + (dt * 0.3)) % 1
        activeColor = Color3.fromHSV(hueValue, 0.8, 1)
        activeSequence = ColorSequence.new(activeColor)
        applyAllColors()
    end
end

-- Initialize skin system (only connects when needed)
local function initializeSkinSystem()
    if skinInitialized then return end
    
    if not skinMonitorConnection then
        skinMonitorConnection = workspace.DescendantAdded:Connect(descendantHandler)
    end
    
    skinInitialized = true
end

-- Cleanup skin system (disconnect everything)
local function cleanupSkinSystem()
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

-- ============ TOGGLE FUNCTIONS ============

local function toggleHandAura(state)
    if handAuraEnabled == state then return end
    handAuraEnabled = state
    
    if handAuraEnabled then
        initializeSkinSystem()
        addAllHandTrails()
        if rainbowEnabled then
            applyAllColors()
        end
    else
        removeAllTrails()
        if not rainbowEnabled then
            cleanupSkinSystem()
        end
    end
end

local function toggleRainbowAura(state)
    if rainbowEnabled == state then return end
    rainbowEnabled = state
    
    if rainbowEnabled then
        initializeSkinSystem()
        
        if not rainbowHeartbeatConnection then
            rainbowHeartbeatConnection = RunService.Heartbeat:Connect(rainbowUpdate)
        end
        
        applyAllColors()
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
        applyAllColors()
        
        if handAuraEnabled then
            local char = player.Character
            if char then
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        local trail = part:FindFirstChild("PurpleTrail")
                        if trail then
                            trail.Color = activeSequence
                        end
                    end
                end
            end
        end
    end
end

-- Server Functions
local function hopToRandomServer()
    task.spawn(function()
        task.wait(1)
        TeleportService:Teleport(game.PlaceId)
    end)
end

local function rejoinServer()
    local jobId, placeId = game.JobId, game.PlaceId
    task.spawn(function()
        task.wait(1)
        if jobId and #jobId > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, jobId)
        else
            TeleportService:Teleport(placeId)
        end
    end)
end

-- =======================================================
-- VIEW LOGIC (RENDER-STEPPED)
-- =======================================================
RunService.RenderStepped:Connect(function()
    if viewingTarget and viewingTarget.Character then
        local part = viewingTarget.Character:FindFirstChild("HumanoidRootPart") or viewingTarget.Character:FindFirstChild("UpperTorso")
        if part then
            Camera.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, -8), part.Position)
        end
    end
end)

-- =======================================================
-- UI COMPONENTS - FLING TAB UPDATED
-- =======================================================

-- FLING TAB - MENGGUNAKAN LOGIKA ZEFLINGV2
local flingMainSection = FlingTab:Section({ Title = "Select Player & Fling", Box = true })
local flingSelectedPlayer = nil

local function updateFlingDropdown()
    local values = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(values, { Title = p.Name, Desc = "Select for Fling", Icon = "target", Value = p })
        end
    end
    return values
end

local flingPlayerDropdown = flingMainSection:Dropdown({
    Title = "Select Player",
    Desc = "Choose a player to fling",
    Values = updateFlingDropdown(),
    Value = nil,
    AllowNone = true,
    Callback = function(selected)
        flingSelectedPlayer = selected and selected.Value or nil
        flingTarget = flingSelectedPlayer
    end
})

flingMainSection:Space()
flingMainSection:Button({
    Title = "Fling Selected Player",
    Icon = "wind",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        if flingSelectedPlayer then
            FlingTarget(flingSelectedPlayer.Name, false)
        end
    end
})

FlingTab:Space()
local flingAllSection = FlingTab:Section({ Title = "Mass Fling", Box = true })
flingAllSection:Button({
    Title = "Fling All Players",
    Icon = "users",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        FlingTarget(nil, true)
    end
})

FlingTab:Space()
local touchFlingSection = FlingTab:Section({ Title = "Touch Fling", Box = true })
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

-- Refresh dropdown setiap 10 detik
task.spawn(function()
    while true do
        flingPlayerDropdown:Refresh(updateFlingDropdown())
        task.wait(10)
    end
end)

-- ORBIT TAB
local orbitMainSection = OrbitTab:Section({ Title = "Player Controls", Box = true })
local selectedPlayer = nil

local function updatePlayerDropdown()
    local values = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(values, { Title = p.Name, Desc = "Click to select", Icon = "user", Value = p })
        end
    end
    return values
end

local orbitPlayerDropdown = orbitMainSection:Dropdown({
    Title = "Select Player",
    Desc = "Choose a player to orbit or view",
    Values = updatePlayerDropdown(),
    Value = nil,
    AllowNone = true,
    Callback = function(selected)
        selectedPlayer = selected and selected.Value or nil
    end
})

OrbitTab:Space()
local orbitSettingsSection = OrbitTab:Section({ Title = "Orbit Settings", Box = true })
local radiusSliderValue = orbitRadius

local radiusSlider = orbitSettingsSection:Slider({
    Title = "Orbit Radius",
    Desc = "Distance from target (1-1000)",
    Step = 1,
    Value = { Min = 1, Max = 1000, Default = orbitRadius },
    Callback = function(value)
        radiusSliderValue = value
        orbitRadius = value
    end
})

orbitSettingsSection:Space()
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
local orbitControlGroup = OrbitTab:Group({})
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
local stopControlGroup = OrbitTab:Group({})
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
stopControlGroup:Button({ 
    Title = "Stop View", 
    Icon = "eye-off", 
    Color = Color3.fromHex("#FF305D"), 
    Justify = "Center", 
    Callback = function()
        stopView()
    end
})

task.spawn(function()
    while true do
        orbitPlayerDropdown:Refresh(updatePlayerDropdown())
        task.wait(10)
    end
end)

-- KILL TAB
local killMainSection = KillTab:Section({ Title = "Instant Kill System", Box = true })
local killSelectedPlayer = nil

local function updateKillDropdown()
    local values = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(values, { Title = p.Name, Desc = "Select for Instant Kill", Icon = "target", Value = p })
        end
    end
    return values
end

local killPlayerDropdown = killMainSection:Dropdown({
    Title = "Select Target",
    Desc = "Choose a player to instant kill",
    Values = updateKillDropdown(),
    Value = nil,
    AllowNone = true,
    Callback = function(selected)
        killSelectedPlayer = selected and selected.Value or nil
        instantKillTarget = killSelectedPlayer
    end
})

killMainSection:Space()
killMainSection:Button({
    Title = "Instant Kill Selected",
    Icon = "skull",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        if killSelectedPlayer then
            if not instantKillEnabled then 
                startInstantKill()
            end
        end
    end
})

killMainSection:Space()
local instantKillToggle = killMainSection:Toggle({
    Title = "INSTANT KILL AUTO",
    Desc = "Enable instant kill on closest player",
    Value = false,
    Callback = function(state)
        if state then
            instantKillTarget = nil
            startInstantKill()
        else
            stopInstantKill()
        end
    end
})

killMainSection:Space()
local instantKillStatus = killMainSection:Paragraph({
    Title = "Status: Idle",
    Desc = "Waiting for activation",
    Image = "skull",
    Color = "Red",
})

task.spawn(function()
    while true do
        killPlayerDropdown:Refresh(updateKillDropdown())
        if instantKillEnabled then
            local statusTitle = instantKillTarget and "Status: ACTIVE (Targeted)" or "Status: ACTIVE (Auto)"
            local statusDesc = instantKillTarget and ("Targeting: " .. instantKillTarget.Name) or "Targeting closest player"
            instantKillStatus:Update({ Title = statusTitle, Desc = statusDesc, Color = "Green" })
        else
            instantKillStatus:Update({ Title = "Status: Idle", Desc = "Waiting for activation", Color = "Red" })
        end
        task.wait(2)
    end
end)

-- TOOLS TAB
local toolsMainSection = ToolsTab:Section({ Title = "Auto Features", Box = true })
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

ToolsTab:Space()
local teleportSection = ToolsTab:Section({ Title = "Teleport Low System", Box = true })
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
teleportSection:Slider({
    Title = "Teleport When HP ≤",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = targetHpPercent },
    Callback = function(v) targetHpPercent = v end
})
teleportSection:Space()
teleportSection:Slider({
    Title = "Return When HP ≥",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = returnHpPercent },
    Callback = function(v) returnHpPercent = v end
})

-- PLACE TAB
local placeMainSection = PlaceTab:Section({ Title = "Place Teleport System", Box = true })
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
local placeSelectionSection = PlaceTab:Section({ Title = "Select Place to Teleport", Box = true })
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
local backToPlaceSection = PlaceTab:Section({ Title = "Return Functions", Box = true })
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

PlaceTab:Paragraph({ Title = "Current Place: None", Desc = "Use buttons above to teleport", Image = "map-pin", Color = "Blue" })

task.spawn(function()
    local placePara = PlaceTab:GetElements().Paragraph
    while true do
        if placePara then
            placePara:Update({ Title = "Current Place: " .. (currentPlace or "None"), Desc = "Use buttons above to teleport" })
        end
        task.wait(2)
    end
end)

-- SKIN TAB
local skinMainSection = SkinTab:Section({ Title = "Skin Modifier", Box = true })
local handAuraToggle = skinMainSection:Toggle({
    Title = "Hand Aura",
    Desc = "Add purple trails to hands",
    Value = false,
    Callback = function(state)
        toggleHandAura(state)
    end
})
skinMainSection:Space()
local rainbowAuraToggle = skinMainSection:Toggle({
    Title = "Rainbow Aura",
    Desc = "Cycle through rainbow colors",
    Value = false,
    Callback = function(state)
        toggleRainbowAura(state)
    end
})
skinMainSection:Space()
skinMainSection:Button({
    Title = "Random Color",
    Icon = "shuffle",
    Color = Color3.fromHex("#305dff"),
    Justify = "Center",
    Callback = function()
        setRandomColor()
    end
})

-- SERVER TAB
local serverMainSection = ServerTab:Section({ Title = "Server Information", Box = true })
local serverInfoParagraph = serverMainSection:Paragraph({
    Title = "Server ID: " .. tostring(game.JobId),
    Desc = "Players: " .. tostring(#Players:GetPlayers()) .. "/20",
    Image = "server",
})

ServerTab:Space()
local serverControlGroup = ServerTab:Group({})
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
serverControlGroup:Button({
    Title = "Rejoin Server",
    Icon = "rotate-ccw",
    Color = Color3.fromHex("#FFA500"),
    Justify = "Center",
    Callback = function()
        rejoinServer()
    end
})

task.spawn(function()
    while true do
        serverInfoParagraph:Update({
            Title = "Server ID: " .. tostring(game.JobId),
            Desc = "Players: " .. tostring(#Players:GetPlayers()) .. "/20",
        })
        task.wait(10)
    end
end)

-- COMMUNITY TAB - HANYA NOTIFIKASI SAAT COPY LINK SUKSES
local communityMainSection = CommunityTab:Section({ Title = "Community Links", Box = true })
communityMainSection:Paragraph({
    Title = "Join Our Community",
    Desc = "Connect with other players and get updates",
    Image = "users",
    Color = "Blue",
})

CommunityTab:Space()
local communityLinksSection = CommunityTab:Section({ Title = "Available Platforms", Box = true })
communityLinksSection:Button({
    Title = "WhatsApp Group",
    Desc = "Join our WhatsApp community",
    Icon = "message-circle",
    Color = Color3.fromHex("#25D366"),
    Justify = "Center",
    Callback = function()
        if setclipboard then
            setclipboard(COMMUNITY_LINKS.WhatsApp)
            Message("✅ Success", "WhatsApp link copied to clipboard!", 3)
        end
    end
})
communityLinksSection:Space()
communityLinksSection:Button({
    Title = "Discord Server",
    Desc = "Join our Discord community",
    Icon = "message-square",
    Color = Color3.fromHex("#5865F2"),
    Justify = "Center",
    Callback = function()
        if setclipboard then
            setclipboard(COMMUNITY_LINKS.Discord)
            Message("✅ Success", "Discord link copied to clipboard!", 3)
        end
    end
})

-- CONTROL BUTTONS
local controlSection = Window:Section({ Title = "Window Controls" })
local windowControlGroup = controlSection:Group({})
windowControlGroup:Button({
    Title = "Minimize",
    Icon = "minimize-2",
    Color = Color3.fromHex("#FFA500"),
    Justify = "Center",
    Callback = function() 
        Window:Minimize()
        guiVisible = false
    end
})
windowControlGroup:Space()
windowControlGroup:Button({
    Title = "Close",
    Icon = "x",
    Color = Color3.fromHex("#FF305D"),
    Justify = "Center",
    Callback = function()
        Window:Destroy()
        if screenGui then screenGui:Destroy() end
        if logoGui then logoGui:Destroy() end
    end
})

-- =======================================================
-- INITIAL NOTIFICATION - SATU-SATUNYA NOTIF SAAT EXECUTE
-- =======================================================
task.wait(1)
Message("✅ ZeOrbitV4", "Script loaded - Click logo to toggle menu", 5)
print("ZeOrbitV4")
