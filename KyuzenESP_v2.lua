-- LocalScript in StarterPlayerScripts
-- KYUZEN ESP v2.1 - NPC & Breakable Highlighter for Absolvement

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================
--   CONFIG
-- =====================
local npcColor   = Color3.fromRGB(255, 75, 75)
local breakColor = Color3.fromRGB(255, 185, 0)

local npcCount    = 0
local breakCount  = 0
local highlighted = {}
local npcVisible  = true
local breakVisible = true
local isScanning  = false
local panelOpen   = true

-- =====================
--   CORE LOGIC
-- =====================
local function removeHighlight(obj)
	local h = obj:FindFirstChild("_KHighlight")
	if h then h:Destroy() end
end

local function highlightObject(obj, color, fill)
	removeHighlight(obj)
	local h = Instance.new("Highlight")
	h.Name = "_KHighlight"
	h.Adornee = obj
	h.OutlineColor = color
	h.FillColor = color
	h.FillTransparency = fill or 0.55
	h.OutlineTransparency = 0
	h.Parent = obj
end

local function isNPC(obj)
	if not obj:IsA("Model") then return false end
	if not obj:FindFirstChildOfClass("Humanoid") then return false end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character == obj then return false end
	end
	return true
end

local function isBreakable(obj)
	local name = obj.Name:lower()
	local keywords = {
		"breakable","barrel","crate","box","vase","pot","chest",
		"wood","plank","glass","destructible","smash","shatter",
		"prop","debris","boulder","wall"
	}
	for _, k in ipairs(keywords) do
		if name:find(k) then return true end
	end
	if obj:FindFirstChild("Breakable") or obj:FindFirstChild("IsBreakable") then return true end
	if CollectionService:HasTag(obj,"Breakable") or CollectionService:HasTag(obj,"breakable") then return true end
	return false
end

local function clearAll()
	for _, entry in ipairs(highlighted) do removeHighlight(entry.obj) end
	highlighted = {}
	npcCount = 0
	breakCount = 0
end

local function scanWorkspace()
	clearAll()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if isNPC(obj) then
			highlightObject(obj, npcColor, 0.5)
			npcCount += 1
			table.insert(highlighted, {obj=obj, kind="npc"})
		elseif isBreakable(obj) then
			highlightObject(obj, breakColor, 0.6)
			breakCount += 1
			table.insert(highlighted, {obj=obj, kind="break"})
		end
	end
end

local function applyVisibility()
	for _, entry in ipairs(highlighted) do
		local h = entry.obj:FindFirstChild("_KHighlight")
		if h then
			h.Enabled = (entry.kind == "npc") and npcVisible or breakVisible
		end
	end
end

-- Live-recolor existing highlights without re-scanning
local function recolorHighlights(kind, color)
	for _, entry in ipairs(highlighted) do
		if entry.kind == kind then
			local h = entry.obj:FindFirstChild("_KHighlight")
			if h then
				h.OutlineColor = color
				h.FillColor = color
			end
		end
	end
end

-- =====================
--   GUI SETUP
-- =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KyuzenESP"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- =====================
--   MAIN PANEL
-- =====================
local PANEL_W = 260
local PANEL_H = 390

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position = UDim2.new(0, 50, 0.5, -(PANEL_H/2))
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local glow = Instance.new("UIStroke")
glow.Color = Color3.fromRGB(90, 60, 130)
glow.Thickness = 1.5
glow.Parent = panel

local bg = Instance.new("UIGradient")
bg.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 14, 28)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 12)),
})
bg.Rotation = 135
bg.Parent = panel

-- Accent bar
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.BorderSizePixel = 0
accentLine.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
accentLine.Parent = panel
local accentGrad = Instance.new("UIGradient")
accentGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 75, 75)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 80, 255)),
	ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 185, 0)),
})
accentGrad.Parent = accentLine

-- =====================
--   HEADER
-- =====================
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 46)
header.Position = UDim2.new(0, 0, 0, 2)
header.BackgroundTransparency = 1
header.Parent = panel

local function makeDot(x, col)
	local d = Instance.new("Frame")
	d.Size = UDim2.new(0, 8, 0, 8)
	d.Position = UDim2.new(0, x, 0.5, -4)
	d.BackgroundColor3 = col
	d.BorderSizePixel = 0
	d.Parent = header
	Instance.new("UICorner").Parent = d
	return d
end
makeDot(14, Color3.fromRGB(255, 75, 75))
makeDot(26, Color3.fromRGB(160, 80, 255))
makeDot(38, Color3.fromRGB(255, 185, 0))

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 56, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "KYUZEN  ESP"
titleLabel.TextColor3 = Color3.fromRGB(235, 235, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 46, 0, 14)
versionLabel.Position = UDim2.new(1, -54, 0.5, -7)
versionLabel.BackgroundColor3 = Color3.fromRGB(100, 50, 180)
versionLabel.BorderSizePixel = 0
versionLabel.Text = "v2.1"
versionLabel.TextColor3 = Color3.fromRGB(210, 180, 255)
versionLabel.TextSize = 9
versionLabel.Font = Enum.Font.GothamBold
versionLabel.Parent = header
Instance.new("UICorner").Parent = versionLabel

local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -28, 0, 1)
sep.Position = UDim2.new(0, 14, 0, 48)
sep.BackgroundColor3 = Color3.fromRGB(45, 35, 65)
sep.BorderSizePixel = 0
sep.Parent = panel

-- =====================
--   STATS ROW
-- =====================
local statsRow = Instance.new("Frame")
statsRow.Size = UDim2.new(1, -24, 0, 60)
statsRow.Position = UDim2.new(0, 12, 0, 58)
statsRow.BackgroundColor3 = Color3.fromRGB(18, 14, 26)
statsRow.BorderSizePixel = 0
statsRow.Parent = panel
local sc = Instance.new("UICorner")
sc.CornerRadius = UDim.new(0, 8)
sc.Parent = statsRow
local ss = Instance.new("UIStroke")
ss.Color = Color3.fromRGB(50, 35, 75)
ss.Thickness = 1
ss.Parent = statsRow

local function makeStatCard(side, label, color)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0.5, -1, 1, 0)
	card.Position = side == "left" and UDim2.new(0,0,0,0) or UDim2.new(0.5,1,0,0)
	card.BackgroundTransparency = 1
	card.Parent = statsRow

	local num = Instance.new("TextLabel")
	num.Name = "Count"
	num.Size = UDim2.new(1, 0, 0, 28)
	num.Position = UDim2.new(0, 0, 0, 6)
	num.BackgroundTransparency = 1
	num.Text = "0"
	num.TextColor3 = color
	num.TextSize = 22
	num.Font = Enum.Font.GothamBold
	num.Parent = card

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 14)
	lbl.Position = UDim2.new(0, 0, 0, 34)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(130, 120, 150)
	lbl.TextSize = 9
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = card

	return num
end

local npcCountLabel   = makeStatCard("left",  "NPC ENTITIES", Color3.fromRGB(255, 100, 100))
local breakCountLabel = makeStatCard("right", "BREAKABLES",   Color3.fromRGB(255, 195, 50))

local midDiv = Instance.new("Frame")
midDiv.Size = UDim2.new(0, 1, 0.6, 0)
midDiv.Position = UDim2.new(0.5, 0, 0.2, 0)
midDiv.BackgroundColor3 = Color3.fromRGB(50, 35, 75)
midDiv.BorderSizePixel = 0
midDiv.Parent = statsRow

local function updateStats()
	npcCountLabel.Text = tostring(npcCount)
	breakCountLabel.Text = tostring(breakCount)
end

-- =====================
--   BUTTON FACTORY
-- =====================
local BTN_H   = 36
local BTN_GAP = 7
local BTN_Y   = 130

local function makeButton(icon, text, yOff, baseColor, glowColor, textColor)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -24, 0, BTN_H)
	btn.Position = UDim2.new(0, 12, 0, yOff)
	btn.BackgroundColor3 = baseColor
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = panel
	Instance.new("UICorner").Parent = btn
	local bs = Instance.new("UIStroke")
	bs.Color = glowColor
	bs.Thickness = 1
	bs.Transparency = 0.5
	bs.Parent = btn

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(0, 28, 1, 0)
	iconLbl.Position = UDim2.new(0, 8, 0, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = icon
	iconLbl.TextColor3 = textColor
	iconLbl.TextSize = 14
	iconLbl.Font = Enum.Font.GothamBold
	iconLbl.Parent = btn

	local textLbl = Instance.new("TextLabel")
	textLbl.Name = "Label"
	textLbl.Size = UDim2.new(1, -44, 1, 0)
	textLbl.Position = UDim2.new(0, 36, 0, 0)
	textLbl.BackgroundTransparency = 1
	textLbl.Text = text
	textLbl.TextColor3 = textColor
	textLbl.TextSize = 11
	textLbl.Font = Enum.Font.GothamBold
	textLbl.TextXAlignment = Enum.TextXAlignment.Left
	textLbl.Parent = btn

	local tweenIn  = TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = glowColor:Lerp(baseColor, 0.4)})
	local tweenOut = TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = baseColor})
	btn.MouseEnter:Connect(function() tweenIn:Play() end)
	btn.MouseLeave:Connect(function() tweenOut:Play() end)

	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.06), {Size = UDim2.new(1,-28,0,BTN_H-2), Position = UDim2.new(0,14,0,yOff+1)}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.10), {Size = UDim2.new(1,-24,0,BTN_H), Position = UDim2.new(0,12,0,yOff)}):Play()
	end)

	return btn, textLbl, bs
end

local y1 = BTN_Y
local y2 = y1 + BTN_H + BTN_GAP
local y3 = y2 + BTN_H + BTN_GAP
local y4 = y3 + BTN_H + BTN_GAP

local scanBtn,  scanLbl  = makeButton("▶", "SCAN WORKSPACE",    y1, Color3.fromRGB(30,60,35),  Color3.fromRGB(80,220,100),  Color3.fromRGB(140,255,160))
local npcBtn,   npcLbl   = makeButton("◉", "NPC HIGHLIGHT: ON", y2, Color3.fromRGB(50,20,20),  Color3.fromRGB(255,75,75),   Color3.fromRGB(255,120,120))
local breakBtn, breakLbl = makeButton("◈", "BREAKABLES: ON",    y3, Color3.fromRGB(50,38,10),  Color3.fromRGB(255,185,0),   Color3.fromRGB(255,205,80))
local clearBtn, clearLbl = makeButton("✕", "CLEAR ALL",         y4, Color3.fromRGB(22,18,32),  Color3.fromRGB(100,80,140),  Color3.fromRGB(160,145,185))

-- =====================
--   COLOR SWATCHES
--   Small clickable square on the right of NPC & Break buttons
-- =====================
local function makeSwatch(parentBtn, initColor)
	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.Size = UDim2.new(0, 20, 0, 20)
	swatch.Position = UDim2.new(1, -28, 0.5, -10)
	swatch.BackgroundColor3 = initColor
	swatch.BorderSizePixel = 0
	swatch.ZIndex = 5
	swatch.Parent = parentBtn
	Instance.new("UICorner").Parent = swatch
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(255, 255, 255)
	st.Transparency = 0.65
	st.Thickness = 1
	st.Parent = swatch

	local swatchBtn = Instance.new("TextButton")
	swatchBtn.Size = UDim2.new(1, 0, 1, 0)
	swatchBtn.BackgroundTransparency = 1
	swatchBtn.Text = ""
	swatchBtn.ZIndex = 6
	swatchBtn.Parent = swatch

	return swatch, swatchBtn
end

local npcSwatch,   npcSwatchBtn   = makeSwatch(npcBtn,   npcColor)
local breakSwatch, breakSwatchBtn = makeSwatch(breakBtn, breakColor)

-- =====================
--   COLOR PICKER PANEL
-- =====================
local PICKER_H   = 118
local pickerOpen = false
local pickerTarget = nil  -- "npc" or "break"

local pickerY = y4 + BTN_H + BTN_GAP

local picker = Instance.new("Frame")
picker.Name = "ColorPicker"
picker.Size = UDim2.new(1, -24, 0, 0)  -- starts collapsed
picker.Position = UDim2.new(0, 12, 0, pickerY)
picker.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
picker.BorderSizePixel = 0
picker.ClipsDescendants = true
picker.Parent = panel
Instance.new("UICorner").Parent = picker
local pickerStroke = Instance.new("UIStroke")
pickerStroke.Color = Color3.fromRGB(80, 55, 120)
pickerStroke.Thickness = 1
pickerStroke.Parent = picker

-- Picker header row
local pickerTitle = Instance.new("TextLabel")
pickerTitle.Size = UDim2.new(1, -38, 0, 18)
pickerTitle.Position = UDim2.new(0, 8, 0, 6)
pickerTitle.BackgroundTransparency = 1
pickerTitle.Text = "NPC COLOR"
pickerTitle.TextColor3 = Color3.fromRGB(180, 150, 220)
pickerTitle.TextSize = 9
pickerTitle.Font = Enum.Font.GothamBold
pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
pickerTitle.Parent = picker

-- Live preview swatch
local pickerPreview = Instance.new("Frame")
pickerPreview.Size = UDim2.new(0, 20, 0, 20)
pickerPreview.Position = UDim2.new(1, -28, 0, 5)
pickerPreview.BackgroundColor3 = npcColor
pickerPreview.BorderSizePixel = 0
pickerPreview.Parent = picker
Instance.new("UICorner").Parent = pickerPreview
local pvStroke = Instance.new("UIStroke")
pvStroke.Color = Color3.fromRGB(255,255,255)
pvStroke.Transparency = 0.65
pvStroke.Thickness = 1
pvStroke.Parent = pickerPreview

-- =====================
--   RGB SLIDERS
-- =====================
local sliderRGB = {r = 255, g = 75, b = 75}

local function makeSlider(label, trackColor, yPos)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 14, 0, 14)
	lbl.Position = UDim2.new(0, 8, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(170, 150, 200)
	lbl.TextSize = 9
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = picker

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -60, 0, 6)
	track.Position = UDim2.new(0, 24, 0, yPos + 4)
	track.BackgroundColor3 = Color3.fromRGB(35, 28, 50)
	track.BorderSizePixel = 0
	track.Parent = picker
	Instance.new("UICorner").Parent = track

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = trackColor
	fill.BorderSizePixel = 0
	fill.Parent = track
	Instance.new("UICorner").Parent = fill

	local handle = Instance.new("TextButton")
	handle.Size = UDim2.new(0, 12, 0, 12)
	handle.Position = UDim2.new(1, -6, 0.5, -6)
	handle.BackgroundColor3 = Color3.fromRGB(240, 228, 255)
	handle.BorderSizePixel = 0
	handle.Text = ""
	handle.AutoButtonColor = false
	handle.ZIndex = 4
	handle.Parent = track
	Instance.new("UICorner").Parent = handle

	local valLbl = Instance.new("TextLabel")
	valLbl.Size = UDim2.new(0, 26, 0, 14)
	valLbl.Position = UDim2.new(1, -30, 0, yPos + 1)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = "255"
	valLbl.TextColor3 = Color3.fromRGB(200, 185, 225)
	valLbl.TextSize = 9
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = picker

	return track, fill, handle, valLbl
end

local rTrack, rFill, rHandle, rVal = makeSlider("R", Color3.fromRGB(220, 55, 55),  30)
local gTrack, gFill, gHandle, gVal = makeSlider("G", Color3.fromRGB(55, 200, 55),  52)
local bTrack, bFill, bHandle, bVal = makeSlider("B", Color3.fromRGB(55, 100, 220), 74)

-- =====================
--   SLIDER INTERACTION
-- =====================
local function setSlider(track, fill, handle, valLbl, pct)
	pct = math.clamp(pct, 0, 1)
	fill.Size = UDim2.new(pct, 0, 1, 0)
	handle.Position = UDim2.new(pct, -6, 0.5, -6)
	local val = math.round(pct * 255)
	valLbl.Text = tostring(val)
	return val
end

local function getPct(track, inputX)
	return (inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X
end

local function onColorChanged()
	local col = Color3.fromRGB(sliderRGB.r, sliderRGB.g, sliderRGB.b)
	pickerPreview.BackgroundColor3 = col
	if pickerTarget == "npc" then
		npcColor = col
		npcSwatch.BackgroundColor3 = col
		recolorHighlights("npc", col)
	else
		breakColor = col
		breakSwatch.BackgroundColor3 = col
		recolorHighlights("break", col)
	end
end

local function bindSlider(track, fill, handle, valLbl, channel)
	local active = false

	handle.MouseButton1Down:Connect(function() active = true end)

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			active = true
			local val = setSlider(track, fill, handle, valLbl, getPct(track, input.Position.X))
			sliderRGB[channel] = val
			onColorChanged()
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if active and input.UserInputType == Enum.UserInputType.MouseMovement then
			local val = setSlider(track, fill, handle, valLbl, getPct(track, input.Position.X))
			sliderRGB[channel] = val
			onColorChanged()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			active = false
		end
	end)
end

bindSlider(rTrack, rFill, rHandle, rVal, "r")
bindSlider(gTrack, gFill, gHandle, gVal, "g")
bindSlider(bTrack, bFill, bHandle, bVal, "b")

-- Sync sliders visually to a given Color3
local function syncSliders(col)
	local r = math.round(col.R * 255)
	local g = math.round(col.G * 255)
	local b = math.round(col.B * 255)
	sliderRGB.r, sliderRGB.g, sliderRGB.b = r, g, b
	setSlider(rTrack, rFill, rHandle, rVal, r / 255)
	setSlider(gTrack, gFill, gHandle, gVal, g / 255)
	setSlider(bTrack, bFill, bHandle, bVal, b / 255)
	pickerPreview.BackgroundColor3 = col
end

-- =====================
--   OPEN / CLOSE PICKER
-- =====================
local pickerTween = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function openPicker(target)
	pickerTarget = target
	if target == "npc" then
		pickerTitle.Text = "NPC COLOR"
		pickerStroke.Color = Color3.fromRGB(200, 60, 60)
		syncSliders(npcColor)
	else
		pickerTitle.Text = "BREAKABLE COLOR"
		pickerStroke.Color = Color3.fromRGB(200, 150, 20)
		syncSliders(breakColor)
	end
	pickerOpen = true
	TweenService:Create(picker, pickerTween, {Size = UDim2.new(1, -24, 0, PICKER_H)}):Play()
end

local function closePicker()
	pickerOpen = false
	TweenService:Create(picker, pickerTween, {Size = UDim2.new(1, -24, 0, 0)}):Play()
end

npcSwatchBtn.MouseButton1Click:Connect(function()
	if pickerOpen and pickerTarget == "npc" then closePicker()
	else openPicker("npc") end
end)

breakSwatchBtn.MouseButton1Click:Connect(function()
	if pickerOpen and pickerTarget == "break" then closePicker()
	else openPicker("break") end
end)

-- =====================
--   HOTKEY HINT
-- =====================
local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, 0, 0, 14)
hintLabel.Position = UDim2.new(0, 0, 1, -16)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "[H] TOGGLE PANEL"
hintLabel.TextColor3 = Color3.fromRGB(70, 60, 90)
hintLabel.TextSize = 9
hintLabel.Font = Enum.Font.GothamBold
hintLabel.Parent = panel

-- =====================
--   COLLAPSE TAB
-- =====================
local collapseTab = Instance.new("TextButton")
collapseTab.Size = UDim2.new(0, 32, 0, 64)
collapseTab.BackgroundColor3 = Color3.fromRGB(16, 12, 22)
collapseTab.BorderSizePixel = 0
collapseTab.Text = ""
collapseTab.ZIndex = 20
collapseTab.Parent = screenGui
Instance.new("UICorner").Parent = collapseTab
local tabStroke = Instance.new("UIStroke")
tabStroke.Color = Color3.fromRGB(90, 60, 130)
tabStroke.Thickness = 1
tabStroke.Parent = collapseTab

local tabGrad = Instance.new("UIGradient")
tabGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 15, 35)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 8, 16)),
})
tabGrad.Rotation = 90
tabGrad.Parent = collapseTab

local tabIcon = Instance.new("TextLabel")
tabIcon.Size = UDim2.new(1, 0, 1, 0)
tabIcon.BackgroundTransparency = 1
tabIcon.Text = "◀"
tabIcon.TextColor3 = Color3.fromRGB(160, 120, 220)
tabIcon.TextSize = 12
tabIcon.Font = Enum.Font.GothamBold
tabIcon.Parent = collapseTab

local function positionTab()
	local px = panel.Position.X.Offset
	local py = panel.Position.Y.Offset
	local pw = panelOpen and PANEL_W or 0
	collapseTab.Position = UDim2.new(0, px + pw - 1, 0, py + PANEL_H/2 - 32)
end

-- =====================
--   DRAG LOGIC
-- =====================
local dragging = false
local dragStart, startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	local vp = workspace.CurrentCamera.ViewportSize
	local newX = math.clamp(startPos.X.Offset + delta.X, 0, vp.X - PANEL_W)
	local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - PANEL_H)
	panel.Position = UDim2.new(0, newX, 0, newY)
	positionTab()
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = panel.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
	                 input.UserInputType == Enum.UserInputType.Touch) then
		updateDrag(input)
	end
end)

-- =====================
--   BUTTON LOGIC
-- =====================
syncSliders(npcColor)  -- init sliders to default NPC color

scanBtn.MouseButton1Click:Connect(function()
	if isScanning then return end
	isScanning = true
	local dots = 0
	local dotConn
	dotConn = RunService.Heartbeat:Connect(function()
		dots = (dots + 1) % 4
		scanLbl.Text = "SCANNING" .. string.rep(".", dots)
	end)
	task.wait(0.05)
	scanWorkspace()
	updateStats()
	dotConn:Disconnect()
	scanLbl.Text = "SCAN WORKSPACE"
	isScanning = false
end)

npcBtn.MouseButton1Click:Connect(function()
	npcVisible = not npcVisible
	npcLbl.Text = npcVisible and "NPC HIGHLIGHT: ON" or "NPC HIGHLIGHT: OFF"
	npcBtn.BackgroundColor3 = npcVisible and Color3.fromRGB(50,20,20) or Color3.fromRGB(22,18,32)
	applyVisibility()
end)

breakBtn.MouseButton1Click:Connect(function()
	breakVisible = not breakVisible
	breakLbl.Text = breakVisible and "BREAKABLES: ON" or "BREAKABLES: OFF"
	breakBtn.BackgroundColor3 = breakVisible and Color3.fromRGB(50,38,10) or Color3.fromRGB(22,18,32)
	applyVisibility()
end)

clearBtn.MouseButton1Click:Connect(function()
	clearAll()
	updateStats()
	npcVisible = true
	breakVisible = true
	npcLbl.Text = "NPC HIGHLIGHT: ON"
	npcBtn.BackgroundColor3 = Color3.fromRGB(50,20,20)
	breakLbl.Text = "BREAKABLES: ON"
	breakBtn.BackgroundColor3 = Color3.fromRGB(50,38,10)
	if pickerOpen then closePicker() end
end)

-- =====================
--   TOGGLE PANEL
-- =====================
local tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function togglePanel()
	panelOpen = not panelOpen
	local targetW = panelOpen and PANEL_W or 0
	TweenService:Create(panel, tweenInfo, {Size = UDim2.new(0, targetW, 0, PANEL_H)}):Play()
	tabIcon.Text = panelOpen and "◀" or "▶"
	task.wait(0.22)
	positionTab()
end

collapseTab.MouseButton1Click:Connect(togglePanel)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.H then togglePanel() end
end)

positionTab()
