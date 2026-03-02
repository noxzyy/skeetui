local Players   = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local FOV         = 120
local TARGET_PART = "Head"
local silentAim   = false

local fovCircle = Drawing.new("Circle")
fovCircle.Radius    = FOV
fovCircle.Color     = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.Filled    = false
fovCircle.Visible   = true

local targetDot = Drawing.new("Circle")
targetDot.Radius    = 5
targetDot.Color     = Color3.fromRGB(255, 50, 50)
targetDot.Thickness = 2
targetDot.Filled    = true
targetDot.Visible   = false

local targetRing = Drawing.new("Circle")
targetRing.Radius    = 12
targetRing.Color     = Color3.fromRGB(255, 50, 50)
targetRing.Thickness = 1
targetRing.Filled    = false
targetRing.Visible   = false

local currentTarget = nil

local function getTarget()
    local center = Camera.ViewportSize / 2
    local nearest, nearestDist = nil, FOV

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(TARGET_PART) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < nearestDist then
            nearestDist = dist
            nearest = p
        end
    end

    return nearest
end

local RaycastModule = filtergc("table", {
    Keys = { "cast", "castThrough", "isPartOfHumanoid" }
}, true)
local castFn = RaycastModule.cast

local wsIndex = nil
for i, v in pairs(debug.getupvalues(castFn)) do
    if v == workspace then
        wsIndex = i
        break
    end
end

if wsIndex then
    local proxy = setmetatable({}, {
        __index = function(_, key)
            if key == "Raycast" then
                return function(_, origin, direction, params)
                    if silentAim then
                        local target = currentTarget
                        if target and target.Character then
                            local part = target.Character:FindFirstChild(TARGET_PART)
                                         or target.Character:FindFirstChild("HumanoidRootPart")
                            if part then
                                local spreadDelta = direction.Unit - Camera.CFrame.LookVector
                                local aimDir = (part.Position - origin).Unit
                                direction = (aimDir + spreadDelta).Unit * direction.Magnitude
                            end
                        end
                    end
                    return workspace:Raycast(origin, direction, params)
                end
            end
            return workspace[key]
        end,
        __newindex = function(_, key, value)
            workspace[key] = value
        end
    })

    debug.setupvalue(castFn, wsIndex, proxy)
end

local menu = loadstring(game:HttpGet("https://raw.githubusercontent.com/noxzyy/skeetui/refs/heads/main/lib.lua"))()

local win = menu:init({
    [1] = { icon = "rbxassetid://15453302474" },
    [2] = { icon = "rbxassetid://15453313321" },
    [3] = { icon = "rbxassetid://15453335745" },
    [4] = { icon = "rbxassetid://15453344494" },
    [5] = { icon = "rbxassetid://15453349637" },
    [6] = { icon = "rbxassetid://15453354931" },
    [7] = { icon = "rbxassetid://15453359751" },
    [8] = { icon = "rbxassetid://15453364412" },
})

local aimbot = win:getTab(1):newSection({
    name         = "Aimbot",
    is_changeable = true,
    scale        = 0.3,
})

aimbot:newToggle({
    name     = "Silent Aim",
    default  = false,
    callback = function(val)
        silentAim = val
        fovCircle.Visible   = val
        targetDot.Visible   = val and currentTarget ~= nil
        targetRing.Visible  = val and currentTarget ~= nil
    end,
})

RunService.RenderStepped:Connect(function()
    if not silentAim then
        targetDot.Visible  = false
        targetRing.Visible = false
        return
    end

    fovCircle.Position = Camera.ViewportSize / 2
    currentTarget = getTarget()

    if currentTarget and currentTarget.Character then
        local part = currentTarget.Character:FindFirstChild(TARGET_PART)
                     or currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local pos = Vector2.new(screenPos.X, screenPos.Y)
                targetDot.Position  = pos
                targetRing.Position = pos
                targetDot.Visible   = true
                targetRing.Visible  = true
            else
                targetDot.Visible  = false
                targetRing.Visible = false
            end
        end
    else
        targetDot.Visible  = false
        targetRing.Visible = false
    end
end)
