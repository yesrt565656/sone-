--https://www.youtube.com/c/anto6666 
-- // Constants \\ --
-- [ Services ] --
local Services = setmetatable({}, {__index = function(Self, Index)
local NewService = game.GetService(game, Index)
if NewService then
Self[Index] = NewService
end
return NewService
end})

-- [ Modules ] --
local UserInterface = loadstring(game:HttpGet("https://raw.githubusercontent.com/icuck/collection-dump/main/AbstractUI", true))()
local Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/iHavoc101/Genesis-Studios/main/Modules/DrawingAPI.lua", true))()

local ToolTip = require(Services.ReplicatedStorage.Modules_client.TooltipModule)

-- [ LocalPlayer ] --
local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ Raycast Parameters ] --
local RaycastParameters = RaycastParams.new()
RaycastParameters.IgnoreWater = true
RaycastParameters.FilterType = Enum.RaycastFilterType.Blacklist
RaycastParameters.FilterDescendantsInstances = {LocalPlayer.Character}

-- // Variables \\ --
-- [ Info ] --
local Info = {
    SilentAIMEnabled = false;
    TriggeredEnabled = false;
    ArmsCheckEnabled = true;
    TeamWhitelist = "";
    FieldOfView = 250;
    Accuracy = 100;
}

local LastArrest = time()

-- [ Interface ] --
local FOVCircle = Drawing.new("Circle", {
   Thickness = 2,
   Color = Color3.fromRGB(200, 200, 200),
   NumSides = 25,
   Radius = _G.FOV
})

local Target = Drawing.new("Triangle", {
   Thickness = 3,
   Color = Color3.fromRGB(0, 200, 255)
})

-- [ Weapons ] --
local Weapons = {
   "Remington 870";
   "AK-47";
   "M9";
   "M4A1";
   "Hammer";
   "Crude Knife";
}

-- [ Metatable ] --
local RawMetatable = getrawmetatable(game)
local __NameCall = RawMetatable.__namecall
local __Index = RawMetatable.__index


-- // Functions \\ --
local function ValidCharacter(Character)
   return Character and (Character.FindFirstChildWhichIsA(Character, "Humanoid") and Character.FindFirstChildWhichIsA(Character, "Humanoid").Health ~= 0) or false
end

local function NotObstructing(Destination, Ancestor)
   -- [ Camera ] --
   local ObstructingParts = Camera.GetPartsObscuringTarget(Camera, {Destination}, {Ancestor, LocalPlayer.Character})

   for i,v in ipairs(ObstructingParts) do
       pcall(function()
           if v.Transparency >= 1 then
               table.remove(ObstructingParts, i)
           end
       end)
   end

   if #ObstructingParts <= 0 then
       return true
   end

   -- [ Raycast ] --
   RaycastParameters.FilterDescendantsInstances = {LocalPlayer.Character}

   local Origin = Camera.CFrame.Position
   local Direction = (Destination - Origin).Unit * 500
   local RayResult = workspace.Raycast(workspace, Origin, Direction, RaycastParameters) or {
       Instance = nil;
       Position = Origin + Direction;
       Material = Enum.Material.Air;
   }

   if RayResult.Instance and (RayResult.Instance.IsDescendantOf(RayResult.Instance, Ancestor) or RayResult.Instance == Ancestor) then
       return true
   end

   -- [ Obstructed ] --
   return false
end

local function IsArmed(Player)
   for i,v in ipairs(Weapons) do
       local Tool = Player.Backpack.FindFirstChild(Player.Backpack, v) or Player.Character.FindFirstChild(Player.Character, v)
       if Tool then
           return true
       end
   end
   return false
end

local function ClosestPlayerToCursor(Distance)
    local Closest = nil
    local Position = nil
    local ShortestDistance = Distance or math.huge

    local MousePosition = Services.UserInputService:GetMouseLocation(Services.UserInputService)

    for i, v in ipairs(Services.Players:GetPlayers()) do
        if v ~= LocalPlayer and (v.Team ~= LocalPlayer.Team and tostring(v.Team) ~= Info.TeamWhitelist) and ValidCharacter(v.Character) then
            if Info.ArmsCheckEnabled and (v.Team == Services.Teams.Inmates and IsArmed(v) == false) then
                continue
            end

            local TargetPart = v.Character:FindFirstChild(Info.AimTarget or "HumanoidRootPart")
            if not TargetPart then continue end

            -- Проверка видимости
            if Info.AimTarget == "Visible Part" then
                for _, Part in ipairs(v.Character:GetChildren()) do
                    if Part:IsA("BasePart") and NotObstructing(Part.Position, v.Character) then
                        TargetPart = Part
                        break
                    end
                end
            end

            if not TargetPart or NotObstructing(TargetPart.Position, v.Character) == false then
                continue
            end

            local ViewportPosition, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
            local Magnitude = (Vector2.new(ViewportPosition.X, ViewportPosition.Y) - MousePosition).Magnitude

            if OnScreen and Magnitude < ShortestDistance then
                Closest = v
                Position = ViewportPosition
                ShortestDistance = Magnitude
            end
        end
    end

    return Closest, Position
end

local function SwitchGuns()
   if LocalPlayer.Character.FindFirstChild(LocalPlayer.Character, "Remington 870") then
       local Tool = LocalPlayer.Backpack.FindFirstChild(LocalPlayer.Backpack, "M4A1") or LocalPlayer.Backpack.FindFirstChild(LocalPlayer.Backpack, "AK-47") or LocalPlayer.Backpack.FindFirstChild(LocalPlayer.Backpack, "M9")

       local Humanoid = LocalPlayer.Character.FindFirstChildWhichIsA(LocalPlayer.Character, "Humanoid")
       Humanoid.EquipTool(Humanoid, Tool)
   else
       local Tool = LocalPlayer.Backpack.FindFirstChild(LocalPlayer.Backpack, "Remington 870")

       local Humanoid = LocalPlayer.Character.FindFirstChildWhichIsA(LocalPlayer.Character, "Humanoid")
       Humanoid.EquipTool(Humanoid, Tool)
   end
end

local function Crash(Gun, BulletCount, ShotCount)
   local ShootEvent = Services.ReplicatedStorage.ShootEvent
   local StartTime = time()
   local BulletTable = {}

   for i = 1, BulletCount do
       BulletTable[i] = {
           Cframe = CFrame.new(),
           Distance = math.huge
       }
   end
   for i = 1, ShotCount do
       ShootEvent:FireServer(BulletTable, Gun)
       if time() - StartTime > 5 then
           break
       end
   end
end

-- // User Interface \\ --
-- [ Window ] --
local Window = UserInterface.new("Confinement X", UDim2.new(0, 420, 0, 420))

-- [ Assists ] --
Window:Divider("Assists")

Window:Toggle("Silent Aim", "Shoots toward the nearest player to your cursor.", false, function(State)
   Info.SilentAIMEnabled = State
end)

Window:Toggle("Trigger Bot", "Press G to temporarily disable.", false, function(State)
   Info.TriggeredEnabled = State
end)

Window:Divider("Settings")

Window:Slider("Field Of View", "Recommended: 250", 10, 500, 250, function(Value)
   Info.FieldOfView = Value
end)

Window:Slider("Accuracy", "Adjust aiming accuracy", 1, 100, 100, function(Value)
    Info.Accuracy = Value
end)

-- Обновляем список частей тела
Window:Dropdown("Aim Target", "Choose part of the body to aim at", 
    {"Head", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Torso"}, 
    function(Value)
        Info.AimTarget = Value
    end
)

-- Функция для поиска нужной части тела
local function GetTargetPart(Character)
    -- Если выбрана конкретная часть тела
    if Info.AimTarget then
        local TargetPart = Character:FindFirstChild(Info.AimTarget)
        if TargetPart then
            return TargetPart
        end
    end

    -- Если ничего не найдено, используем HumanoidRootPart как запасной вариант
    return Character:FindFirstChild("HumanoidRootPart")
end

Window:Dropdown("Team Whitelist", "Team for Silent-Aim to ignore.", {"Guards", "Inmates", "Criminals"}, function(Value)
   Info.TeamWhitelist = Value
end)

Window:Toggle("Danger Check", "Checks if an Inmate has gun.", false, function(State)
   Info.ArmsCheckEnabled = State
end)

Window:Divider("Other")

-- [ Rage ] --
Window:Divider("Rage")

Window:Button("Kill All", "Kills everyone in-game", function()
   local GunScript = (LocalPlayer.Backpack:FindFirstChild("GunInterface", true) or LocalPlayer.Character:FindFirstChild("GunInterface", true))
   if GunScript then
       for i,v in ipairs(game.Players:GetPlayers()) do
           if v ~= LocalPlayer then
               local BulletInfo = {
                   [1] = {
                       ["RayObject"] = Ray.new(Vector3.new(845.555908, 101.429337, 2269.43945), Vector3.new(-391.152252, 8.65560055, -83.2166901)),
                       ["Distance"] = 3.2524313926697,
                       ["Cframe"] = CFrame.new(840.310791, 101.334137, 2267.87988, 0.0636406094, 0.151434347, -0.986416459, 0, 0.988420188, 0.151741937, 0.997972965, -0.00965694897, 0.0629036576),
                       ["Hit"] = v.Character.Head
                   },
                   [2] = {
                       ["RayObject"] = Ray.new(Vector3.new(845.555908, 101.429337, 2269.43945), Vector3.new(-392.481476, -8.44939327, -76.7261353)),
                       ["Distance"] = 3.2699294090271,
                       ["Cframe"] = CFrame.new(840.290466, 101.184189, 2267.93506, 0.0964837447, 0.0589403138, -0.993587971, 4.65661287e-10, 0.998245299, 0.0592165813, 0.995334625, -0.00571343815, 0.0963144377),
                       ["Hit"] = v.Character.Head
                   },
                   [3] = {
                       ["RayObject"] = Ray.new(Vector3.new(845.555908, 101.429337, 2269.43945), Vector3.new(-389.21701, -2.50536323, -92.2163162)),
                       ["Distance"] = 3.1665518283844,
                       ["Cframe"] = CFrame.new(840.338867, 101.236496, 2267.80371, 0.0166504811, 0.0941716284, -0.995416701, 1.16415322e-10, 0.995554805, 0.0941846818, 0.999861419, -0.00156822044, 0.0165764652),
                       ["Hit"] = v.Character.Head
                   },
                   [4] = {
                       ["RayObject"] = Ray.new(Vector3.new(845.555908, 101.429337, 2269.43945), Vector3.new(-393.353973, 3.13988972, -72.5452042)),
                       ["Distance"] = 3.3218522071838,
                       ["Cframe"] = CFrame.new(840.277222, 101.285957, 2267.9707, 0.117109694, 0.118740402, -0.985994935, -1.86264515e-09, 0.992826641, 0.119563118, 0.993119001, -0.0140019981, 0.116269611),
                       ["Hit"] = v.Character.Head
                   },
                   [5] = {
                       ["RayObject"] = Ray.new(Vector3.new(845.555908, 101.429337, 2269.43945), Vector3.new(-390.73172, 3.2097764, -85.5477524)),
                       ["Distance"] = 3.222757101059,
                       ["Cframe"] = CFrame.new(840.317993, 101.286423, 2267.86035, 0.0517584644, 0.123365127, -0.991010666, 0, 0.992340803, 0.123530701, 0.99865967, -0.00639375951, 0.0513620302),
                       ["Hit"] = v.Character.Head
                   }
               }
               Services.ReplicatedStorage.ShootEvent:FireServer(BulletInfo, GunScript.Parent)
               Services.ReplicatedStorage.ShootEvent:FireServer(BulletInfo, GunScript.Parent)
           end
       end
   else
       ToolTip.update("No gun found!")
   end
end)

-- Добавляем раздел для модификации оружия
Window:Divider("Weapon Modifications")

-- Добавляем переключатель AutoFire
Window:Toggle("Auto Fire", "AutoFire (not trigger bot)", false, function(State)
    -- Проверяем текущее оружие и обновляем его параметр AutoFire
    local GunStates = LocalPlayer.Character:FindFirstChild("GunStates", true)
    if GunStates then
        local GunInfo = require(GunStates)
        GunInfo.AutoFire = State  -- Устанавливаем значение AutoFire в зависимости от State
    end
end)

-- Создаем таблицу с параметрами оружия и их настройками
local WeaponSettings = {
    { Name = "Fire Rate", Min = 0.01, Max = 1, Default = 0.087, Key = "FireRate" },
    { Name = "Reload Time", Min = 0.01, Max = 5, Default = 0.01, Key = "ReloadTime" },
    { Name = "Max Ammo", Min = 1, Max = 100, Default = 15, Key = "MaxAmmo" },
    { Name = "Stored Ammo", Min = 1, Max = 2000, Default = 1488, Key = "StoredAmmo" },
    { Name = "Bullets Per Shot", Min = 1, Max = 10, Default = 1, Key = "Bullets" },
    { Name = "Damage", Min = 1, Max = 100, Default = 1, Key = "Damage" },
    { Name = "Spread", Min = 0, Max = 50, Default = 1, Key = "Spread" },    
}

-- Перебираем настройки и создаем слайдеры для каждого параметра
for _, setting in ipairs(WeaponSettings) do
    Window:Slider(
        setting.Name, 
        "Adjust " .. setting.Name, 
        setting.Min, 
        setting.Max, 
        setting.Default, 
        function(Value)
            -- Обновляем параметры текущего оружия
            local GunStates = LocalPlayer.Character:FindFirstChild("GunStates", true)
            if GunStates then
                local GunInfo = require(GunStates)
                GunInfo[setting.Key] = Value
            end
        end
    )
end

-- [ Miscellaneous ] --
Window:Divider("Miscellaneous")

Window:Button("Get Guns", "Grabs all(doesn't work)", function()
   local HasSWAT = Services.MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, 96651)

   workspace.Remote.ItemHandler:InvokeServer(workspace.Prison_ITEMS.giver["Remington 870"].ITEMPICKUP)
   if HasSWAT then
       workspace.Remote.ItemHandler:InvokeServer(workspace.Prison_ITEMS.giver["M4A1"].ITEMPICKUP)
   end
   workspace.Remote.ItemHandler:InvokeServer(workspace.Prison_ITEMS.giver["AK-47"].ITEMPICKUP)
   workspace.Remote.ItemHandler:InvokeServer(workspace.Prison_ITEMS.giver["M9"].ITEMPICKUP)

   if HasSWAT then
       workspace.Remote.ItemHandler:InvokeServer(workspace.Prison_ITEMS.clothes["Riot Police"].ITEMPICKUP)
   end
end)

-- [ Credits ] --
Window:Divider("Credits")

Window:Button("kryt224", "Script Creator", function()
   setclipboard("kryt224")
end)

-- // Silent Aim Logic \\ --

setreadonly(getrawmetatable(game), false)
local RawMetatable = getrawmetatable(game)
local NameCall = RawMetatable.namecall
local Index = RawMetatable.index

RawMetatable.__index = newcclosure(function(Self, Index)
    if Info.SilentAIMEnabled == true and checkcaller() == false then
        if typeof(Self) == "Instance" and (Self:IsA("PlayerMouse") or Self:IsA("Mouse")) then
            if Index == "Hit" then
                local Closest, _ = ClosestPlayerToCursor(Info.FieldOfView) -- Находим ближайшего игрока
                if Closest then
                    -- Выбор части тела для стрельбы
                    local TargetPart = Closest.Character:FindFirstChild(Info.AimTarget or "HumanoidRootPart")
                    
                    -- Если выбран "Visible Part", ищем первую видимую часть тела
                    if Info.AimTarget == "Visible Part" then
                        for _, Part in ipairs(Closest.Character:GetChildren()) do
                            if Part:IsA("BasePart") and NotObstructing(Part.Position, Closest.Character) then
                                TargetPart = Part
                                break
                            end
                        end
                    end

                    -- Если не нашли целевую часть, используем голову как запасной вариант
                    if not TargetPart then
                        TargetPart = Closest.Character:FindFirstChild("Head")
                    end

                    -- Получаем позицию цели
                    local TargetPosition = TargetPart and TargetPart.Position or Vector3.new(0, 0, 0)

                    -- Рассчитываем направление на цель
                    local DirectionToTarget = (TargetPosition - Camera.CFrame.Position).unit
                    local AngleOffset = math.random(-1, 1) * (1 - Info.Accuracy / 100)  -- Маленькое отклонение угла

                    -- Ограничиваем смещение внутри целевой области
                    local MaxOffset = TargetPart.Size.Magnitude / 2  -- Используем радиус целевой части как предел смещения

                    -- Коррекция по осям для более плавного смещения, ограничиваем в пределах цели
                    local RandomOffset = Vector3.new(
                        math.clamp(AngleOffset * DirectionToTarget.X * 5, -MaxOffset, MaxOffset),  -- Ограничиваем отклонение по оси X
                        math.clamp(math.random(-5, 5) * (1 - Info.Accuracy / 100), -MaxOffset, MaxOffset),  -- Ограничиваем отклонение по оси Y
                        math.clamp(AngleOffset * DirectionToTarget.Z * 5, -MaxOffset, MaxOffset)   -- Ограничиваем отклонение по оси Z
                    )

                    -- Применяем плавное смещение и возвращаем откорректированную позицию
                    local AdjustedPosition = TargetPosition + RandomOffset
                    return CFrame.new(AdjustedPosition)
                end
            end
        end
    end

    return __Index(Self, Index)
end)

setreadonly(getrawmetatable(game), true)

-- // Event Listeners \\ --
Services.RunService.RenderStepped:Connect(function()
   if Info.SilentAIMEnabled == true then
       -- FOV --
       FOVCircle.Visible = true
       FOVCircle.Radius = Info.FieldOfView
       FOVCircle.Position = Services.UserInputService:GetMouseLocation()

       -- Target --
       local Closest, Position = ClosestPlayerToCursor(Info.FieldOfView)
       if Closest then
           Target.PointA = Vector2.new(Position.X - 25, Position.Y + 25)
           Target.PointB = Vector2.new(Position.X + 25, Position.Y + 25)
           Target.PointC = Vector2.new(Position.X, Position.Y - 25)
           if Info.TriggeredEnabled and not Services.UserInputService:IsKeyDown(Enum.KeyCode.G) then
               mouse1click()
           end
       end
       Target.Visible = Closest ~= nil
   else
       FOVCircle.Visible = false
       Target.Visible = false
   end
end)

LocalPlayer.Chatted:Connect(function(Message)
   if string.find(Message:lower(), "-lag") then
       local GunScript = (LocalPlayer.Backpack:FindFirstChild("GunInterface", true) or LocalPlayer.Character:FindFirstChild("GunInterface", true))
       if GunScript then
           ToolTip.update("Lagging...")
           Crash(GunScript.Parent, 100, 10)
           ToolTip.update("Lagged!")
       else
          ToolTip.update("Error: No gun found!")
       end
   end
end)

local LastShotDetected = time()
for i,v in ipairs(getconnections(Services.ReplicatedStorage.ReplicateEvent.OnClientEvent)) do
   local OldFunction = v.Function
   v.Function = function(BulletStats, IsTaser)
       if #BulletStats > 25 or time() - LastShotDetected > 0.02 then
           ToolTip.update("Bullet Overload: Removing...")
           return
       end
       LastShotDetected = time()
       OldFunction(BulletStats, IsTaser)
   end
end

local LastSoundDetected = time()
for i,v in ipairs(getconnections(Services.ReplicatedStorage.SoundEvent.OnClientEvent)) do
   local OldFunction = v.Function
   v.Function = function(Sound)
       if time() - LastSoundDetected > 0.02 then
           ToolTip.update("Audio Overload: Removing...")
           return
       end
       LastSoundDetected = time()
       OldFunction(Sound)
   end
end


-- // KeyBinds \\ --
Services.UserInputService.InputBegan:Connect(function(Input, GameProcessed)
   if _G.ArrestAssist == false or GameProcessed or LocalPlayer.Character:FindFirstChild("Handcuffs") == nil then
       return
   end

   local Delta = time() - LastArrest
   if Delta <= 15 then
       ToolTip.update("Wait " .. tostring(math.floor(Delta)) .. " seconds before arresting again!")
   end

   if Input.UserInputType == Enum.UserInputType.MouseButton1 then
       local Closest = ClosestPlayerToCursor(_G.FOV)
       if Closest then
           local Result = workspace.Remote.arrest:InvokeServer(Closest.Character.HumanoidRootPart)
           ToolTip.update(Result == true and "Successfully arrested!" or Result)
           if Result == true then
               LastArrest = time()
           end
       end
   end
end)

Services.ContextActionService:BindAction("Switch Bind", function(actionName, InputState, inputObject)
if InputState == Enum.UserInputState.End then
return
   end
   pcall(SwitchGuns)
end, true, Enum.KeyCode.Q)

-- // Actions \\ --
LocalPlayer.PlayerGui.Home.fadeFrame.Visible = false

return {};
