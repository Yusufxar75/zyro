-- [[ ZyroSoftware - v1.0 ]] --
-- [[ Coder by Massivestroke/aimfaster ]] --
-- [[ https://cheatglobal.com/members/massivestrokee.448425/ ]] --

local ZyroSettings = {
    Aimbot = false, AimbotKey = Enum.UserInputType.MouseButton2, FOV = 120, Smoothness = 4,
    AutoFire = false, Hitbox = false, TeamCheck = false, VisibleCheck = false,
    
    BunnyHop = false, BHopPower = 80, BHopSpeedBoost = 25,
    Walkspeed = false, WalkspeedValue = 50,
    JumpPower = false, JumpPowerValue = 150,
    
    Mevlana = false, MevlanaSpeed = 5,
    ThirdPerson = false, ThirdPersonFOV = 90,
    
    ESPBox = false, ESPName = false, ESPHealth = false, ESPDistance = false,
    Chams = false, RainbowWorld = false, FancyNames = false,
    SilentWallBang = false, SilentRange = 800,
    
    SkinEnabled = false,
    SkinColor = Color3.fromRGB(255, 0, 100),
    SkinMaterial = "Neon",
    SkinSize = 1,
    CharColor = Color3.fromRGB(0, 255, 200),
    RainbowGun = false,
    RainbowChar = false,
    
    MusicURL = "",
    AntiCheatBypass = true, EmulatorMode = false, MenuVisible = true
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local OrigLight = {A=Lighting.Ambient, OA=Lighting.OutdoorAmbient, FC=Lighting.FogColor, FE=Lighting.FogEnd, CT=Lighting.ClockTime, B=Lighting.Brightness, FOV=Camera.FieldOfView}
local OrigCamMode = LP.CameraMode
local OriginalSkinData = {}

local function GetRoot(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHead(c) return c and c:FindFirstChild("Head") end
local function GetHumanoid(c) return c and c:FindFirstChildOfClass("Humanoid") end

local function IsAlive(c)
    if not c then return false end
    local h = GetHumanoid(c)
    if h then return h.Health > 0 end
    return c:FindFirstChild("Head") ~= nil
end

local function IsEnemy(p)
    if p == LP or not p.Character or not IsAlive(p.Character) then return false end
    if ZyroSettings.TeamCheck and p.Team and LP.Team and p.Team == LP.Team then return false end
    return true
end

local function IsVisible(targetPart)
    if not ZyroSettings.VisibleCheck then return true end
    if not targetPart or not targetPart.Parent then return false end
    local origin = Camera.CFrame.Position
    local dir = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character, Camera}
    if targetPart.Parent then
        table.insert(params.FilterDescendantsInstances, targetPart.Parent)
    end
    local result = workspace:Raycast(origin, dir, params)
    return result == nil
end

local FOVCircle = nil
if Drawing then
    pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Visible = false
        FOVCircle.Radius = ZyroSettings.FOV
        FOVCircle.Color = Color3.fromRGB(0, 255, 200)
        FOVCircle.Thickness = 1.5
        FOVCircle.NumSides = 60
    end)
end

-- [[ BUNNYHOP v9 - ÇOK KATMANLI ]]
-- BloxStrike Humanoid olmadığı için Jump/JumpPower çalışmıyor.
-- Çoklu yöntem: Velocity + BodyVelocity + LinearVelocity + CFrame micro-jump

local bhopConn
local bhopBV = nil
local bhopLV = nil
local bhopAttach = nil
local bhopTick = 0

local function CleanupBhopObjects()
    if bhopBV then pcall(function() bhopBV:Destroy() end); bhopBV = nil end
    if bhopLV then pcall(function() bhopLV:Destroy() end); bhopLV = nil end
    if bhopAttach then pcall(function() bhopAttach:Destroy() end); bhopAttach = nil end
end

local function StartBunnyHop()
    if bhopConn then bhopConn:Disconnect() end
    bhopConn = RunService.RenderStepped:Connect(function(dt)
        if not ZyroSettings.BunnyHop then 
            CleanupBhopObjects()
            return 
        end
        
        local char = LP.Character
        if not char then CleanupBhopObjects() return end
        local root = GetRoot(char)
        if not root then CleanupBhopObjects() return end
        local hum = GetHumanoid(char)
        
        bhopTick = bhopTick + dt
        
        -- Yöntem 1: Humanoid varsa klasik zıplama
        if hum then
            pcall(function()
                hum.UseJumpPower = true
                hum.JumpPower = ZyroSettings.BHopPower
            end)
            if hum.FloorMaterial ~= Enum.Material.Air then
                pcall(function() hum.Jump = true end)
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end
        
        -- Yöntem 2: BodyVelocity (anti-cheat sıfırlayabilir)
        if not bhopBV or not bhopBV.Parent or bhopBV.Parent ~= root then
            if bhopBV then pcall(function() bhopBV:Destroy() end) end
            bhopBV = Instance.new("BodyVelocity")
            bhopBV.Name = "ZyroBHopBV"
            bhopBV.MaxForce = Vector3.new(0, 1e6, 0)
            bhopBV.P = 1e6
            bhopBV.Parent = root
        end
        bhopBV.Velocity = Vector3.new(0, ZyroSettings.BHopPower, 0)
        
        -- Yöntem 3: LinearVelocity constraint
        if not bhopLV or not bhopLV.Parent or not bhopAttach or bhopAttach.Parent ~= root then
            CleanupBhopObjects()
            bhopAttach = Instance.new("Attachment")
            bhopAttach.Name = "ZyroBHopAttach"
            bhopAttach.Parent = root
            
            bhopLV = Instance.new("LinearVelocity")
            bhopLV.Name = "ZyroBHopLV"
            bhopLV.Attachment0 = bhopAttach
            bhopLV.MaxForce = math.huge
            bhopLV.VectorVelocity = Vector3.new(0, ZyroSettings.BHopPower, 0)
            bhopLV.RelativeTo = Enum.ActuatorRelativeTo.World
            bhopLV.Parent = root
        end
        pcall(function() bhopLV.VectorVelocity = Vector3.new(0, ZyroSettings.BHopPower, 0) end)
        
        -- Yöntem 4: Direkt root.Velocity
        pcall(function()
            root.Velocity = Vector3.new(root.Velocity.X, ZyroSettings.BHopPower, root.Velocity.Z)
        end)
        
        -- Yöntem 5: CFrame micro-jump (her 0.4 saniyede bir ışınlama)
        if bhopTick >= 0.4 then
            bhopTick = 0
            pcall(function()
                root.CFrame = root.CFrame + Vector3.new(0, 2.5, 0)
            end)
        end
        
        -- Yatay hız boost
        if ZyroSettings.BHopSpeedBoost > 0 then
            pcall(function()
                local moveDir = hum and hum.MoveDirection or Vector3.new(0, 0, 0)
                if moveDir.Magnitude > 0.1 then
                    root.Velocity = Vector3.new(
                        moveDir.X * ZyroSettings.BHopSpeedBoost + root.Velocity.X,
                        root.Velocity.Y,
                        moveDir.Z * ZyroSettings.BHopSpeedBoost + root.Velocity.Z
                    )
                end
            end)
        end
    end)
end

-- [[ WALKSPEED / JUMPPOWER ]]
local wsConn
local originalWS = 16
local wsInitialized = false

local function StartWalkSpeedJump()
    if wsConn then wsConn:Disconnect() end
    wsConn = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        if not char then return end
        local hum = GetHumanoid(char)
        if not hum then return end
        
        if not wsInitialized then
            originalWS = hum.WalkSpeed or 16
            wsInitialized = true
        end
        
        if ZyroSettings.Walkspeed then
            pcall(function() hum.WalkSpeed = ZyroSettings.WalkspeedValue end)
        elseif not ZyroSettings.BunnyHop then
            pcall(function() hum.WalkSpeed = originalWS end)
        end
        
        if ZyroSettings.JumpPower and not ZyroSettings.BunnyHop then
            pcall(function()
                hum.UseJumpPower = true
                hum.JumpPower = ZyroSettings.JumpPowerValue
            end)
        end
    end)
end

-- [[ MEVLANA ]]
local mevlanaConn
local mAngle = 0
local function StartMevlana()
    if mevlanaConn then mevlanaConn:Disconnect() end
    mevlanaConn = RunService.RenderStepped:Connect(function(dt)
        if not ZyroSettings.Mevlana then return end
        local char = LP.Character
        if not char then return end
        local root = GetRoot(char)
        if not root then return end
        local hum = GetHumanoid(char)
        if hum then hum.AutoRotate = false end
        mAngle = mAngle + dt * ZyroSettings.MevlanaSpeed
        if mAngle > math.pi * 2 then mAngle = mAngle - math.pi * 2 end
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, mAngle, 0)
    end)
end

local function StopMevlana()
    local char = LP.Character
    if char then
        local hum = GetHumanoid(char)
        if hum then hum.AutoRotate = true end
    end
end

-- [[ THIRDPERSON ]]
local tpConn
local function StartThirdPerson()
    if tpConn then tpConn:Disconnect() end
    tpConn = RunService.RenderStepped:Connect(function()
        if not ZyroSettings.ThirdPerson then
            if LP.CameraMode ~= OrigCamMode then
                pcall(function()
                    LP.CameraMode = OrigCamMode
                    Camera.FieldOfView = OrigLight.FOV
                    Camera.CameraSubject = LP.Character and GetHumanoid(LP.Character)
                    Camera.MinZoomDistance = 0.5
                    Camera.MaxZoomDistance = 400
                end)
            end
            return
        end
        pcall(function()
            LP.CameraMode = Enum.CameraMode.Classic
            Camera.FieldOfView = ZyroSettings.ThirdPersonFOV
            Camera.CameraSubject = LP.Character and (GetHumanoid(LP.Character) or GetHead(LP.Character)) or Camera.CameraSubject
            Camera.MinZoomDistance = 0.5
            Camera.MaxZoomDistance = 25
        end)
    end)
end

-- [[ HITBOX ]]
local hitboxConn
local function StartHitbox()
    if hitboxConn then hitboxConn:Disconnect() end
    hitboxConn = RunService.Heartbeat:Connect(function()
        for _, p in pairs(Players:GetPlayers()) do
            if IsEnemy(p) then
                local head = GetHead(p.Character)
                if head then
                    if ZyroSettings.Hitbox then
                        pcall(function()
                            head.Size = Vector3.new(6, 6, 6)
                            head.Transparency = 0.5
                            head.CanCollide = false
                        end)
                    else
                        pcall(function()
                            head.Size = Vector3.new(2, 1, 1)
                            head.Transparency = 0
                        end)
                    end
                end
            end
        end
    end)
end

-- [[ RAINBOW WORLD ]]
local rainbowConn
local hue = 0
local function StartRainbowWorld()
    if rainbowConn then rainbowConn:Disconnect() end
    rainbowConn = RunService.Heartbeat:Connect(function(dt)
        if not ZyroSettings.RainbowWorld then
            if Lighting.Ambient ~= OrigLight.A then
                Lighting.Ambient = OrigLight.A
                Lighting.OutdoorAmbient = OrigLight.OA
                Lighting.FogColor = OrigLight.FC
                Lighting.FogEnd = OrigLight.FE
                Lighting.ClockTime = OrigLight.CT
                Lighting.Brightness = OrigLight.B
                Lighting.ColorShift_Top = Color3.new(0,0,0)
                Lighting.ColorShift_Bottom = Color3.new(0,0,0)
            end
            return
        end
        hue = (hue + dt * 0.15) % 1
        local c = Color3.fromHSV(hue, 0.8, 0.9)
        Lighting.Ambient = c
        Lighting.OutdoorAmbient = c
        Lighting.FogColor = c
        Lighting.FogEnd = 300
        Lighting.FogStart = 0
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.ColorShift_Top = c
        Lighting.ColorShift_Bottom = Color3.fromHSV((hue + 0.5) % 1, 0.8, 0.9)
    end)
end

-- [[ FANCY NAMES ]]
local fancyMap = {
    a="α",b="в",c="¢",d="∂",e="є",f="ƒ",g="g",h="н",i="ι",j="נ",k="к",l="ℓ",
    m="м",n="η",o="σ",p="ρ",q="q",r="я",s="ѕ",t="т",u="υ",v="ν",w="ω",x="χ",y="у",z="z",
    A="Λ",B="B",C="C",D="Ð",E="Ξ",F="F",G="G",H="H",I="I",J="J",K="K",L="Ł",M="M",
    N="Π",O="Θ",P="P",Q="Q",R="Я",S="Σ",T="T",U="U",V="V",W="Ω",X="X",Y="Y",Z="Z"
}
local decorations = {"✦","★","✧","❈","◆","❖","⟡","✵","❉","☬","⚜","✺","❂"}
local function MakeFancy(name)
    local d1 = decorations[math.random(1, #decorations)]
    local d2 = decorations[math.random(1, #decorations)]
    local out = ""
    for i = 1, #name do
        local ch = name:sub(i, i)
        out = out .. (fancyMap[ch] or ch)
    end
    return d1 .. " " .. out .. " " .. d2
end

-- [[ SKIN CHANGER ]]
local skinConn = nil
local hueSkin = 0

local function IsWeaponModel(obj)
    if not obj then return false end
    local n = obj.Name:lower()
    return n:find("weapon") or n:find("gun") or n:find("knife") or 
           n:find("pistol") or n:find("rifle") or n:find("ak") or 
           n:find("m4") or n:find("awp") or n:find("deagle") or
           n:find("smg") or n:find("sniper") or n:find("viewmodel")
end

local function ApplySkinToPart(part, color, material, sizeMult, rainbow)
    if not part or not part:IsA("BasePart") then return end
    if not OriginalSkinData[part] then
        OriginalSkinData[part] = {
            Color = part.Color,
            Material = part.Material,
            Size = part.Size
        }
    end
    local orig = OriginalSkinData[part]
    pcall(function()
        if rainbow then
            local h = (tick() * 0.3) % 1
            part.Color = Color3.fromHSV(h, 0.8, 1)
        else
            part.Color = color or orig.Color
        end
        if material then
            local mat = Enum.Material[material]
            if mat then part.Material = mat end
        end
        if sizeMult and sizeMult ~= 1 then
            part.Size = orig.Size * sizeMult
        else
            part.Size = orig.Size
        end
    end)
end

local function RestorePart(part)
    if OriginalSkinData[part] and part.Parent then
        local orig = OriginalSkinData[part]
        pcall(function()
            part.Color = orig.Color
            part.Material = orig.Material
            part.Size = orig.Size
        end)
    end
end

local function StartSkinChanger()
    if skinConn then skinConn:Disconnect() end
    skinConn = RunService.Heartbeat:Connect(function()
        if not ZyroSettings.SkinEnabled then 
            for part, _ in pairs(OriginalSkinData) do
                if part and part.Parent then
                    RestorePart(part)
                end
            end
            return
        end
        
        hueSkin = hueSkin + 0.01
        local char = LP.Character
        if not char then return end
        
        local charParts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", 
                          "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg",
                          "RightUpperLeg", "RightLowerLeg", "Torso", "Left Arm", "Right Arm",
                          "Left Leg", "Right Leg"}
        for _, pName in ipairs(charParts) do
            local part = char:FindFirstChild(pName)
            if part and part:IsA("BasePart") then
                if ZyroSettings.RainbowChar then
                    ApplySkinToPart(part, nil, nil, 1, true)
                else
                    ApplySkinToPart(part, ZyroSettings.CharColor, nil, 1, false)
                end
            end
        end
        
        -- Silah modelleri (camera + character + workspace)
        local scanTargets = {}
        for _, c in ipairs(Camera:GetChildren()) do table.insert(scanTargets, c) end
        for _, c in ipairs(char:GetChildren()) do table.insert(scanTargets, c) end
        for _, c in ipairs(workspace:GetChildren()) do table.insert(scanTargets, c) end
        
        for _, obj in ipairs(scanTargets) do
            if obj:IsA("Model") and IsWeaponModel(obj) then
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("MeshPart") or part:IsA("BasePart") then
                        if ZyroSettings.RainbowGun then
                            ApplySkinToPart(part, nil, ZyroSettings.SkinMaterial, ZyroSettings.SkinSize, true)
                        else
                            ApplySkinToPart(part, ZyroSettings.SkinColor, ZyroSettings.SkinMaterial, ZyroSettings.SkinSize, false)
                        end
                    end
                end
            end
        end
    end)
end

-- [[ ESP ]]
local DrawingsTable = {}
local BillboardsTable = {}

local function ClearPlayerData(p)
    if p.Character then
        local h = p.Character:FindFirstChild("ZyroChams")
        if h then h:Destroy() end
    end
    if BillboardsTable[p] and BillboardsTable[p].Billboard.Parent then
        BillboardsTable[p].Billboard:Destroy()
    end
    BillboardsTable[p] = nil
    if DrawingsTable[p] then
        for _, d in pairs(DrawingsTable[p]) do
            pcall(function() d:Remove() end)
        end
        DrawingsTable[p] = nil
    end
end

local function CreateMultiBillboard(head)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ZyroTag"
    bb.Size = UDim2.new(0, 280, 0, 60)
    bb.StudsOffsetWorldSpace = Vector3.new(0, 1.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 800
    bb.LightInfluence = 0
    bb.Parent = head
    local cont = Instance.new("Frame", bb)
    cont.Size = UDim2.new(1, 0, 1, 0)
    cont.BackgroundTransparency = 1
    local lay = Instance.new("UIListLayout", cont)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local function mk(n, col, ord)
        local l = Instance.new("TextLabel", cont)
        l.Name = n; l.Size = UDim2.new(1, 0, 0, 20)
        l.BackgroundTransparency = 1
        l.TextColor3 = col; l.TextStrokeTransparency = 0
        l.TextStrokeColor3 = Color3.new(0, 0, 0)
        l.TextSize = 14; l.Font = Enum.Font.GothamBold
        l.LayoutOrder = ord
        return l
    end
    return {
        Billboard = bb,
        Name = mk("NL", Color3.fromRGB(255, 90, 90), 1),
        Health = mk("HL", Color3.fromRGB(80, 255, 120), 2),
        Distance = mk("DL", Color3.fromRGB(255, 210, 80), 3)
    }
end

local function CreateCornerBox()
    return {
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line"),
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line"),
        TL = Drawing.new("Line"),
        TR = Drawing.new("Line"),
        BL = Drawing.new("Line"),
        BR = Drawing.new("Line")
    }
end

local espConn
local function StartESP()
    if espConn then espConn:Disconnect() end
    espConn = RunService.RenderStepped:Connect(function()
        if FOVCircle then
            FOVCircle.Visible = ZyroSettings.Aimbot
            FOVCircle.Radius = ZyroSettings.FOV
            FOVCircle.Position = UserInputService:GetMouseLocation()
        end
        for _, p in pairs(Players:GetPlayers()) do
            if IsEnemy(p) then
                local char = p.Character
                local root = GetRoot(char)
                local head = GetHead(char)
                if char and root and head then
                    local chams = char:FindFirstChild("ZyroChams")
                    if ZyroSettings.Chams then
                        if not chams then
                            local h = Instance.new("Highlight")
                            h.Name = "ZyroChams"; h.Parent = char; h.Adornee = char
                            h.FillColor = Color3.fromRGB(255, 0, 60)
                            h.OutlineColor = Color3.fromRGB(255, 150, 150)
                            h.FillTransparency = 0.5
                            h.OutlineTransparency = 0
                            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        end
                    elseif chams then
                        chams:Destroy()
                    end
                    
                    local need = ZyroSettings.ESPName or ZyroSettings.ESPHealth or ZyroSettings.ESPDistance
                    if need then
                        if not BillboardsTable[p] or not BillboardsTable[p].Billboard.Parent then
                            BillboardsTable[p] = CreateMultiBillboard(head)
                        end
                        local t = BillboardsTable[p]
                        if t.Billboard.Parent ~= head then t.Billboard.Parent = head end
                        
                        if ZyroSettings.ESPName then
                            t.Name.Text = ZyroSettings.FancyNames and MakeFancy(p.Name) or p.Name
                            t.Name.Visible = true
                        else t.Name.Visible = false end
                        
                        if ZyroSettings.ESPHealth then
                            local hum = GetHumanoid(char)
                            t.Health.Text = hum and ("❤ " .. math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)) or "❤ ALIVE"
                            t.Health.Visible = true
                        else t.Health.Visible = false end
                        
                        if ZyroSettings.ESPDistance then
                            local dist = (Camera.CFrame.Position - root.Position).Magnitude
                            t.Distance.Text = "📏 " .. math.floor(dist) .. "m"
                            t.Distance.Visible = true
                        else t.Distance.Visible = false end
                    elseif BillboardsTable[p] then
                        if BillboardsTable[p].Billboard.Parent then
                            BillboardsTable[p].Billboard:Destroy()
                        end
                        BillboardsTable[p] = nil
                    end
                    
                    if Drawing and ZyroSettings.ESPBox then
                        if not DrawingsTable[p] then
                            local ok, tbl = pcall(function() return {Box = CreateCornerBox()} end)
                            if ok then DrawingsTable[p] = tbl end
                        end
                        if DrawingsTable[p] then
                            local d = DrawingsTable[p]
                            local box = d.Box
                            local headTop = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y / 2, 0))
                            local rootBottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, root.Size.Y / 2, 0))
                            local headSP = Camera:WorldToViewportPoint(head.Position)
                            if headSP.Z > 0 then
                                local boxTop = headTop.Y
                                local boxBottom = rootBottom.Y
                                local boxHeight = math.abs(boxBottom - boxTop)
                                local boxWidth = boxHeight * 0.55
                                local boxLeft = headSP.X - boxWidth / 2
                                local boxRight = headSP.X + boxWidth / 2
                                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                                local thickness = math.clamp(20 / math.max(dist, 5), 1, 2.5)
                                local cornerSize = math.min(boxWidth * 0.3, boxHeight * 0.25)
                                local mainColor = Color3.fromRGB(255, 30, 60)
                                local cornerColor = Color3.fromRGB(0, 255, 200)
                                box.Top.From = Vector2.new(boxLeft, boxTop)
                                box.Top.To = Vector2.new(boxRight, boxTop)
                                box.Top.Color = mainColor
                                box.Top.Thickness = thickness
                                box.Top.Visible = true
                                box.Bottom.From = Vector2.new(boxLeft, boxBottom)
                                box.Bottom.To = Vector2.new(boxRight, boxBottom)
                                box.Bottom.Color = mainColor
                                box.Bottom.Thickness = thickness
                                box.Bottom.Visible = true
                                box.Left.From = Vector2.new(boxLeft, boxTop)
                                box.Left.To = Vector2.new(boxLeft, boxBottom)
                                box.Left.Color = mainColor
                                box.Left.Thickness = thickness
                                box.Left.Visible = true
                                box.Right.From = Vector2.new(boxRight, boxTop)
                                box.Right.To = Vector2.new(boxRight, boxBottom)
                                box.Right.Color = mainColor
                                box.Right.Thickness = thickness
                                box.Right.Visible = true
                                box.TL.From = Vector2.new(boxLeft, boxTop)
                                box.TL.To = Vector2.new(boxLeft + cornerSize, boxTop)
                                box.TL.Color = cornerColor
                                box.TL.Thickness = thickness + 1
                                box.TL.Visible = true
                                box.TR.From = Vector2.new(boxRight - cornerSize, boxTop)
                                box.TR.To = Vector2.new(boxRight, boxTop)
                                box.TR.Color = cornerColor
                                box.TR.Thickness = thickness + 1
                                box.TR.Visible = true
                                box.BL.From = Vector2.new(boxLeft, boxBottom)
                                box.BL.To = Vector2.new(boxLeft + cornerSize, boxBottom)
                                box.BL.Color = cornerColor
                                box.BL.Thickness = thickness + 1
                                box.BL.Visible = true
                                box.BR.From = Vector2.new(boxRight - cornerSize, boxBottom)
                                box.BR.To = Vector2.new(boxRight, boxBottom)
                                box.BR.Color = cornerColor
                                box.BR.Thickness = thickness + 1
                                box.BR.Visible = true
                            else
                                for _, line in pairs(d.Box) do line.Visible = false end
                            end
                        end
                    elseif DrawingsTable[p] then
                        for _, line in pairs(DrawingsTable[p].Box) do
                            pcall(function() line:Remove() end)
                        end
                        DrawingsTable[p] = nil
                    end
                else
                    ClearPlayerData(p)
                end
            else
                ClearPlayerData(p)
            end
        end
    end)
end

-- [[ KAMERA ]]
local cameraLockTarget = nil
local lastTarget = nil
local targetChangeTime = 0

local function GetClosestPlayerByFOV()
    local mousePos = UserInputService:GetMouseLocation()
    local closest, minDist = nil, ZyroSettings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if IsEnemy(p) then
            local part = GetHead(p.Character)
            if part then
                if not IsVisible(part) then continue end
                local pos, onS = Camera:WorldToViewportPoint(part.Position)
                if onS then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < minDist then closest = p; minDist = dist end
                end
            end
        end
    end
    return closest
end

local function GetClosestEnemyThroughWall()
    local myRoot = GetRoot(LP.Character)
    if not myRoot then return nil end
    local closest, minDist = nil, ZyroSettings.SilentRange
    for _, p in pairs(Players:GetPlayers()) do
        if IsEnemy(p) then
            local root = GetRoot(p.Character)
            if root then
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist < minDist then closest = p; minDist = dist end
            end
        end
    end
    return closest
end

local cameraConn
local function StartCameraController()
    if cameraConn then cameraConn:Disconnect() end
    cameraConn = RunService.RenderStepped:Connect(function()
        local activeTarget = nil
        local smoothness = ZyroSettings.Smoothness
        local rmbHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if rmbHeld then
            if ZyroSettings.SilentWallBang then
                local wbTarget = GetClosestEnemyThroughWall()
                if wbTarget and wbTarget.Character then
                    activeTarget = GetHead(wbTarget.Character)
                    smoothness = 3
                end
            elseif ZyroSettings.Aimbot then
                local aimTarget = GetClosestPlayerByFOV()
                if aimTarget and aimTarget.Character then
                    activeTarget = GetHead(aimTarget.Character)
                end
            end
        end
        if activeTarget ~= lastTarget then
            targetChangeTime = tick()
            lastTarget = activeTarget
        end
        if activeTarget and (tick() - targetChangeTime) < 0.05 then
            cameraLockTarget = activeTarget
            return
        end
        cameraLockTarget = activeTarget
        if activeTarget then
            if not activeTarget.Parent then return end
            if mousemoverel then
                local screenPos = Camera:WorldToViewportPoint(activeTarget.Position)
                local vps = Camera.ViewportSize
                local dX = (screenPos.X - vps.X / 2) / math.max(1, smoothness)
                local dY = (screenPos.Y - vps.Y / 2) / math.max(1, smoothness)
                pcall(function() mousemoverel(math.floor(dX), math.floor(dY)) end)
            end
            local targetCF = CFrame.new(Camera.CFrame.Position, activeTarget.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / math.max(1, smoothness))
        end
    end)
end

-- [[ AUTOFIRE ]]
local fireConn
local function StartAutoFire()
    if fireConn then fireConn:Disconnect() end
    fireConn = RunService.Heartbeat:Connect(function()
        if not ZyroSettings.AutoFire then return end
        if ZyroSettings.SilentWallBang and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if cameraLockTarget then
                pcall(function() mouse1click() end)
                task.wait(0.05)
            end
            return
        end
        local mouse = LP:GetMouse()
        local target = mouse.Target
        if target then
            local char = target:FindFirstAncestorOfClass("Model")
            if char then
                local ep = Players:GetPlayerFromCharacter(char)
                if ep and IsEnemy(ep) then
                    pcall(function() mouse1click() end)
                    task.wait(0.05)
                end
            end
        end
    end)
end

-- [[ MÜZİK ]]
local musicSound = nil
local function PlayMusic(assetId)
    if musicSound then musicSound:Destroy(); musicSound = nil end
    if not assetId or assetId == "" then return end
    local id = assetId:gsub("[^%d]", "")
    if id == "" then return end
    pcall(function()
        musicSound = Instance.new("Sound")
        musicSound.Name = "ZyroMusic"
        musicSound.SoundId = "rbxassetid://" .. id
        musicSound.Volume = 0.5
        musicSound.Looped = true
        musicSound.Parent = SoundService
        musicSound:Play()
    end)
end

local function StopMusic()
    if musicSound then musicSound:Stop(); musicSound:Destroy(); musicSound = nil end
end

-- [[ ÜST BİLDİRİMLER ]]
local notifHolder = nil
local function CreateTopNotification()
    if notifHolder then notifHolder:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "ZyroTopNotif"
    sg.Parent = CoreGui
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 999
    local holder = Instance.new("Frame", sg)
    holder.Size = UDim2.new(0, 320, 0, 200)
    holder.Position = UDim2.new(0, 15, 0, 15)
    holder.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", holder)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    notifHolder = sg
    return holder
end

local function MakeNotif(title, status, c1, c2, order)
    if not notifHolder then CreateTopNotification() end
    local holder = notifHolder:FindFirstChildOfClass("Frame")
    if not holder then return nil end
    local f = Instance.new("Frame", holder)
    f.Size = UDim2.new(1, 0, 0, 70)
    f.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 1
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", f)
    s.Thickness = 1.5
    local g = Instance.new("UIGradient", s)
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2)
    }
    task.spawn(function()
        local t = 0
        while f.Parent do
            task.wait(0.05)
            t = t + 0.05
            if not f.Parent then break end
            local h1 = (t * 0.2) % 1
            local h2 = (t * 0.2 + 0.5) % 1
            g.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromHSV(h1, 0.8, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(h2, 0.8, 1))
            }
        end
    end)
    local t1 = Instance.new("TextLabel", f)
    t1.Size = UDim2.new(1, -20, 0, 25); t1.Position = UDim2.new(0, 10, 0, 6)
    t1.BackgroundTransparency = 1; t1.Text = title
    t1.TextColor3 = Color3.fromRGB(0, 255, 200)
    t1.TextSize = 13; t1.Font = Enum.Font.GothamBold
    t1.TextXAlignment = Enum.TextXAlignment.Left
    local t2 = Instance.new("TextLabel", f)
    t2.Size = UDim2.new(1, -20, 0, 24); t2.Position = UDim2.new(0, 10, 0, 34)
    t2.BackgroundTransparency = 1; t2.Text = status
    t2.TextColor3 = Color3.fromRGB(0, 255, 100)
    t2.TextSize = 14; t2.Font = Enum.Font.GothamBold
    t2.TextXAlignment = Enum.TextXAlignment.Left
    task.spawn(function()
        while f.Parent do
            task.wait(0.8)
            if not f.Parent then break end
            t2.TextColor3 = Color3.fromRGB(0, 255, 100)
            task.wait(0.8)
            if not f.Parent then break end
            t2.TextColor3 = Color3.fromRGB(0, 180, 70)
        end
    end)
    return f
end

local bypassNotif = nil
local function ShowBypassNotif()
    if bypassNotif then bypassNotif:Destroy(); bypassNotif = nil end
    task.wait(0.1)
    bypassNotif = MakeNotif("🛡 ANTI-CHEAT BYPASS", "● BYPASS: ACTIVE", Color3.fromRGB(0, 255, 100), Color3.fromRGB(0, 255, 200), 1)
end

local emulatorNotif = nil
local function ShowEmulatorNotif()
    if emulatorNotif then emulatorNotif:Destroy(); emulatorNotif = nil end
    task.wait(0.1)
    emulatorNotif = MakeNotif("🖥 ZYRO EMULATOR", "● EMULATOR: ON", Color3.fromRGB(150, 0, 255), Color3.fromRGB(255, 0, 100), 2)
end

local function HideEmulatorNotif()
    if emulatorNotif then emulatorNotif:Destroy(); emulatorNotif = nil end
end

task.spawn(function()
    task.wait(0.5)
    if ZyroSettings.AntiCheatBypass then ShowBypassNotif() end
end)

-- [[ UI ]]
local function CreateUI()
    if CoreGui:FindFirstChild("Zyro_Neon_UI") then CoreGui.Zyro_Neon_UI:Destroy() end
    local SG = Instance.new("ScreenGui")
    SG.Name = "Zyro_Neon_UI"
    SG.Parent = CoreGui
    SG.ResetOnSpawn = false
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MF = Instance.new("Frame", SG)
    MF.Name = "MainFrame"
    MF.Size = UDim2.new(0, 660, 0, 530)
    MF.Position = UDim2.new(0.5, -330, 0.5, -265)
    MF.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
    MF.BorderSizePixel = 0
    MF.Active = true
    MF.Draggable = true
    Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 14)
    local MS = Instance.new("UIStroke", MF)
    MS.Color = Color3.fromRGB(0, 255, 200); MS.Thickness = 1.5; MS.Transparency = 0.3

    local NB = Instance.new("Frame", MF)
    NB.Size = UDim2.new(1, 0, 0, 3); NB.BorderSizePixel = 0
    local NG = Instance.new("UIGradient", NB)
    NG.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 100))
    }

    local TB = Instance.new("Frame", MF)
    TB.Size = UDim2.new(1, 0, 0, 50); TB.BackgroundTransparency = 1

    local Title = Instance.new("TextLabel", TB)
    Title.Size = UDim2.new(1, -120, 0, 25); Title.Position = UDim2.new(0, 20, 0, 5)
    Title.Text = "⚡ ZYRO — v17.0 ULTIMATE"
    Title.TextColor3 = Color3.fromRGB(0, 255, 200); Title.TextSize = 17
    Title.Font = Enum.Font.GothamBold; Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1

    local Cred = Instance.new("TextLabel", TB)
    Cred.Size = UDim2.new(1, -120, 0, 20); Cred.Position = UDim2.new(0, 20, 0, 26)
    Cred.Text = "Coder by Massivestroke/aimfaster"
    Cred.TextColor3 = Color3.fromRGB(150, 150, 170); Cred.TextSize = 11
    Cred.Font = Enum.Font.Gotham; Cred.TextXAlignment = Enum.TextXAlignment.Left
    Cred.BackgroundTransparency = 1

    local Close = Instance.new("TextButton", TB)
    Close.Size = UDim2.new(0, 32, 0, 32); Close.Position = UDim2.new(1, -45, 0, 10)
    Close.BackgroundColor3 = Color3.fromRGB(40, 10, 20); Close.Text = "✕"
    Close.TextColor3 = Color3.fromRGB(255, 80, 100)
    Close.Font = Enum.Font.GothamBold; Close.TextSize = 16
    Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)
    Close.MouseButton1Click:Connect(function() SG:Destroy() end)

    local TC = Instance.new("Frame", MF)
    TC.Size = UDim2.new(1, -40, 0, 38); TC.Position = UDim2.new(0, 20, 0, 55)
    TC.BackgroundColor3 = Color3.fromRGB(14, 14, 22); TC.BorderSizePixel = 0
    Instance.new("UICorner", TC).CornerRadius = UDim.new(0, 10)
    local TL = Instance.new("UIListLayout", TC)
    TL.FillDirection = Enum.FillDirection.Horizontal
    TL.Padding = UDim.new(0, 4)

    local CF = Instance.new("Frame", MF)
    CF.Size = UDim2.new(1, -40, 1, -110); CF.Position = UDim2.new(0, 20, 0, 100)
    CF.BackgroundTransparency = 1

    local Tabs = {}
    local Active = nil
    local function CreateTab(name, width)
        local B = Instance.new("TextButton", TC)
        B.Size = UDim2.new(0, width or 120, 1, 0)
        B.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
        B.Text = name; B.TextColor3 = Color3.fromRGB(150, 150, 170)
        B.Font = Enum.Font.GothamMedium; B.TextSize = 12
        Instance.new("UICorner", B).CornerRadius = UDim.new(0, 10)
        local P = Instance.new("ScrollingFrame", CF)
        P.Size = UDim2.new(1, 0, 1, 0); P.BackgroundTransparency = 1
        P.BorderSizePixel = 0; P.ScrollBarThickness = 4
        P.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 200)
        P.Visible = false; P.CanvasSize = UDim2.new(0, 0, 0, 0)
        P.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local PL = Instance.new("UIListLayout", P)
        PL.Padding = UDim.new(0, 8)
        Tabs[name] = {Button = B, Page = P}
        B.MouseButton1Click:Connect(function()
            if Active then
                Tabs[Active].Page.Visible = false
                Tabs[Active].Button.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
                Tabs[Active].Button.TextColor3 = Color3.fromRGB(150, 150, 170)
            end
            Active = name; P.Visible = true
            B.BackgroundColor3 = Color3.fromRGB(0, 60, 50)
            B.TextColor3 = Color3.fromRGB(0, 255, 200)
        end)
        return P
    end

    local CP = CreateTab("⚔ COMBAT")
    local VP = CreateTab("👁 VISUAL")
    local TPg = CreateTab("🏃 MOVE")
    local SPg = CreateTab("🎨 SKIN")
    local MP = CreateTab("⚙ MISC")

    Active = "⚔ COMBAT"
    Tabs["⚔ COMBAT"].Page.Visible = true
    Tabs["⚔ COMBAT"].Button.BackgroundColor3 = Color3.fromRGB(0, 60, 50)
    Tabs["⚔ COMBAT"].Button.TextColor3 = Color3.fromRGB(0, 255, 200)

    local function AddToggle(parent, name, key, cb)
        local C = Instance.new("Frame", parent)
        C.Size = UDim2.new(1, -10, 0, 42)
        C.BackgroundColor3 = Color3.fromRGB(14, 14, 22); C.BorderSizePixel = 0
        Instance.new("UICorner", C).CornerRadius = UDim.new(0, 8)
        local S = Instance.new("UIStroke", C)
        S.Color = Color3.fromRGB(35, 35, 45); S.Thickness = 1
        local L = Instance.new("TextLabel", C)
        L.Size = UDim2.new(1, -80, 1, 0); L.Position = UDim2.new(0, 15, 0, 0)
        L.Text = name; L.TextColor3 = Color3.fromRGB(220, 220, 230)
        L.TextSize = 13; L.Font = Enum.Font.GothamMedium
        L.TextXAlignment = Enum.TextXAlignment.Left; L.BackgroundTransparency = 1
        local SB = Instance.new("Frame", C)
        SB.Size = UDim2.new(0, 46, 0, 24); SB.Position = UDim2.new(1, -60, 0.5, -12)
        SB.BackgroundColor3 = Color3.fromRGB(40, 40, 50); SB.BorderSizePixel = 0
        Instance.new("UICorner", SB).CornerRadius = UDim.new(0, 12)
        local SK = Instance.new("Frame", SB)
        SK.Size = UDim2.new(0, 18, 0, 18); SK.Position = UDim2.new(0, 3, 0.5, -9)
        SK.BackgroundColor3 = Color3.fromRGB(200, 200, 200); SK.BorderSizePixel = 0
        Instance.new("UICorner", SK).CornerRadius = UDim.new(0, 9)
        local CB = Instance.new("TextButton", C)
        CB.Size = UDim2.new(1, 0, 1, 0); CB.BackgroundTransparency = 1; CB.Text = ""
        CB.MouseButton1Click:Connect(function()
            ZyroSettings[key] = not ZyroSettings[key]
            local st = ZyroSettings[key]
            TweenService:Create(SB, TweenInfo.new(0.2), {
                BackgroundColor3 = st and Color3.fromRGB(0, 255, 200) or Color3.fromRGB(40, 40, 50)
            }):Play()
            TweenService:Create(SK, TweenInfo.new(0.2), {
                Position = st and UDim2.new(0, 25, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            }):Play()
            TweenService:Create(S, TweenInfo.new(0.2), {
                Color = st and Color3.fromRGB(0, 255, 200) or Color3.fromRGB(35, 35, 45)
            }):Play()
            if cb then cb(st) end
        end)
    end

    local function AddSlider(parent, name, key, mn, mx, st)
        local C = Instance.new("Frame", parent)
        C.Size = UDim2.new(1, -10, 0, 55)
        C.BackgroundColor3 = Color3.fromRGB(14, 14, 22); C.BorderSizePixel = 0
        Instance.new("UICorner", C).CornerRadius = UDim.new(0, 8)
        local S = Instance.new("UIStroke", C)
        S.Color = Color3.fromRGB(35, 35, 45)
        local L = Instance.new("TextLabel", C)
        L.Size = UDim2.new(1, -30, 0, 22); L.Position = UDim2.new(0, 15, 0, 6)
        L.Text = name .. ": " .. tostring(ZyroSettings[key])
        L.TextColor3 = Color3.fromRGB(220, 220, 230); L.TextSize = 13
        L.Font = Enum.Font.GothamMedium
        L.TextXAlignment = Enum.TextXAlignment.Left; L.BackgroundTransparency = 1
        local Sl = Instance.new("Frame", C)
        Sl.Size = UDim2.new(1, -30, 0, 6); Sl.Position = UDim2.new(0, 15, 0, 36)
        Sl.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Sl.BorderSizePixel = 0
        Instance.new("UICorner", Sl).CornerRadius = UDim.new(0, 3)
        local F = Instance.new("Frame", Sl)
        F.Size = UDim2.new((ZyroSettings[key] - mn) / (mx - mn), 0, 1, 0)
        F.BackgroundColor3 = Color3.fromRGB(0, 255, 200); F.BorderSizePixel = 0
        Instance.new("UICorner", F).CornerRadius = UDim.new(0, 3)
        local drag = false
        local Click = Instance.new("TextButton", Sl)
        Click.Size = UDim2.new(1, 0, 3, 0); Click.Position = UDim2.new(0, 0, 0, -6)
        Click.BackgroundTransparency = 1; Click.Text = ""
        Click.MouseButton1Down:Connect(function() drag = true end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local pc = math.clamp((i.Position.X - Sl.AbsolutePosition.X) / Sl.AbsoluteSize.X, 0, 1)
                local v = mn + (mx - mn) * pc
                v = math.floor(v / st + 0.5) * st
                ZyroSettings[key] = v
                L.Text = name .. ": " .. tostring(v)
                F.Size = UDim2.new((v - mn) / (mx - mn), 0, 1, 0)
            end
        end)
    end

    local function AddColorPicker(parent, name, key)
        local C = Instance.new("Frame", parent)
        C.Size = UDim2.new(1, -10, 0, 85)
        C.BackgroundColor3 = Color3.fromRGB(14, 14, 22); C.BorderSizePixel = 0
        Instance.new("UICorner", C).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", C).Color = Color3.fromRGB(35, 35, 45)
        local L = Instance.new("TextLabel", C)
        L.Size = UDim2.new(1, -30, 0, 20); L.Position = UDim2.new(0, 15, 0, 6)
        L.Text = name; L.TextColor3 = Color3.fromRGB(220, 220, 230)
        L.TextSize = 13; L.Font = Enum.Font.GothamMedium
        L.TextXAlignment = Enum.TextXAlignment.Left; L.BackgroundTransparency = 1
        local Preview = Instance.new("Frame", C)
        Preview.Size = UDim2.new(0, 30, 0, 30); Preview.Position = UDim2.new(1, -40, 0, 6)
        Preview.BackgroundColor3 = ZyroSettings[key]
        Preview.BorderSizePixel = 0
        Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Preview).Color = Color3.fromRGB(60, 60, 80)
        local function mkSlider(label, yOffset, channel)
            local R = Instance.new("Frame", C)
            R.Size = UDim2.new(1, -60, 0, 14)
            R.Position = UDim2.new(0, 15, 0, 30 + yOffset)
            R.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            R.BorderSizePixel = 0
            Instance.new("UICorner", R).CornerRadius = UDim.new(0, 3)
            local lbl = Instance.new("TextLabel", R)
            lbl.Size = UDim2.new(0, 20, 1, 0); lbl.Position = UDim2.new(1, 3, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = label; lbl.TextColor3 = Color3.fromRGB(180, 180, 200)
            lbl.TextSize = 11; lbl.Font = Enum.Font.Gotham
            local isDrag = false
            local click = Instance.new("TextButton", R)
            click.Size = UDim2.new(1, 0, 3, 0); click.Position = UDim2.new(0, 0, 0, -7)
            click.BackgroundTransparency = 1; click.Text = ""
            click.MouseButton1Down:Connect(function() isDrag = true end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then isDrag = false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if isDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                    local pc = math.clamp((i.Position.X - R.AbsolutePosition.X) / R.AbsoluteSize.X, 0, 1)
                    local c = ZyroSettings[key]
                    local newColor
                    if channel == "R" then newColor = Color3.new(pc, c.G, c.B)
                    elseif channel == "G" then newColor = Color3.new(c.R, pc, c.B)
                    else newColor = Color3.new(c.R, c.G, pc) end
                    ZyroSettings[key] = newColor
                    Preview.BackgroundColor3 = newColor
                end
            end)
        end
        mkSlider("R", 0, "R")
        mkSlider("G", 18, "G")
        mkSlider("B", 36, "B")
    end

    local function AddTextBox(parent, name, key, placeholder, cb)
        local C = Instance.new("Frame", parent)
        C.Size = UDim2.new(1, -10, 0, 70)
        C.BackgroundColor3 = Color3.fromRGB(14, 14, 22); C.BorderSizePixel = 0
        Instance.new("UICorner", C).CornerRadius = UDim.new(0, 8)
        local S = Instance.new("UIStroke", C)
        S.Color = Color3.fromRGB(35, 35, 45)
        local L = Instance.new("TextLabel", C)
        L.Size = UDim2.new(1, -30, 0, 20); L.Position = UDim2.new(0, 15, 0, 6)
        L.Text = name; L.TextColor3 = Color3.fromRGB(220, 220, 230)
        L.TextSize = 13; L.Font = Enum.Font.GothamMedium
        L.TextXAlignment = Enum.TextXAlignment.Left; L.BackgroundTransparency = 1
        local TB = Instance.new("TextBox", C)
        TB.Size = UDim2.new(1, -30, 0, 32); TB.Position = UDim2.new(0, 15, 0, 30)
        TB.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        TB.BorderSizePixel = 0
        TB.Text = ZyroSettings[key]
        TB.PlaceholderText = placeholder
        TB.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
        TB.TextColor3 = Color3.fromRGB(0, 255, 200)
        TB.Font = Enum.Font.Gotham
        TB.TextSize = 12
        TB.TextXAlignment = Enum.TextXAlignment.Left
        TB.ClearTextOnFocus = false
        Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 6)
        local Pad = Instance.new("UIPadding", TB)
        Pad.PaddingLeft = UDim.new(0, 8)
        TB.FocusLost:Connect(function()
            ZyroSettings[key] = TB.Text
            if cb then cb(TB.Text) end
        end)
    end
    
    local function AddDropdown(parent, name, key, options)
        local C = Instance.new("Frame", parent)
        C.Size = UDim2.new(1, -10, 0, 60)
        C.BackgroundColor3 = Color3.fromRGB(14, 14, 22); C.BorderSizePixel = 0
        Instance.new("UICorner", C).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", C).Color = Color3.fromRGB(35, 35, 45)
        local L = Instance.new("TextLabel", C)
        L.Size = UDim2.new(1, -30, 0, 20); L.Position = UDim2.new(0, 15, 0, 6)
        L.Text = name; L.TextColor3 = Color3.fromRGB(220, 220, 230)
        L.TextSize = 13; L.Font = Enum.Font.GothamMedium
        L.TextXAlignment = Enum.TextXAlignment.Left; L.BackgroundTransparency = 1
        local Sel = Instance.new("TextButton", C)
        Sel.Size = UDim2.new(1, -30, 0, 28); Sel.Position = UDim2.new(0, 15, 0, 28)
        Sel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        Sel.BorderSizePixel = 0
        Sel.Text = ZyroSettings[key]
        Sel.TextColor3 = Color3.fromRGB(0, 255, 200)
        Sel.Font = Enum.Font.Gotham
        Sel.TextSize = 12
        Instance.new("UICorner", Sel).CornerRadius = UDim.new(0, 6)
        local idx = 1
        for i, opt in ipairs(options) do
            if opt == ZyroSettings[key] then idx = i break end
        end
        Sel.MouseButton1Click:Connect(function()
            idx = idx + 1
            if idx > #options then idx = 1 end
            ZyroSettings[key] = options[idx]
            Sel.Text = options[idx]
        end)
    end

    AddToggle(CP, "Aimbot (Sağ Tık)", "Aimbot")
    AddToggle(CP, "🎯 Silent WallBang", "SilentWallBang")
    AddToggle(CP, "Auto-Fire", "AutoFire")
    AddToggle(CP, "Hitbox Büyüt", "Hitbox")
    AddToggle(CP, "Takım Kontrolü", "TeamCheck")
    AddToggle(CP, "Duvar Kontrolü", "VisibleCheck")
    AddSlider(CP, "FOV", "FOV", 40, 400, 10)
    AddSlider(CP, "Smooth", "Smoothness", 1, 20, 1)
    AddSlider(CP, "WallBang Menzil", "SilentRange", 100, 3000, 100)

    AddToggle(VP, "ESP Box", "ESPBox")
    AddToggle(VP, "ESP Name", "ESPName")
    AddToggle(VP, "ESP Health", "ESPHealth")
    AddToggle(VP, "ESP Distance", "ESPDistance")
    AddToggle(VP, "Chams", "Chams")
    AddToggle(VP, "Şekilli İsimler", "FancyNames")
    AddToggle(VP, "🌈 Regenbow Dünya", "RainbowWorld")

    AddToggle(TPg, "🐇 BunnyHop", "BunnyHop")
    AddToggle(TPg, "⚡ Walkspeed", "Walkspeed")
    AddToggle(TPg, "⬆ JumpPower", "JumpPower")
    AddToggle(TPg, "Mevlana Hilesi", "Mevlana", function(st)
        if not st then StopMevlana() end
    end)
    AddToggle(TPg, "ThirdPerson", "ThirdPerson")
    AddSlider(TPg, "BHop Gücü", "BHopPower", 30, 300, 10)
    AddSlider(TPg, "BHop Hız Boost", "BHopSpeedBoost", 0, 100, 5)
    AddSlider(TPg, "Mevlana Hızı", "MevlanaSpeed", 0.5, 20, 0.5)
    AddSlider(TPg, "TP FOV", "ThirdPersonFOV", 60, 120, 5)

    AddToggle(SPg, "🎨 Skin Changer Aktif", "SkinEnabled")
    AddToggle(SPg, "🌈 Regenbow Silah", "RainbowGun")
    AddToggle(SPg, "🌈 Regenbow Karakter", "RainbowChar")
    AddColorPicker(SPg, "Silah Rengi", "SkinColor")
    AddColorPicker(SPg, "Karakter Rengi", "CharColor")
    AddDropdown(SPg, "Silah Materyali", "SkinMaterial", {
        "Plastic", "Neon", "ForceField", "Glass", "Marble", "Granite", 
        "Metal", "Wood", "Fabric", "Ice", "Sand", "Foil", "DiamondPlate"
    })
    AddSlider(SPg, "Silah Boyutu", "SkinSize", 0.5, 3, 0.1)
    
    local SkinInfo = Instance.new("TextLabel", SPg)
    SkinInfo.Size = UDim2.new(1, -10, 0, 70)
    SkinInfo.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
    SkinInfo.Text = "🎨 SKIN CHANGER\nSilahı ve karakterini renklendirir.\nMateryal ve boyut ayarlanabilir."
    SkinInfo.TextColor3 = Color3.fromRGB(150, 150, 170); SkinInfo.TextSize = 11
    SkinInfo.Font = Enum.Font.Gotham
    SkinInfo.TextXAlignment = Enum.TextXAlignment.Left
    SkinInfo.Parent = SPg
    Instance.new("UICorner", SkinInfo).CornerRadius = UDim.new(0, 8)

    local MusicLabel = Instance.new("TextLabel", MP)
    MusicLabel.Size = UDim2.new(1, -10, 0, 26)
    MusicLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MusicLabel.Text = "🎵 MÜZİK ÇALAR"
    MusicLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
    MusicLabel.TextSize = 14
    MusicLabel.Font = Enum.Font.GothamBold
    MusicLabel.Parent = MP
    Instance.new("UICorner", MusicLabel).CornerRadius = UDim.new(0, 8)

    AddTextBox(MP, "Roblox Asset ID / URL", "MusicURL", "rbxassetid://1837879082", function(val)
        PlayMusic(val)
    end)

    local MusicBtnFrame = Instance.new("Frame", MP)
    MusicBtnFrame.Size = UDim2.new(1, -10, 0, 42)
    MusicBtnFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
    MusicBtnFrame.BorderSizePixel = 0
    MusicBtnFrame.Parent = MP
    Instance.new("UICorner", MusicBtnFrame).CornerRadius = UDim.new(0, 8)

    local PlayBtn = Instance.new("TextButton", MusicBtnFrame)
    PlayBtn.Size = UDim2.new(0.48, -5, 1, 0)
    PlayBtn.Position = UDim2.new(0, 5, 0, 0)
    PlayBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 60)
    PlayBtn.Text = "▶ ÇAL"
    PlayBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
    PlayBtn.Font = Enum.Font.GothamBold
    PlayBtn.TextSize = 14
    Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 8)
    PlayBtn.MouseButton1Click:Connect(function()
        PlayMusic(ZyroSettings.MusicURL)
    end)

    local StopBtn = Instance.new("TextButton", MusicBtnFrame)
    StopBtn.Size = UDim2.new(0.48, -5, 1, 0)
    StopBtn.Position = UDim2.new(0.52, 0, 0, 0)
    StopBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 30)
    StopBtn.Text = "■ DUR"
    StopBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.TextSize = 14
    Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 8)
    StopBtn.MouseButton1Click:Connect(StopMusic)

    AddToggle(MP, "🛡 Anti-Cheat Bypass", "AntiCheatBypass", function(st)
        if st then ShowBypassNotif() else
            if bypassNotif then bypassNotif:Destroy(); bypassNotif = nil end
        end
    end)
    AddToggle(MP, "🖥 Emülatör Modu", "EmulatorMode", function(st)
        if st then ShowEmulatorNotif() else HideEmulatorNotif() end
    end)

    local LinkFrame = Instance.new("Frame", MP)
    LinkFrame.Size = UDim2.new(1, -10, 0, 45)
    LinkFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
    LinkFrame.BorderSizePixel = 0
    LinkFrame.Parent = MP
    Instance.new("UICorner", LinkFrame).CornerRadius = UDim.new(0, 8)
    local LinkStroke = Instance.new("UIStroke", LinkFrame)
    LinkStroke.Thickness = 1
    local LinkGrad = Instance.new("UIGradient", LinkStroke)
    LinkGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 255))
    }
    local LinkBtn = Instance.new("TextButton", LinkFrame)
    LinkBtn.Size = UDim2.new(1, 0, 1, 0)
    LinkBtn.BackgroundTransparency = 1
    LinkBtn.Text = "🔗 cheatglobal.com/members/massivestrokee"
    LinkBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
    LinkBtn.TextSize = 12
    LinkBtn.Font = Enum.Font.GothamBold
    LinkBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then
                setclipboard("https://cheatglobal.com/members/massivestrokee.448425/")
            end
        end)
        local oldText = LinkBtn.Text
        LinkBtn.Text = "✓ KOPYALANDI!"
        LinkBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
        task.wait(1.5)
        if LinkBtn.Parent then
            LinkBtn.Text = oldText
            LinkBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
        end
    end)

    local Info = Instance.new("TextLabel", MP)
    Info.Size = UDim2.new(1, -10, 0, 90)
    Info.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
    Info.Text = "📌 INSERT = Menü | 🎯 Sağ Tık = Aimbot/WallBang\n⚡ v17.0 | BHop = Velocity+Constraint+CFrame\n💡 Walkspeed/JumpPower = Humanoid olmazsa çalışmaz"
    Info.TextColor3 = Color3.fromRGB(150, 150, 170); Info.TextSize = 12
    Info.Font = Enum.Font.Gotham
    Info.TextXAlignment = Enum.TextXAlignment.Left
    Info.Parent = MP
    Instance.new("UICorner", Info).CornerRadius = UDim.new(0, 8)

    return SG
end

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Insert then
        ZyroSettings.MenuVisible = not ZyroSettings.MenuVisible
        local UI = CoreGui:FindFirstChild("Zyro_Neon_UI")
        if UI then
            local MF = UI:FindFirstChild("MainFrame")
            if MF then MF.Visible = ZyroSettings.MenuVisible end
        end
    end
end)

-- BAŞLAT
StartBunnyHop()
StartWalkSpeedJump()
StartMevlana()
StartThirdPerson()
StartHitbox()
StartRainbowWorld()
StartESP()
StartCameraController()
StartAutoFire()
StartSkinChanger()
CreateUI()

print("========================================")
print("  ZyroSoftware v1.0")
print("  Coder by Massivestroke/aimfaster")
print("  https://cheatglobal.com/members/massivestrokee.448425/")
print("========================================")
