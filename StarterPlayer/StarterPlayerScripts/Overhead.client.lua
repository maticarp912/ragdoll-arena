-- LocalScript: StarterPlayer/StarterPlayerScripts/Overhead
-- Sobre cada luchador (jugadores y muñecos; tú no, tus barras están abajo): nombre, Vida (roja), Stun (ámbar) y Guardia (azul, fina),
-- icono de aviso (fuerte/imbloqueable) e indicadores en el arma:
--   Fuerte       -> punto rojo en la punta del arma + anillo que se cierra + rombo "!" (etapa 8: sin teñir el arma)
--   Imbloqueable -> punto incandescente que late + doble anillo dorado + rombo "!!"
--   Guardia      -> contorno acero en el arma
-- Además: contorno tenue con el color del equipo, y brillo pálido mientras duran los i-frames de la esquiva.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local N = Theme.Metrics
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local Infusions = require(ReplicatedStorage:WaitForChild("Infusions"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local PolishConfig = require(ReplicatedStorage:WaitForChild("PolishConfig"))
local RunService = game:GetService("RunService")
local TG = PolishConfig.Telegraph

local C = Theme.Colors
local STUN_MAX = CombatConfig.Stun.Max
local DUMMY_MODES = {
	Idle = "Quieto", Block = "Bloquea", Parry = "Parrea", Dodge = "Esquiva",
	Attack = "Ataca", Heavy = "Fuertes", Mixed = "Mixto",
}

local attached = {} -- [model] = { conns = {}, gui = BillboardGui, ... }

----------------------------------------------------------------------
-- 0.2 (C18): etiqueta de rol antes del nombre. El rol es el atributo Role del jugador (lo pone RoleService de
-- Codex); el color sale de ReplicatedStorage.Roles (Codex). Si Roles todavía no existe o cambia de forma, se usa
-- PolishConfig.Roles como respaldo, así esto no se rompe mientras se integra.
----------------------------------------------------------------------
local RolesModule = nil
local function rolesData()
	if RolesModule ~= nil then return RolesModule or nil end
	local m = ReplicatedStorage:FindFirstChild("Roles")
	if not m then return nil end -- se vuelve a buscar la próxima vez
	local ok, data = pcall(require, m)
	RolesModule = ok and type(data) == "table" and data or false
	return RolesModule or nil
end

local function asColor(v)
	if typeof(v) == "Color3" then return v end
	if typeof(v) == "BrickColor" then return v.Color end
	if type(v) == "string" and string.match(v, "^#?%x%x%x%x%x%x$") then
		local ok, c = pcall(Color3.fromHex, v)
		if ok then return c end
	end
	return nil
end

local function roleColor(role)
	local R = rolesData()
	if R then
		if type(R.color) == "function" then
			local ok, c = pcall(R.color, role)
			if ok and asColor(c) then return asColor(c) end
		end
		for _, field in { "Colors", "Data", "Info", "Roles", "List" } do
			local t = R[field]
			local entry = type(t) == "table" and t[role]
			local c = asColor(entry) or (type(entry) == "table" and (asColor(entry.color) or asColor(entry.Color)))
			if c then return c end
		end
		local entry = R[role]
		local c = type(entry) == "table" and (asColor(entry.color) or asColor(entry.Color))
		if c then return c end
	end
	local fallback = PolishConfig.Roles and PolishConfig.Roles.Colors
	return fallback and fallback[role] or C.Gold
end

local function roleText(role)
	local key = "overhead.role." .. role
	local text = L.t(key)
	return text ~= key and text or role
end

local HIDDEN_ROLES = { [""] = true, Player = true, Member = true, None = true, Jugador = true }

local function escapeRich(text)
	return (string.gsub(string.gsub(string.gsub(text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
end

local function bar(parent, y, height, color)
	local bg = Instance.new("Frame")
	bg.Position = UDim2.fromOffset(N.Zero, y)
	bg.Size = UDim2.new(N.One, N.Zero, N.Zero, height)
	bg.BackgroundColor3 = C.BarBack
	bg.BackgroundTransparency = N.Value_0_15
	bg.BorderSizePixel = N.Zero
	bg.Parent = parent
	Theme.stroke(bg, C.Gold, N.One, N.Value_0_6)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(N.One, N.One)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = N.Zero
	fill.Parent = bg
	return fill, bg
end

local function teamColorOf(model)
	local p = Players:GetPlayerFromCharacter(model)
	if p and p.Team then
		return Theme.Teams[p.Team.Name] or p.TeamColor.Color
	end
	return nil
end

local function detach(model)
	local a = attached[model]
	if not a then return end
	attached[model] = nil
	for _, c in a.conns do c:Disconnect() end
	for _, inst in a.instances do
		if inst.Parent then inst:Destroy() end
	end
end

local function attach(model)
	if attached[model] then return end
	local head = model:WaitForChild("Head", N.Value_5)
	local hum = model:WaitForChild("Humanoid", N.Value_5)
	if not head or not hum or attached[model] or not model.Parent then return end

	local a = { conns = {}, instances = {} }
	attached[model] = a
	local function on(signal, fn)
		table.insert(a.conns, signal:Connect(fn))
	end

	-- Panel sobre la cabeza
	local gui = Instance.new("BillboardGui")
	gui.Name = "Overhead"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(N.Value_124, N.Value_70)
	gui.StudsOffset = Vector3.new(N.Zero, N.Value_3_4, N.Zero)
	-- En la ciudad las barras no se ven a través de los edificios y solo de cerca;
	-- en partida se ven siempre (por encima de todo)
	local function depth()
		local inMatch = Players.LocalPlayer:GetAttribute("InMatch") == true
		gui.AlwaysOnTop = inMatch
		gui.MaxDistance = inMatch and N.Value_160 or Theme.Lobby.OverheadDistance
	end
	depth()
	on(Players.LocalPlayer:GetAttributeChangedSignal("InMatch"), depth)
	gui.Parent = head
	table.insert(a.instances, gui)

	-- Icono de aviso (rombo) encima del nombre
	local warnHolder = Instance.new("Frame")
	warnHolder.AnchorPoint = Vector2.new(N.Half, N.Zero)
	warnHolder.Position = UDim2.new(N.Half, N.Zero, N.Zero, N.Zero)
	warnHolder.Size = UDim2.fromOffset(N.Value_22, N.Value_22)
	warnHolder.BackgroundTransparency = N.One
	warnHolder.Visible = false
	warnHolder.Parent = gui

	local diamond = Instance.new("Frame")
	diamond.AnchorPoint = Vector2.new(N.Half, N.Half)
	diamond.Position = UDim2.fromScale(N.Half, N.Half)
	diamond.Size = UDim2.fromOffset(N.Value_15, N.Value_15)
	diamond.Rotation = N.Value_45
	diamond.BorderSizePixel = N.Zero
	diamond.Parent = warnHolder
	local diamondStroke = Theme.stroke(diamond, C.Charcoal, N.Two, N.Zero)

	local warnText = Instance.new("TextLabel")
	warnText.Size = UDim2.fromScale(N.One, N.One)
	warnText.BackgroundTransparency = N.One
	warnText.Font = Theme.Fonts.Number
	warnText.TextSize = N.Value_13
	warnText.TextColor3 = C.Charcoal
	warnText.ZIndex = N.Two
	warnText.Parent = warnHolder

	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromOffset(N.Zero, N.Value_22)
	name.Size = UDim2.new(N.One, N.Zero, N.Zero, N.Value_16)
	name.BackgroundTransparency = N.One
	name.Font = Theme.Fonts.Title
	name.TextSize = N.Value_15
	name.TextStrokeTransparency = N.Value_0_35
	name.TextColor3 = C.Bone
	name.Parent = gui

	local hpFill = bar(gui, N.Value_40, N.Value_8, C.Health)
	local stunFill = bar(gui, N.Value_50, N.Value_5, C.Stun)
	local guardFill = bar(gui, N.Value_57, N.Three, C.Guard)

	-- Fila de estados (quemadura, sangrado...) para la Fase C
	local statusRow = Instance.new("Frame")
	statusRow.Name = "StatusRow"
	statusRow.Position = UDim2.fromOffset(N.Zero, N.Value_62)
	statusRow.Size = UDim2.new(N.One, N.Zero, N.Zero, N.Value_8)
	statusRow.BackgroundTransparency = N.One
	statusRow.Parent = gui

	local infusion = Instance.new("TextLabel")
 infusion.Size = UDim2.fromScale(N.One,N.One) infusion.BackgroundTransparency = N.One infusion.Font = Theme.Fonts.Number
 infusion.TextSize = Theme.Sizes.TextSmall infusion.TextStrokeTransparency = N.Value_0_35 infusion.Parent = statusRow
 local function updateInfusion()
  local def = Infusions.get(model:GetAttribute("InfusionId"))
  infusion.Text = def and (L.t("infusion." .. (model:GetAttribute("InfusionId") or "Fire")) .. (model:GetAttribute("InfusionActive") and " *" or "")) or ""
  infusion.TextColor3 = def and def.color or C.BoneDim
 end
 on(model:GetAttributeChangedSignal("InfusionId"), updateInfusion)
 on(model:GetAttributeChangedSignal("InfusionActive"), updateInfusion)
 updateInfusion()
 local player = Players:GetPlayerFromCharacter(model)
	-- Tu propia barra no va sobre tu cabeza: está abajo en la pantalla (HUD)
	gui.Enabled = player ~= Players.LocalPlayer

	local function updateName()
		if model:GetAttribute("IsDummy") then
			name.RichText = false
			name.Text = L.t("dummy", { mode = L.t("dummy." .. (workspace:GetAttribute("DummyMode") or "Idle")) })
			name.TextColor3 = C.BoneDim
		else
			local display = player and player.DisplayName or model.Name
			if player and player:GetAttribute("Pass_VIP") == true then display = "♛ " .. display end
			local role = player and player:GetAttribute("Role")
			if type(role) == "string" and not HIDDEN_ROLES[role] then
				-- [ROL] Nombre: el rol con su color, el nombre con el del equipo
				name.RichText = true
				name.Text = ('<font color="#%s">[%s]</font> %s'):format(roleColor(role):ToHex(),
					escapeRich(string.upper(roleText(role))), escapeRich(display))
			else
				name.RichText = false
				name.Text = display
			end
			name.TextColor3 = teamColorOf(model) or C.Bone
		end
	end
	updateName()
	if player then
		on(player:GetPropertyChangedSignal("Team"), updateName)
		on(player:GetAttributeChangedSignal("Role"), updateName)
		on(player:GetAttributeChangedSignal("Pass_VIP"), updateName)
	end
	if model:GetAttribute("IsDummy") then on(workspace:GetAttributeChangedSignal("DummyMode"), updateName) end

	local function updateHealth()
		hpFill.Size = UDim2.fromScale(math.clamp(hum.Health / math.max(hum.MaxHealth, N.One), N.Zero, N.One), N.One)
	end
	on(hum.HealthChanged, updateHealth)
	on(hum:GetPropertyChangedSignal("MaxHealth"), updateHealth)
	updateHealth()

	local function updateStun()
		local s = model:GetAttribute("Stun") or N.Zero
		stunFill.Size = UDim2.fromScale(math.clamp(s / STUN_MAX, N.Zero, N.One), N.One)
		stunFill.BackgroundColor3 = s >= STUN_MAX * N.Value_0_75 and C.TelegraphHeavy or C.Stun
	end
	on(model:GetAttributeChangedSignal("Stun"), updateStun)
	updateStun()

	local function updateGuard()
		local gmax = model:GetAttribute("GuardMax") or N.Value_100
		local g = model:GetAttribute("Guard") or gmax
		guardFill.Size = UDim2.fromScale(math.clamp(g / gmax, N.Zero, N.One), N.One)
		guardFill.BackgroundColor3 = model:GetAttribute("GuardBroken") and C.Disabled or C.Guard
	end
	on(model:GetAttributeChangedSignal("Guard"), updateGuard)
	on(model:GetAttributeChangedSignal("GuardMax"), updateGuard)
	on(model:GetAttributeChangedSignal("GuardBroken"), updateGuard)
	updateGuard()

	-- Contorno tenue del equipo
	local teamOutline = Instance.new("Highlight")
	teamOutline.Name = "TeamOutline"
	teamOutline.FillTransparency = N.One
	teamOutline.OutlineTransparency = N.One
	teamOutline.DepthMode = Enum.HighlightDepthMode.Occluded
	teamOutline.Adornee = model
	teamOutline.Parent = model
	table.insert(a.instances, teamOutline)
	local function updateTeamOutline()
		local col = teamColorOf(model)
		teamOutline.OutlineColor = col or C.Bone
		teamOutline.OutlineTransparency = col and Theme.Teams.OutlineTransparency or N.One
		teamOutline.Enabled = col ~= nil -- Roblox limita los Highlight activos (31): solo si hay equipo
	end
	updateTeamOutline()
	if player then on(player:GetPropertyChangedSignal("Team"), updateTeamOutline) end

	-- Indicadores en el arma (aviso y guardia)
	local weaponGlow = Instance.new("Highlight")
	weaponGlow.Name = "WeaponGlow"
	weaponGlow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	weaponGlow.Enabled = false
	weaponGlow.Parent = model
	table.insert(a.instances, weaponGlow)

	-- Aviso de fuerte (etapa 8): punto rojo en la punta del arma con un anillo que se cierra hasta el golpe.
	-- No tiñe el arma (la skin se sigue viendo). Imbloqueable: centro incandescente que late y doble anillo dorado.
	local ring -- BillboardGui del aviso
	local ringHitAt = N.Zero
	local ringPulse -- conexión del latido (imbloqueable)
	local function clearRing(flash)
		if ringPulse then ringPulse:Disconnect() ringPulse = nil end
		if not ring then return end
		local old = ring
		ring = nil
		-- Si se apaga al llegar el golpe (no por finta o interrupción), destella antes de irse
		if flash and workspace:GetServerTimeNow() >= ringHitAt - TG.FlashTime then
			local info = TweenInfo.new(TG.FlashTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			for _, f in old:GetChildren() do
				if f:IsA("Frame") then
					local s = f.Size.X.Scale * TG.FlashScale
					TweenService:Create(f, info, { Size = UDim2.fromScale(s, s), BackgroundTransparency = N.One }):Play()
					local stroke = f:FindFirstChildOfClass("UIStroke")
					if stroke then TweenService:Create(stroke, info, { Transparency = N.One }):Play() end
				end
			end
			task.delay(TG.FlashTime, function() old:Destroy() end)
		else
			old:Destroy()
		end
	end

	local function circle(parent, size, color, transparency, z)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(N.Half, N.Half)
		f.Position = UDim2.fromScale(N.Half, N.Half)
		f.Size = UDim2.fromScale(size, size)
		f.BackgroundColor3 = color
		f.BackgroundTransparency = transparency
		f.BorderSizePixel = N.Zero
		f.ZIndex = z
		f.Parent = parent
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(N.Half, N.Zero)
		cr.Parent = f
		return f
	end

	local function makeRing(tool, unblockable, hitAt)
		clearRing(false)
		local tip = tool and tool:FindFirstChild("BladeTip", true)
		local adornee = tip or (tool and tool:FindFirstChild("Handle")) or head
		local remaining = math.max(N.Value_0_15, hitAt - workspace:GetServerTimeNow())
		ringHitAt = hitAt
		ring = Instance.new("BillboardGui")
		ring.Name = "TelegraphRing"
		ring.Size = UDim2.fromOffset(TG.Canvas, TG.Canvas)
		ring.AlwaysOnTop = true
		ring.LightInfluence = N.Zero
		ring.Adornee = adornee
		ring.Parent = model
		local linear = TweenInfo.new(remaining, Enum.EasingStyle.Linear)
		-- halo y punto: crecen a medida que se acerca el golpe
		local halo = circle(ring, TG.Halo, unblockable and TG.UnblockableHalo or TG.HeavyHalo, TG.HaloTransparency, N.One)
		local core = circle(ring, TG.Dot, unblockable and TG.UnblockableCore or TG.HeavyCore, N.Zero, N.Three)
		TweenService:Create(halo, linear, { Size = UDim2.fromScale(TG.Halo * TG.DotGrow, TG.Halo * TG.DotGrow) }):Play()
		TweenService:Create(core, linear, { Size = UDim2.fromScale(TG.Dot * TG.DotGrow, TG.Dot * TG.DotGrow) }):Play()
		if unblockable then
			local edge = Instance.new("UIStroke")
			edge.Color = TG.UnblockableHalo
			edge.Thickness = TG.RingThickness
			edge.Parent = core
		end
		-- anillo(s) que se cierran hacia el punto: cuando lo tocan, llega el golpe
		local ringColor = unblockable and TG.UnblockableRing or TG.HeavyRing
		for i = N.One, unblockable and N.Two or N.One do
			local start = i == N.One and TG.Ring or TG.Ring * N.Value_0_7
			local f = circle(ring, start, ringColor, N.One, N.Two)
			local st = Instance.new("UIStroke")
			st.Color = ringColor
			st.Thickness = TG.RingThickness
			st.Parent = f
			TweenService:Create(f, linear, { Size = UDim2.fromScale(TG.RingEnd, TG.RingEnd) }):Play()
		end
		if unblockable then
			local scale = Instance.new("UIScale")
			scale.Parent = core
			ringPulse = RunService.RenderStepped:Connect(function()
				scale.Scale = N.One + math.sin(os.clock() * TG.Pulse * math.pi * N.Two) * TG.PulseAmp
			end)
		end
	end

	local lastTelegraph = ""
	local function updateWeaponFx()
		local tool = model:FindFirstChildOfClass("Tool")
		local telegraph = model:GetAttribute("Telegraph") or ""
		local wasTelegraph = lastTelegraph ~= ""
		lastTelegraph = telegraph
		if telegraph ~= "" then
			local unblockable = telegraph == "Unblockable"
			local color = unblockable and C.TelegraphUnblockable or C.TelegraphHeavy
			weaponGlow.Enabled = false -- etapa 8: el arma ya no se tiñe entera
			warnHolder.Visible = true
			diamond.BackgroundColor3 = color
			diamondStroke.Color = C.Charcoal
			warnText.Text = L.t(unblockable and "unblockable" or "warning")
			makeRing(tool, unblockable, model:GetAttribute("HitAt") or N.Zero)
		elseif model:GetAttribute("Blocking") then
			clearRing(wasTelegraph)
			warnHolder.Visible = false
			weaponGlow.Adornee = tool or model
			weaponGlow.FillTransparency = N.One
			weaponGlow.OutlineColor = C.BlockGlow
			weaponGlow.OutlineTransparency = tool and N.Value_0_15 or N.Value_0_7
			weaponGlow.Enabled = true
		else
			clearRing(wasTelegraph)
			warnHolder.Visible = false
			weaponGlow.Enabled = false
		end
	end
	on(model:GetAttributeChangedSignal("Telegraph"), updateWeaponFx)
	on(model:GetAttributeChangedSignal("Blocking"), updateWeaponFx)
	on(model.ChildAdded, function(c) if c:IsA("Tool") then updateWeaponFx() end end)
	updateWeaponFx()

	-- Brillo de invulnerabilidad: dura lo mismo que los i-frames de la esquiva
	local iframeGlow = Instance.new("Highlight")
	iframeGlow.Name = "IFrameGlow"
	iframeGlow.Adornee = model
	iframeGlow.FillColor = C.IFrame
	iframeGlow.OutlineColor = C.IFrame
	iframeGlow.DepthMode = Enum.HighlightDepthMode.Occluded
	iframeGlow.Enabled = false
	iframeGlow.Parent = model
	table.insert(a.instances, iframeGlow)
	local iframeToken = N.Zero
	local function updateIFrames()
		local untilT = model:GetAttribute("IFrameUntil") or N.Zero
		if untilT <= N.Zero then return end
		-- Con lag el atributo puede llegar tarde: se muestra al menos un instante
		local remaining = math.clamp(untilT - workspace:GetServerTimeNow(), N.Value_0_12, N.One)
		iframeToken += N.One
		local my = iframeToken
		iframeGlow.FillTransparency = N.Value_0_3
		iframeGlow.OutlineTransparency = N.Zero
		iframeGlow.Enabled = true
		TweenService:Create(iframeGlow, TweenInfo.new(remaining, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ FillTransparency = N.Value_0_85, OutlineTransparency = N.Value_0_6 }):Play()
		task.delay(remaining, function()
			if iframeToken == my then iframeGlow.Enabled = false end
		end)
	end
	on(model:GetAttributeChangedSignal("IFrameUntil"), updateIFrames)

	on(model.AncestryChanged, function(_, parent)
		if not parent then
			clearRing()
			detach(model)
		end
	end)
	on(hum.Died, function()
		clearRing()
		weaponGlow.Enabled = false
		warnHolder.Visible = false
	end)
end

CollectionService:GetInstanceAddedSignal("Combatant"):Connect(function(m)
	task.spawn(attach, m)
end)
CollectionService:GetInstanceRemovedSignal("Combatant"):Connect(detach)
for _, m in CollectionService:GetTagged("Combatant") do
	task.spawn(attach, m)
end

L.Changed:Connect(function()
 local models = {} for model in attached do table.insert(models, model) end
 for _, model in models do detach(model) task.spawn(attach, model) end
end)
