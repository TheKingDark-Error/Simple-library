-- SimpleLib Updated (fix/tab-colorpicker-update)
-- Focus: Fix tab visibility preserving, improved ColorPicker parsing (#RGB/#RRGGBB), Image/Img element, BackgroundId support, bigger notify close button (32px), added 4 themes, remove extra frames

local SimpleLib = {}
SimpleLib.Version = "3.1.1-fix"
SimpleLib.Theme = "Dark"
SimpleLib.Themes = {}

-- Basic services
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleLibV3_Updated"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Utility
local function New(Class, Props, Children)
    local obj = Instance.new(Class)
    for k,v in pairs(Props or {}) do obj[k] = v end
    for _,c in ipairs(Children or {}) do c.Parent = obj end
    return obj
end

local function Tween(obj, props, dur)
    dur = dur or 0.25
    local tw = TweenService:Create(obj, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

-- Theme registry and helper
local ThemeRegistry = {}
local function RegisterThemeObject(obj, prop, key)
    table.insert(ThemeRegistry, {Object = obj, Property = prop, Key = key})
end

function SimpleLib.ApplyTheme()
    local theme = SimpleLib.Themes[SimpleLib.Theme] or SimpleLib.Themes.Dark
    if not theme then return end
    for _,entry in ipairs(ThemeRegistry) do
        if entry.Object and entry.Object.Parent then
            pcall(function() entry.Object[entry.Property] = theme[entry.Key] end)
        end
    end
end

-- Built-in themes (old ones kept lightly; added 4 new)
SimpleLib.Themes.Dark = {
    Background = Color3.fromRGB(35,35,40), TextPrimary = Color3.fromRGB(255,255,255), Accent = Color3.fromRGB(50,200,100), NotifyBg = Color3.fromRGB(30,30,35), Stroke = Color3.fromRGB(60,60,70)
}
SimpleLib.Themes.Solar = { Background = Color3.fromRGB(40,28,18), TextPrimary = Color3.fromRGB(255,245,230), Accent = Color3.fromRGB(255,165,60), NotifyBg = Color3.fromRGB(48,34,28), Stroke = Color3.fromRGB(80,60,45)}
SimpleLib.Themes.Vapor = { Background = Color3.fromRGB(245,245,255), TextPrimary = Color3.fromRGB(30,30,40), Accent = Color3.fromRGB(120,160,220), NotifyBg = Color3.fromRGB(235,235,245), Stroke = Color3.fromRGB(200,200,215)}
SimpleLib.Themes.Orchid = { Background = Color3.fromRGB(34,22,40), TextPrimary = Color3.fromRGB(250,240,255), Accent = Color3.fromRGB(200,120,220), NotifyBg = Color3.fromRGB(48,34,50), Stroke = Color3.fromRGB(75,55,80)}
SimpleLib.Themes.Nightfall = { Background = Color3.fromRGB(12,14,18), TextPrimary = Color3.fromRGB(230,240,250), Accent = Color3.fromRGB(80,160,200), NotifyBg = Color3.fromRGB(18,20,24), Stroke = Color3.fromRGB(45,50,58)}

-- Aliases
local Aliases = { Image = "Image", Img = "Image" }

-- Simple window creation with BackgroundId support
function SimpleLib:CreateWindow(opts)
    opts = opts or {}
    local theme = SimpleLib.Themes[SimpleLib.Theme] or SimpleLib.Themes.Dark

    local Win = New("Frame", {
        Size = UDim2.new(0, 600, 0, 420),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = theme.MainPanel or theme.Background,
        BorderSizePixel = 0,
        ZIndex = 50,
    }, { New("UICorner", { CornerRadius = UDim.new(0, 12) }) })
    Win.Parent = ScreenGui
    RegisterThemeObject(Win, "BackgroundColor3", "MainPanel")

    -- BackgroundId support: create ImageLabel behind content
    if opts.BackgroundId then
        local id = tostring(opts.BackgroundId)
        -- if only numeric id, prepend rbxassetid://
        if tonumber(id) then id = "rbxassetid://" .. id end
        local ok, test = pcall(function()
            local img = New("ImageLabel", { Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Image = id, ZIndex = 0, })
            img.Parent = Win
            return img
        end)
        -- if failure, ignore and keep theme background
    end

    -- Topbar + body
    local Top = New("Frame", { Size = UDim2.new(1,0,0,48), BackgroundTransparency = 1, ZIndex = 51 })
    Top.Parent = Win
    local Title = New("TextLabel", { Text = opts.Title or "Window", TextColor3 = theme.TextPrimary, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Font = Enum.Font.GothamBold, TextSize = 22 })
    Title.Parent = Top
    RegisterThemeObject(Title, "TextColor3", "TextPrimary")

    -- Sidebar for tabs
    local Sidebar = New("Frame", { Size = UDim2.new(0,160,1,0), Position = UDim2.new(0,12,0,48), BackgroundColor3 = theme.Sidebar or theme.Background, BorderSizePixel = 0, ZIndex = 51 }, { New("UICorner", { CornerRadius = UDim.new(0,8) }) })
    Sidebar.Parent = Win
    RegisterThemeObject(Sidebar, "BackgroundColor3", "Sidebar")

    -- Content holder
    local ContentHolder = New("Frame", { Size = UDim2.new(1,-200,1,-60), Position = UDim2.new(0,180,0,54), BackgroundTransparency = 1, ZIndex = 52 })
    ContentHolder.Parent = Win

    -- Tab system: keep containers and toggle Visible, don't destroy
    local Tabs = {}
    function Win:CreateTab(name)
        local btn = New("TextButton", { Text = name, Size = UDim2.new(1,-12,0,40), BackgroundTransparency = 1, TextColor3 = theme.TextPrimary, Font = Enum.Font.Gotham, TextSize = 16 })
        btn.Parent = Sidebar
        RegisterThemeObject(btn, "TextColor3", "TextPrimary")

        local container = New("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false })
        container.Parent = ContentHolder

        table.insert(Tabs, {Name = name, Button = btn, Container = container})

        btn.MouseButton1Click:Connect(function()
            for _,t in ipairs(Tabs) do
                t.Container.Visible = (t.Name == name)
                -- style active
                if t.Name == name then
                    Tween(t.Button, {TextColor3 = (theme.Accent or Color3.fromRGB(255,255,255))}, 0.15)
                else
                    Tween(t.Button, {TextColor3 = (theme.TextPrimary or Color3.fromRGB(200,200,200))}, 0.15)
                end
            end
        end)

        -- if first tab, activate by default
        if #Tabs == 1 then
            btn:CaptureFocus()
            btn.MouseButton1Click:Wait() -- ensure button exists
            -- make visible
            container.Visible = true
            Tween(btn, {TextColor3 = (theme.Accent or Color3.fromRGB(255,255,255))}, 0.15)
        end

        return container
    end

    return Win
end

-- NOTIFICATION system (bigger close button)
local NotifyStacks = { TopRight = {} }
local NotifyWidth = 220
local function ShowNotification(data)
    data = data or {}
    local theme = SimpleLib.Themes[SimpleLib.Theme] or SimpleLib.Themes.Dark
    local frame = New("Frame", { Size = UDim2.new(0, NotifyWidth, 0, 70), BackgroundColor3 = theme.NotifyBg, Position = UDim2.new(1, -NotifyWidth - 12, 0, 12), ZIndex = 600}, { New("UICorner", { CornerRadius = UDim.new(0,10) }) })
    frame.Parent = ScreenGui
    RegisterThemeObject(frame, "BackgroundColor3", "NotifyBg")

    local title = New("TextLabel", { Text = data.title or "Notify", TextColor3 = theme.TextPrimary, BackgroundTransparency = 1, Size = UDim2.new(1,-48,0,30), Position = UDim2.new(0,12,0,8), Font = Enum.Font.GothamBold, TextSize = 14 })
    title.Parent = frame; RegisterThemeObject(title, "TextColor3", "TextPrimary")

    local content = New("TextLabel", { Text = data.content or "", TextColor3 = theme.TextPrimary, BackgroundTransparency = 1, Size = UDim2.new(1,-48,0,30), Position = UDim2.new(0,12,0,30), Font = Enum.Font.Gotham, TextSize = 12 })
    content.Parent = frame; RegisterThemeObject(content, "TextColor3", "TextPrimary")

    local closeBtn = New("TextButton", { Size = UDim2.new(0,32,0,32), Position = UDim2.new(1,-40,0,8), BackgroundTransparency = 1, Text = "×", Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = theme.TextPrimary })
    closeBtn.Parent = frame; RegisterThemeObject(closeBtn, "TextColor3", "TextPrimary")
    closeBtn.MouseButton1Click:Connect(function()
        Tween(frame, {BackgroundTransparency = 1, Position = frame.Position + UDim2.new(0,200,0,0)}, 0.25)
        task.delay(0.25, function() if frame.Destroy then frame:Destroy() end end)
    end)

    -- auto remove
    task.delay(data.duration or 5, function() if frame and frame.Parent then closeBtn:Destroy(); if frame.Destroy then frame:Destroy() end end)
end

-- COLOR PICKER: improved parsing & management
local ActiveColorPicker = nil

local function HexToRGB(hex)
    hex = tostring(hex or ""):gsub("#", "")
    if #hex == 3 then
        -- expand e.g. f0a -> ff00aa
        hex = hex:sub(1,1)..hex:sub(1,1)..hex:sub(2,2)..hex:sub(2,2)..hex:sub(3,3)..hex:sub(3,3)
    end
    if #hex ~= 6 then return 0,0,0 end
    local r = tonumber(hex:sub(1,2), 16) or 0
    local g = tonumber(hex:sub(3,4), 16) or 0
    local b = tonumber(hex:sub(5,6), 16) or 0
    r = math.clamp(r,0,255); g = math.clamp(g,0,255); b = math.clamp(b,0,255)
    return r,g,b
end

local function RGBToHex(r,g,b)
    r = math.clamp(math.floor(r or 0),0,255); g = math.clamp(math.floor(g or 0),0,255); b = math.clamp(math.floor(b or 0),0,255)
    return string.format("#%02X%02X%02X", r,g,b)
end

local function ShowColorPicker(opts, callback)
    opts = opts or {}
    if ActiveColorPicker then pcall(function() ActiveColorPicker:Destroy() end); ActiveColorPicker = nil end
    local theme = SimpleLib.Themes[SimpleLib.Theme] or SimpleLib.Themes.Dark
    local default = opts.Default or Color3.fromRGB(50,200,100)
    local r = math.floor(default.R*255); local g = math.floor(default.G*255); local b = math.floor(default.B*255)

    local Picker = New("Frame", { Size = UDim2.new(0,420,0,320), Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = theme.Background or theme.MainPanel, ZIndex = 900}, { New("UICorner", {CornerRadius = UDim.new(0,12)}) })
    Picker.Parent = ScreenGui
    RegisterThemeObject(Picker, "BackgroundColor3", "Background")

    local title = New("TextLabel", { Text = opts.Title or "Color Picker", Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1, TextColor3 = theme.TextPrimary, Font = Enum.Font.GothamBold, TextSize = 20, Position = UDim2.new(0,16,0,8) })
    title.Parent = Picker; RegisterThemeObject(title, "TextColor3", "TextPrimary")

    -- simple inputs: Hex box
    local hexBox = New("TextBox", { Size = UDim2.new(0,120,0,36), Position = UDim2.new(1,-140,0,12), Text = RGBToHex(r,g,b), Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = theme.TextPrimary, BackgroundColor3 = theme.Element or theme.MainPanel, ZIndex = 901 })
    hexBox.Parent = Picker; RegisterThemeObject(hexBox, "TextColor3", "TextPrimary")

    -- Apply / Cancel
    local applyBtn = New("TextButton", { Text = "Apply", Size = UDim2.new(0,120,0,44), Position = UDim2.new(1,-140,1,-56), BackgroundColor3 = theme.Accent or Color3.fromRGB(50,200,100), TextColor3 = theme.TextPrimary, Font = Enum.Font.GothamBold, TextSize = 18 })
    applyBtn.Parent = Picker

    local cancelBtn = New("TextButton", { Text = "Cancel", Size = UDim2.new(0,120,0,44), Position = UDim2.new(0,16,1,-56), BackgroundColor3 = theme.Section or theme.MainPanel, TextColor3 = theme.TextPrimary, Font = Enum.Font.GothamBold, TextSize = 18 })
    cancelBtn.Parent = Picker

    ActiveColorPicker = Picker

    -- events
    hexBox.FocusLost:Connect(function(enter)
        local text = hexBox.Text or ""
        local rr,gg,bb = HexToRGB(text)
        hexBox.Text = RGBToHex(rr,gg,bb)
        if callback then pcall(callback, Color3.fromRGB(rr,gg,bb)) end
    end)
    applyBtn.MouseButton1Click:Connect(function()
        local t = hexBox.Text or ""
        local rr,gg,bb = HexToRGB(t)
        if callback then pcall(callback, Color3.fromRGB(rr,gg,bb)) end
        if ActiveColorPicker and ActiveColorPicker.Destroy then ActiveColorPicker:Destroy() end; ActiveColorPicker = nil
    end)
    cancelBtn.MouseButton1Click:Connect(function()
        if ActiveColorPicker and ActiveColorPicker.Destroy then ActiveColorPicker:Destroy() end; ActiveColorPicker = nil
    end)

    return Picker
end

-- Image element helper for Tabs
function SimpleLib.CreateImageElement(parent, meta)
    meta = meta or {}
    local id = tostring(meta.Id or "")
    if tonumber(id) then id = "rbxassetid://"..id end
    local img = New("ImageLabel", { Size = UDim2.new(0, 200, 0, 120), BackgroundTransparency = 1, Image = id })
    img.Parent = parent
    return img
end

-- expose functions
SimpleLib.ShowNotification = ShowNotification
SimpleLib.ShowColorPicker = ShowColorPicker
SimpleLib.CreateImageElement = SimpleLib.CreateImageElement
SimpleLib.New = New

return SimpleLib
