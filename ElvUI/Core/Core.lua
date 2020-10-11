local ElvUI = select(2, ...)
ElvUI[2] = ElvUI[1].Libs.ACL:GetLocale('ElvUI', ElvUI[1]:GetLocale()) -- Locale doesn't exist yet, make it exist.
local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB

--Lua functions
local _G = _G
local tonumber, pairs, ipairs, error, unpack, select, tostring = tonumber, pairs, ipairs, error, unpack, select, tostring
local strjoin, twipe, tinsert, tremove, tContains = strjoin, wipe, tinsert, tremove, tContains
local format, find, strrep, strlen, sub, gsub = format, strfind, strrep, strlen, strsub, gsub
local assert, type, pcall, xpcall, next, print = assert, type, pcall, xpcall, next, print
local rawget, rawset, setmetatable = rawget, rawset, setmetatable

local CreateFrame = CreateFrame
local GetCVar = GetCVar
local GetCVarBool = GetCVarBool
local GetNumGroupMembers = GetNumGroupMembers
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local GetAddOnEnableState = GetAddOnEnableState
local UnitFactionGroup = UnitFactionGroup
local DisableAddOn = DisableAddOn
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local IsInRaid = IsInRaid
local SetCVar = SetCVar
local ReloadUI = ReloadUI
local GetSpellInfo = GetSpellInfo
local UnitGUID = UnitGUID

local ERR_NOT_IN_COMBAT = ERR_NOT_IN_COMBAT
local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local C_ChatInfo_SendAddonMessage = C_ChatInfo.SendAddonMessage
-- GLOBALS: ElvUIPlayerBuffs, ElvUIPlayerDebuffs

--Modules
local ActionBars = E:GetModule('ActionBars')
local AFK = E:GetModule('AFK')
local Auras = E:GetModule('Auras')
local Bags = E:GetModule('Bags')
--local Blizzard = E:GetModule('Blizzard')
local Chat = E:GetModule('Chat')
local DataBars = E:GetModule('DataBars')
local DataTexts = E:GetModule('DataTexts')
local Layout = E:GetModule('Layout')
local Minimap = E:GetModule('Minimap')
local NamePlates = E:GetModule('NamePlates')
local Tooltip = E:GetModule('Tooltip')
local Totems = E:GetModule('Totems')
local UnitFrames = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM

--Constants
E.noop = function() end
E.title = format('|cff1784d1%s |r', 'ElvUI')
E.version = tonumber(GetAddOnMetadata('ElvUI', 'Version'))
E.myfaction, E.myLocalizedFaction = UnitFactionGroup('player')
E.mylevel = UnitLevel('player')
E.myLocalizedClass, E.myclass, E.myClassID = UnitClass('player')
E.myLocalizedRace, E.myrace = UnitRace('player')
E.myname = UnitName('player')
E.myrealm = GetRealmName()
E.mynameRealm = format('%s - %s', E.myname, E.myrealm) -- contains spaces/dashes in realm (for profile keys)
E.wowpatch, E.wowbuild = GetBuildInfo()
E.wowbuild = tonumber(E.wowbuild)
E.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
E.resolution = ({GetScreenResolutions()})[GetCurrentResolution()] or GetCVar('gxWindowedResolution') --only used for now in our install.lua line 779
E.screenwidth, E.screenheight = GetPhysicalScreenSize()
E.isMacClient = IsMacClient()
E.NewSign = '|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:14:14|t' -- not used by ElvUI yet, but plugins like BenikUI and MerathilisUI use it.
E.TexturePath = 'Interface\\AddOns\\ElvUI\\Media\\Textures\\' -- for plugins?
E.InfoColor = '|cff1784d1'
E.UserList = {}

-- oUF Defines
E.oUF.Tags.Vars.E = E
E.oUF.Tags.Vars.L = L

--Tables
E.media = {}
E.frames = {}
E.unitFrameElements = {}
E.statusBars = {}
E.texts = {}
E.snapBars = {}
E.RegisteredModules = {}
E.RegisteredInitialModules = {}
E.valueColorUpdateFuncs = {}
E.TexCoords = {0, 1, 0, 1}
E.FrameLocks = {}
E.VehicleLocks = {}
E.CreditsList = {}
E.LockedCVars = {}
E.IgnoredCVars = {}
E.UpdatedCVars = {}
E.InversePoints = {
	TOP = 'BOTTOM',
	BOTTOM = 'TOP',
	TOPLEFT = 'BOTTOMLEFT',
	TOPRIGHT = 'BOTTOMRIGHT',
	LEFT = 'RIGHT',
	RIGHT = 'LEFT',
	BOTTOMLEFT = 'TOPLEFT',
	BOTTOMRIGHT = 'TOPRIGHT',
	CENTER = 'CENTER'
}

E.ClassRole = {
	HUNTER		= 'Melee',
	ROGUE		= 'Melee',
	MAGE		= 'Caster',
	PRIEST		= 'Caster',
	WARLOCK		= 'Caster',
	DEMONHUNTER	= {'Melee',  'Tank'},
	WARRIOR		= {'Melee',  'Melee',  'Tank'},
	DEATHKNIGHT	= {'Tank',   'Melee',  'Melee'},
	MONK		= {'Tank',   'Caster', 'Melee'},
	PALADIN		= {'Caster', 'Tank',   'Melee'},
	SHAMAN		= {'Caster', 'Melee',  'Caster'},
	DRUID		= {'Caster', 'Melee',  'Tank',  'Caster'},
}

E.DispelClasses = {
	DRUID = { Curse = true, Poison = true },
	MAGE = { Curse = true },
	PALADIN = { Magic = true, Poison = true, Disease = true },
	PRIEST = { Magic = true, Disease = true },
	SHAMAN = { Poison = true, Disease = true },
	WARLOCK = { Magic = true }
}

E.BadDispels = {
	[34914]		= 'Vampiric Touch',		-- horrifies
	[233490]	= 'Unstable Affliction'	-- silences
}

--Workaround for people wanting to use white and it reverting to their class color.
E.PriestColors = { r = 0.99, g = 0.99, b = 0.99, colorStr = 'fffcfcfc' }

--This frame everything in ElvUI should be anchored to for Eyefinity support.
E.UIParent = CreateFrame('Frame', 'ElvUIParent', _G.UIParent)
E.UIParent:SetFrameLevel(_G.UIParent:GetFrameLevel())
E.UIParent:SetSize(_G.UIParent:GetSize())
E.UIParent:SetPoint('BOTTOM')
E.UIParent.origHeight = E.UIParent:GetHeight()
E.snapBars[#E.snapBars + 1] = E.UIParent

E.HiddenFrame = CreateFrame('Frame')
E.HiddenFrame:Hide()

do -- used in optionsUI
	E.DEFAULT_FILTER = {}
	for filter, tbl in pairs(G.unitframe.aurafilters) do
		E.DEFAULT_FILTER[filter] = tbl.type
	end
end

do
	local a1,a2 = '','[%s%-]'
	function E:ShortenRealm(realm)
		return gsub(realm, a2, a1)
	end

	local a3 = format('%%-%s', E:ShortenRealm(E.myrealm))
	function E:StripMyRealm(name)
		return gsub(name, a3, a1)
	end
end

function E:Print(...)
	(E.db and _G[E.db.general.messageRedirect] or _G.DEFAULT_CHAT_FRAME):AddMessage(strjoin('', E.media.hexvaluecolor or '|cff00b3ff', 'ElvUI:|r ', ...)) -- I put DEFAULT_CHAT_FRAME as a fail safe.
end

function E:GrabColorPickerValues(r, g, b)
	-- we must block the execution path to `ColorCallback` in `AceGUIWidget-ColorPicker-ElvUI`
	-- in order to prevent an infinite loop from `OnValueChanged` when passing into `E.UpdateMedia` which eventually leads here again.
	_G.ColorPickerFrame.noColorCallback = true

	-- grab old values
	local oldR, oldG, oldB = _G.ColorPickerFrame:GetColorRGB()

	-- set and define the new values
	_G.ColorPickerFrame:SetColorRGB(r, g, b)
	r, g, b = _G.ColorPickerFrame:GetColorRGB()

	-- swap back to the old values
	if oldR then _G.ColorPickerFrame:SetColorRGB(oldR, oldG, oldB) end

	-- free it up..
	_G.ColorPickerFrame.noColorCallback = nil

	return r, g, b
end

--Basically check if another class border is being used on a class that doesn't match. And then return true if a match is found.
function E:CheckClassColor(r, g, b)
	r, g, b = E:GrabColorPickerValues(r, g, b)

	for class in pairs(_G.RAID_CLASS_COLORS) do
		if class ~= E.myclass then
			local colorTable = E:ClassColor(class, true)
			local red, green, blue = E:GrabColorPickerValues(colorTable.r, colorTable.g, colorTable.b)
			if red == r and green == g and blue == b then
				return true
			end
		end
	end
end

function E:SetColorTable(t, data)
	if not data.r or not data.g or not data.b then
		error('SetColorTable: Could not unpack color values.')
	end

	if t and (type(t) == 'table') then
		t[1], t[2], t[3], t[4] = E:UpdateColorTable(data)
	else
		t = E:GetColorTable(data)
	end

	return t
end

function E:UpdateColorTable(data)
	if not data.r or not data.g or not data.b then
		error('UpdateColorTable: Could not unpack color values.')
	end

	if (data.r > 1 or data.r < 0) then data.r = 1 end
	if (data.g > 1 or data.g < 0) then data.g = 1 end
	if (data.b > 1 or data.b < 0) then data.b = 1 end
	if data.a and (data.a > 1 or data.a < 0) then data.a = 1 end

	if data.a then
		return data.r, data.g, data.b, data.a
	else
		return data.r, data.g, data.b
	end
end

function E:GetColorTable(data)
	if not data.r or not data.g or not data.b then
		error('GetColorTable: Could not unpack color values.')
	end

	if (data.r > 1 or data.r < 0) then data.r = 1 end
	if (data.g > 1 or data.g < 0) then data.g = 1 end
	if (data.b > 1 or data.b < 0) then data.b = 1 end
	if data.a and (data.a > 1 or data.a < 0) then data.a = 1 end

	if data.a then
		return {data.r, data.g, data.b, data.a}
	else
		return {data.r, data.g, data.b}
	end
end

function E:UpdateMedia()
	if not E.db.general or not E.private.general then return end --Prevent rare nil value errors

	--Fonts
	E.media.normFont = LSM:Fetch('font', E.db.general.font)
	E.media.combatFont = LSM:Fetch('font', E.private.general.dmgfont)

	--Textures
	E.media.blankTex = LSM:Fetch('background', 'ElvUI Blank')
	E.media.normTex = LSM:Fetch('statusbar', E.private.general.normTex)
	E.media.glossTex = LSM:Fetch('statusbar', E.private.general.glossTex)

	--Border Color
	local border = E.db.general.bordercolor
	if E:CheckClassColor(border.r, border.g, border.b) then
		local classColor = E:ClassColor(E.myclass, true)
		E.db.general.bordercolor.r = classColor.r
		E.db.general.bordercolor.g = classColor.g
		E.db.general.bordercolor.b = classColor.b
	end

	E.media.bordercolor = {border.r, border.g, border.b}

	--UnitFrame Border Color
	border = E.db.unitframe.colors.borderColor
	if E:CheckClassColor(border.r, border.g, border.b) then
		local classColor = E:ClassColor(E.myclass, true)
		E.db.unitframe.colors.borderColor.r = classColor.r
		E.db.unitframe.colors.borderColor.g = classColor.g
		E.db.unitframe.colors.borderColor.b = classColor.b
	end
	E.media.unitframeBorderColor = {border.r, border.g, border.b}

	--Backdrop Color
	E.media.backdropcolor = E:SetColorTable(E.media.backdropcolor, E.db.general.backdropcolor)

	--Backdrop Fade Color
	E.media.backdropfadecolor = E:SetColorTable(E.media.backdropfadecolor, E.db.general.backdropfadecolor)

	--Value Color
	local value = E.db.general.valuecolor
	if E:CheckClassColor(value.r, value.g, value.b) then
		value = E:ClassColor(E.myclass, true)
		E.db.general.valuecolor.r = value.r
		E.db.general.valuecolor.g = value.g
		E.db.general.valuecolor.b = value.b
	end

	--Chat Tab Selector Color
	local selectorColor = E.db.chat.tabSelectorColor
	if E:CheckClassColor(selectorColor.r, selectorColor.g, selectorColor.b) then
		selectorColor = E:ClassColor(E.myclass, true)
		E.db.chat.tabSelectorColor.r = selectorColor.r
		E.db.chat.tabSelectorColor.g = selectorColor.g
		E.db.chat.tabSelectorColor.b = selectorColor.b
	end

	E.media.hexvaluecolor = E:RGBToHex(value.r, value.g, value.b)
	E.media.rgbvaluecolor = {value.r, value.g, value.b}

	-- Chat Panel Background Texture
	local LeftChatPanel, RightChatPanel = _G.LeftChatPanel, _G.RightChatPanel
	if LeftChatPanel and LeftChatPanel.tex and RightChatPanel and RightChatPanel.tex then
		LeftChatPanel.tex:SetTexture(E.db.chat.panelBackdropNameLeft)
		RightChatPanel.tex:SetTexture(E.db.chat.panelBackdropNameRight)

		local a = E.db.general.backdropfadecolor.a or 0.5
		LeftChatPanel.tex:SetAlpha(a)
		RightChatPanel.tex:SetAlpha(a)
	end

	E:ValueFuncCall()
	E:UpdateBlizzardFonts()
end

do	--Update font/texture paths when they are registered by the addon providing them
	--This helps fix most of the issues with fonts or textures reverting to default because the addon providing them is loading after ElvUI.
	--We use a wrapper to avoid errors in :UpdateMedia because 'self' is passed to the function with a value other than ElvUI.
	local function LSMCallback() E:UpdateMedia() end
	LSM.RegisterCallback(E, 'LibSharedMedia_Registered', LSMCallback)
end

do
	local function CVAR_UPDATE(name, value)
		if not E.IgnoredCVars[name] then
			local locked = E.LockedCVars[name]
			if locked ~= nil and locked ~= value then
				if InCombatLockdown() then
					E.CVarUpdate = true
					return
				end

				SetCVar(name, locked)
			end

			local func = E.UpdatedCVars[name]
			if func then func(value) end
		end
	end

	hooksecurefunc('SetCVar', CVAR_UPDATE)
	function E:LockCVar(name, value)
		if GetCVar(name) ~= value then
			SetCVar(name, value)
		end

		E.LockedCVars[name] = value
	end

	function E:UpdatedCVar(name, func)
		E.UpdatedCVars[name] = func
	end

	function E:IgnoreCVar(name, ignore)
		E.IgnoredCVars[name] = (not not ignore) -- cast to bool, just in case
	end
end

function E:ValueFuncCall()
	local hex, r, g, b = E.media.hexvaluecolor, unpack(E.media.rgbvaluecolor)
	for func in pairs(E.valueColorUpdateFuncs) do func(hex, r, g, b) end
end

function E:UpdateFrameTemplates()
	for frame in pairs(E.frames) do
		if frame and frame.template and not frame.ignoreUpdates then
			if not frame.ignoreFrameTemplates then
				frame:SetTemplate(frame.template, frame.glossTex, nil, frame.forcePixelMode)
			end
		else
			E.frames[frame] = nil
		end
	end

	for frame in pairs(E.unitFrameElements) do
		if frame and frame.template and not frame.ignoreUpdates then
			if not frame.ignoreFrameTemplates then
				frame:SetTemplate(frame.template, frame.glossTex, nil, frame.forcePixelMode, frame.isUnitFrameElement)
			end
		else
			E.unitFrameElements[frame] = nil
		end
	end
end

function E:UpdateBorderColors()
	local r, g, b = unpack(E.media.bordercolor)
	for frame in pairs(E.frames) do
		if frame and frame.template and not frame.ignoreUpdates then
			if not frame.ignoreBorderColors then
				if frame.template == 'Default' or frame.template == 'Transparent' then
					frame:SetBackdropBorderColor(r, g, b)
				end
			end
		else
			E.frames[frame] = nil
		end
	end

	local r2, g2, b2 = unpack(E.media.unitframeBorderColor)
	for frame in pairs(E.unitFrameElements) do
		if frame and frame.template and not frame.ignoreUpdates then
			if not frame.ignoreBorderColors then
				if frame.template == 'Default' or frame.template == 'Transparent' then
					frame:SetBackdropBorderColor(r2, g2, b2)
				end
			end
		else
			E.unitFrameElements[frame] = nil
		end
	end
end

function E:UpdateBackdropColors()
	local r, g, b = unpack(E.media.backdropcolor)
	local r2, g2, b2, a2 = unpack(E.media.backdropfadecolor)

	for frame in pairs(E.frames) do
		if frame and frame.template and not frame.ignoreUpdates then
			if not frame.ignoreBackdropColors then
				if frame.template == 'Default' then
					frame:SetBackdropColor(r, g, b)
				elseif frame.template == 'Transparent' then
					frame:SetBackdropColor(r2, g2, b2, a2)
				end
			end
		else
			E.frames[frame] = nil
		end
	end

	for frame in pairs(E.unitFrameElements) do
		if frame and frame.template and not frame.ignoreUpdates then
			if not frame.ignoreBackdropColors then
				if frame.template == 'Default' then
					frame:SetBackdropColor(r, g, b)
				elseif frame.template == 'Transparent' then
					frame:SetBackdropColor(r2, g2, b2, a2)
				end
			end
		else
			E.unitFrameElements[frame] = nil
		end
	end
end

function E:UpdateFontTemplates()
	for text in pairs(E.texts) do
		if text then
			text:FontTemplate(text.font, text.fontSize, text.fontStyle)
		else
			E.texts[text] = nil
		end
	end
end

function E:RegisterStatusBar(statusBar)
	tinsert(E.statusBars, statusBar)
end

function E:UpdateStatusBars()
	for _, statusBar in pairs(E.statusBars) do
		if statusBar and statusBar:IsObjectType('StatusBar') then
			statusBar:SetStatusBarTexture(E.media.normTex)
		elseif statusBar and statusBar:IsObjectType('Texture') then
			statusBar:SetTexture(E.media.normTex)
		end
	end
end

do
	local cancel = function(popup)
		DisableAddOn(popup.addon)
		ReloadUI()
	end

	function E:IncompatibleAddOn(addon, module, info)
		local popup = E.PopupDialogs.INCOMPATIBLE_ADDON
		popup.button2 = info.name or module
		popup.button1 = addon
		popup.module = module
		popup.addon = addon
		popup.accept = info.accept
		popup.cancel = info.cancel or cancel

		E:StaticPopup_Show('INCOMPATIBLE_ADDON', popup.button1, popup.button2)
	end
end

function E:IsAddOnEnabled(addon)
	return GetAddOnEnableState(E.myname, addon) == 2
end

function E:IsIncompatible(module, addons)
	for _, addon in ipairs(addons) do
		if E:IsAddOnEnabled(addon) then
			E:IncompatibleAddOn(addon, module, addons.info)
			return true
		end
	end
end

do
	local ADDONS = {
		ActionBar = {
			info = {
				enabled = function() return E.private.actionbar.enable end,
				accept = function() E.private.actionbar.enable = false; ReloadUI() end,
				name = 'ElvUI ActionBars'
			},
			'Bartender4',
			'Dominos'
		},
		Chat = {
			info = {
				enabled = function() return E.private.chat.enable end,
				accept = function() E.private.chat.enable = false; ReloadUI() end,
				name = 'ElvUI Chat'
			},
			'Prat-3.0',
			'Chatter',
			'Glass'
		},
		NamePlates = {
			info = {
				enabled = function() return E.private.nameplates.enable end,
				accept = function() E.private.nameplates.enable = false; ReloadUI() end,
				name = 'ElvUI NamePlates'
			},
			'TidyPlates',
			'Healers-Have-To-Die',
			'Kui_Nameplates',
			'Plater',
			'Aloft'
		}
	}

	E.INCOMPATIBLE_ADDONS = ADDONS -- let addons have the ability to alter this list to trigger our popup if they want
	function E:AddIncompatible(module, addonName)
		if ADDONS[module] then
			tinsert(ADDONS[module], addonName)
		else
			print(module, 'is not in the incompatibility list.')
		end
	end

	function E:CheckIncompatible()
		if E.global.ignoreIncompatible then return end

		for module, addons in pairs(ADDONS) do
			if addons[1] and addons.info.enabled() and E:IsIncompatible(module, addons) then
				break
			end
		end
	end
end

function E:CopyTable(currentTable, defaultTable)
	if type(currentTable) ~= 'table' then currentTable = {} end

	if type(defaultTable) == 'table' then
		for option, value in pairs(defaultTable) do
			if type(value) == 'table' then
				value = E:CopyTable(currentTable[option], value)
			end

			currentTable[option] = value
		end
	end

	return currentTable
end

function E:RemoveEmptySubTables(tbl)
	if type(tbl) ~= 'table' then
		E:Print('Bad argument #1 to \'RemoveEmptySubTables\' (table expected)')
		return
	end

	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			if next(v) == nil then
				tbl[k] = nil
			else
				E:RemoveEmptySubTables(v)
			end
		end
	end
end

--Compare 2 tables and remove duplicate key/value pairs
--param cleanTable : table you want cleaned
--param checkTable : table you want to check against.
--param generatedKeys : table defined in `Distributor.lua` to allow user generated tables to be exported (customTexts, customCurrencies, etc).
--return : a copy of cleanTable with duplicate key/value pairs removed
function E:RemoveTableDuplicates(cleanTable, checkTable, generatedKeys)
	if type(cleanTable) ~= 'table' then
		E:Print('Bad argument #1 to \'RemoveTableDuplicates\' (table expected)')
		return
	end
	if type(checkTable) ~=  'table' then
		E:Print('Bad argument #2 to \'RemoveTableDuplicates\' (table expected)')
		return
	end

	local rtdCleaned = {}
	local keyed = type(generatedKeys) == 'table'
	for option, value in pairs(cleanTable) do
		local default, genTable, genOption = checkTable[option]
		if keyed then genTable = generatedKeys[option] else genOption = generatedKeys end

		-- we only want to add settings which are existing in the default table, unless it's allowed by generatedKeys
		if default ~= nil or (genTable or genOption ~= nil) then
			if type(value) == 'table' and type(default) == 'table' then
				if genOption ~= nil then
					rtdCleaned[option] = E:RemoveTableDuplicates(value, default, genOption)
				else
					rtdCleaned[option] = E:RemoveTableDuplicates(value, default, genTable or nil)
				end
			elseif cleanTable[option] ~= default then
				-- add unique data to our clean table
				rtdCleaned[option] = value
			end
		end
	end

	--Clean out empty sub-tables
	E:RemoveEmptySubTables(rtdCleaned)

	return rtdCleaned
end

--Compare 2 tables and remove blacklisted key/value pairs
--param cleanTable : table you want cleaned
--param blacklistTable : table you want to check against.
--return : a copy of cleanTable with blacklisted key/value pairs removed
function E:FilterTableFromBlacklist(cleanTable, blacklistTable)
	if type(cleanTable) ~= 'table' then
		E:Print('Bad argument #1 to \'FilterTableFromBlacklist\' (table expected)')
		return
	end
	if type(blacklistTable) ~=  'table' then
		E:Print('Bad argument #2 to \'FilterTableFromBlacklist\' (table expected)')
		return
	end

	local tfbCleaned = {}
	for option, value in pairs(cleanTable) do
		if type(value) == 'table' and blacklistTable[option] and type(blacklistTable[option]) == 'table' then
			tfbCleaned[option] = E:FilterTableFromBlacklist(value, blacklistTable[option])
		else
			-- Filter out blacklisted keys
			if (blacklistTable[option] ~= true) then
				tfbCleaned[option] = value
			end
		end
	end

	--Clean out empty sub-tables
	E:RemoveEmptySubTables(tfbCleaned)

	return tfbCleaned
end

do	--The code in this function is from WeakAuras, credit goes to Mirrored and the WeakAuras Team
	--Code slightly modified by Simpy
	local function recurse(table, level, ret)
		for i, v in pairs(table) do
			ret = ret..strrep('    ', level)..'['
			if type(i) == 'string' then ret = ret..'"'..i..'"' else ret = ret..i end
			ret = ret..'] = '

			if type(v) == 'number' then
				ret = ret..v..',\n'
			elseif type(v) == 'string' then
				ret = ret..'"'..v:gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('"', '\\"'):gsub('\124', '\124\124')..'",\n'
			elseif type(v) == 'boolean' then
				if v then ret = ret..'true,\n' else ret = ret..'false,\n' end
			elseif type(v) == 'table' then
				ret = ret..'{\n'
				ret = recurse(v, level + 1, ret)
				ret = ret..strrep('    ', level)..'},\n'
			else
				ret = ret..'"'..tostring(v)..'",\n'
			end
		end

		return ret
	end

	function E:TableToLuaString(inTable)
		if type(inTable) ~= 'table' then
			E:Print('Invalid argument #1 to E:TableToLuaString (table expected)')
			return
		end

		local ret = '{\n'
		if inTable then ret = recurse(inTable, 1, ret) end
		ret = ret..'}'

		return ret
	end
end

do	--The code in this function is from WeakAuras, credit goes to Mirrored and the WeakAuras Team
	--Code slightly modified by Simpy
	local lineStructureTable, profileFormat = {}, {
		profile = 'E.db',
		private = 'E.private',
		global = 'E.global',
		filters = 'E.global',
		styleFilters = 'E.global'
	}

	local function buildLineStructure(str) -- str is profileText
		for _, v in ipairs(lineStructureTable) do
			if type(v) == 'string' then
				str = str..'["'..v..'"]'
			else
				str = str..'['..v..']'
			end
		end

		return str
	end

	local sameLine
	local function recurse(tbl, ret, profileText)
		local lineStructure = buildLineStructure(profileText)
		for k, v in pairs(tbl) do
			if not sameLine then
				ret = ret..lineStructure
			end

			ret = ret..'['

			if type(k) == 'string' then
				ret = ret..'"'..k..'"'
			else
				ret = ret..k
			end

			if type(v) == 'table' then
				tinsert(lineStructureTable, k)
				sameLine = true
				ret = ret..']'
				ret = recurse(v, ret, profileText)
			else
				sameLine = false
				ret = ret..'] = '

				if type(v) == 'number' then
					ret = ret..v..'\n'
				elseif type(v) == 'string' then
					ret = ret..'"'..v:gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('"', '\\"'):gsub('\124', '\124\124')..'"\n'
				elseif type(v) == 'boolean' then
					if v then
						ret = ret..'true\n'
					else
						ret = ret..'false\n'
					end
				else
					ret = ret..'"'..tostring(v)..'"\n'
				end
			end
		end

		tremove(lineStructureTable)

		return ret
	end

	function E:ProfileTableToPluginFormat(inTable, profileType)
		local profileText = profileFormat[profileType]
		if not profileText then return end

		twipe(lineStructureTable)
		local ret = ''
		if inTable and profileType then
			sameLine = false
			ret = recurse(inTable, ret, profileText)
		end

		return ret
	end
end

do	--Split string by multi-character delimiter (the strsplit / string.split function provided by WoW doesn't allow multi-character delimiter)
	local splitTable = {}
	function E:SplitString(str, delim)
		assert(type (delim) == 'string' and strlen(delim) > 0, 'bad delimiter')

		local start = 1
		twipe(splitTable)  -- results table

		-- find each instance of a string followed by the delimiter
		while true do
			local pos = find(str, delim, start, true) -- plain find
			if not pos then break end

			tinsert(splitTable, sub(str, start, pos - 1))
			start = pos + strlen(delim)
		end -- while

		-- insert final one (after last delimiter)
		tinsert(splitTable, sub(str, start))

		return unpack(splitTable)
	end
end

do
	local SendMessageWaiting -- only allow 1 delay at a time regardless of eventing
	function E:SendMessage()
		if IsInRaid() then
			C_ChatInfo_SendAddonMessage('ELVUI_VERSIONCHK', E.version, (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and 'INSTANCE_CHAT' or 'RAID')
		elseif IsInGroup() then
			C_ChatInfo_SendAddonMessage('ELVUI_VERSIONCHK', E.version, (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and 'INSTANCE_CHAT' or 'PARTY')
		elseif IsInGuild() then
			C_ChatInfo_SendAddonMessage('ELVUI_VERSIONCHK', E.version, 'GUILD')
		end

		SendMessageWaiting = nil
	end

	local SendRecieveGroupSize = 0
	local PLAYER_NAME = format('%s-%s', E.myname, E:ShortenRealm(E.myrealm))
	local function SendRecieve(_, event, prefix, message, _, sender)
		if event == 'CHAT_MSG_ADDON' then
			if sender == PLAYER_NAME then return end
			if prefix == 'ELVUI_VERSIONCHK' then
				local msg, ver = tonumber(message), E.version
				local inCombat = InCombatLockdown()

				E.UserList[E:StripMyRealm(sender)] = msg
				if ver ~= G.general.version then
					if not E.shownUpdatedWhileRunningPopup and not inCombat then
						E:StaticPopup_Show('ELVUI_UPDATED_WHILE_RUNNING', nil, nil, {mismatch = ver > G.general.version})

						E.shownUpdatedWhileRunningPopup = true
					end
				elseif msg and (msg > ver) then -- you're outdated D:
					if not E.recievedOutOfDateMessage then
						E:Print(L["ElvUI is out of date. You can download the newest version from www.tukui.org. Get premium membership and have ElvUI automatically updated with the Tukui Client!"])

						if msg and ((msg - ver) >= 0.05) and not inCombat then
							E:StaticPopup_Show('ELVUI_UPDATE_AVAILABLE')
						end

						E.recievedOutOfDateMessage = true
					end
				end
			end
		elseif event == 'GROUP_ROSTER_UPDATE' then
			local num = GetNumGroupMembers()
			if num ~= SendRecieveGroupSize then
				if num > 1 and num > SendRecieveGroupSize then
					if not SendMessageWaiting then
						SendMessageWaiting = E:Delay(10, E.SendMessage)
					end
				end
				SendRecieveGroupSize = num
			end
		elseif event == 'PLAYER_ENTERING_WORLD' then
			if not SendMessageWaiting then
				SendMessageWaiting = E:Delay(10, E.SendMessage)
			end
		end
	end

	_G.C_ChatInfo.RegisterAddonMessagePrefix('ELVUI_VERSIONCHK')

	local f = CreateFrame('Frame')
	f:RegisterEvent('CHAT_MSG_ADDON')
	f:RegisterEvent('GROUP_ROSTER_UPDATE')
	f:RegisterEvent('PLAYER_ENTERING_WORLD')
	f:SetScript('OnEvent', SendRecieve)
end

function E:UpdateStart(skipCallback, skipUpdateDB)
	if not skipUpdateDB then
		E:UpdateDB()
	end

	E:UpdateMoverPositions()
	E:UpdateMediaItems()
	E:UpdateUnitFrames()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateDB()
	E.private = E.charSettings.profile
	E.global = E.data.global
	E.db = E.data.profile

	E:DBConversions()
	Auras.db = E.db.auras
	ActionBars.db = E.db.actionbar
	Bags.db = E.db.bags
	Chat.db = E.db.chat
	DataBars.db = E.db.databars
	DataTexts.db = E.db.datatexts
	NamePlates.db = E.db.nameplates
	Tooltip.db = E.db.tooltip
	UnitFrames.db = E.db.unitframe
	Totems.db = E.db.general.totems

	--Not part of staggered update
end

function E:UpdateMoverPositions()
	--The mover is positioned before it is resized, which causes issues for unitframes
	--Allow movers to be 'pushed' outside the screen, when they are resized they should be back in the screen area.
	--We set movers to be clamped again at the bottom of this function.
	E:SetMoversClampedToScreen(false)
	E:SetMoversPositions()

	--Not part of staggered update
end

function E:UpdateUnitFrames()
	if E.private.unitframe.enable then
		UnitFrames:Update_AllFrames()
	end

	--Not part of staggered update
end

function E:UpdateMediaItems(skipCallback)
	E:UpdateMedia()
	E:UpdateFrameTemplates()
	E:UpdateStatusBars()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateLayout(skipCallback)
	Layout:ToggleChatPanels()
	Layout:BottomPanelVisibility()
	Layout:TopPanelVisibility()
	Layout:SetDataPanelStyle()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateActionBars(skipCallback)
	ActionBars:ToggleCooldownOptions()
	ActionBars:UpdateButtonSettings()
	ActionBars:UpdateMicroPositionDimensions()
	ActionBars:UpdatePetCooldownSettings()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateNamePlates(skipCallback)
	NamePlates:ConfigureAll()
	NamePlates:StyleFilterInitialize()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateTooltip()
	Tooltip:SetTooltipFonts()
	-- for plugins :3
end

function E:UpdateBags(skipCallback)
	Bags:Layout()
	Bags:Layout(true)
	Bags:SizeAndPositionBagBar()
	Bags:UpdateCountDisplay()
	Bags:UpdateItemLevelDisplay()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateChat(skipCallback)
	Chat:SetupChat()
	Chat:UpdateEditboxAnchors()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateDataBars(skipCallback)
	DataBars:ExperienceBar_Toggle()
	DataBars:PetExperienceBar_Toggle()
	DataBars:ReputationBar_Toggle()
	DataBars:ThreatBar_Toggle()
	DataBars:UpdateAll()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateDataTexts(skipCallback)
	DataTexts:LoadDataTexts()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateMinimap(skipCallback)
	Minimap:UpdateSettings()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateAuras(skipCallback)
	if ElvUIPlayerBuffs then Auras:UpdateHeader(ElvUIPlayerBuffs) end
	if ElvUIPlayerDebuffs then Auras:UpdateHeader(ElvUIPlayerDebuffs) end

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateMisc(skipCallback)
	AFK:Toggle()
--	Blizzard:SetObjectiveFrameHeight()

--	Totems:PositionAndSize()
--	Totems:ToggleEnable()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateEnd()
	E:UpdateCooldownSettings('all')

	if E.RefreshGUI then
		E:RefreshGUI()
	end

	E:SetMoversClampedToScreen(true) -- Go back to using clamp after resizing has taken place.

	if not E.installSetup and not E.private.install_complete then
		E:Install()
	end

	if E.staggerUpdateRunning then
		--We're doing a staggered update, but plugins expect the old UpdateAll to be called
		--So call it, but skip updates inside it
		E:UpdateAll(false)
	end

	--Done updating, let code now
	E.staggerUpdateRunning = false
end

do
	local staggerDelay = 0.02
	local staggerTable = {}
	local function CallStaggeredUpdate()
		local nextUpdate, nextDelay = staggerTable[1]
		if nextUpdate then
			tremove(staggerTable, 1)

			if nextUpdate == 'UpdateNamePlates' or nextUpdate == 'UpdateBags' then
				nextDelay = 0.05
			end

			E:Delay(nextDelay or staggerDelay, E[nextUpdate])
		end
	end
	E:RegisterCallback('StaggeredUpdate', CallStaggeredUpdate)

	function E:StaggeredUpdateAll(event, installSetup)
		if not E.initialized then
			E:Delay(1, E.StaggeredUpdateAll, E, event, installSetup)
			return
		end

		E.installSetup = installSetup
		if (installSetup or event and event == 'OnProfileChanged' or event == 'OnProfileCopied') and not E.staggerUpdateRunning then
			tinsert(staggerTable, 'UpdateLayout')
			if E.private.actionbar.enable then
				tinsert(staggerTable, 'UpdateActionBars')
			end
			if E.private.nameplates.enable then
				tinsert(staggerTable, 'UpdateNamePlates')
			end
			if E.private.bags.enable then
				tinsert(staggerTable, 'UpdateBags')
			end
			if E.private.chat.enable then
				tinsert(staggerTable, 'UpdateChat')
			end
			if E.private.tooltip.enable then
				tinsert(staggerTable, 'UpdateTooltip')
			end
			tinsert(staggerTable, 'UpdateDataBars')
			tinsert(staggerTable, 'UpdateDataTexts')
			if E.private.general.minimap.enable then
				tinsert(staggerTable, 'UpdateMinimap')
			end
			if ElvUIPlayerBuffs or ElvUIPlayerDebuffs then
				tinsert(staggerTable, 'UpdateAuras')
			end
			tinsert(staggerTable, 'UpdateMisc')
			tinsert(staggerTable, 'UpdateEnd')

			--Stagger updates
			E.staggerUpdateRunning = true
			E:UpdateStart()
		else
			--Fire away
			E:UpdateAll(true)
		end
	end
end

function E:UpdateAll(doUpdates)
	if doUpdates then
		E:UpdateStart(true)

		E:UpdateLayout()
		E:UpdateTooltip()
		E:UpdateActionBars()
		E:UpdateBags()
		E:UpdateChat()
		E:UpdateDataBars()
		E:UpdateDataTexts()
		E:UpdateMinimap()
		E:UpdateNamePlates()
		E:UpdateAuras()
		E:UpdateMisc()
		E:UpdateEnd()
	end
end

do
	E.ObjectEventTable, E.ObjectEventFrame = {}, CreateFrame('Frame')
	local eventFrame, eventTable = E.ObjectEventFrame, E.ObjectEventTable

	eventFrame:SetScript('OnEvent', function(_, event, ...)
		local objs = eventTable[event]
		if objs then
			for object, funcs in pairs(objs) do
				for _, func in ipairs(funcs) do
					func(object, event, ...)
				end
			end
		end
	end)

	function E:HasFunctionForObject(event, object, func)
		if not (event and object and func) then
			E:Print('Error. Usage: HasFunctionForObject(event, object, func)')
			return
		end

		local objs = eventTable[event]
		local funcs = objs and objs[object]
		return funcs and tContains(funcs, func)
	end

	function E:IsEventRegisteredForObject(event, object)
		if not (event and object) then
			E:Print('Error. Usage: IsEventRegisteredForObject(event, object)')
			return
		end

		local objs = eventTable[event]
		local funcs = objs and objs[object]
		return funcs ~= nil, funcs
	end

	--- Registers specified event and adds specified func to be called for the specified object.
	-- Unless all parameters are supplied it will not register.
	-- If the specified object has already been registered for the specified event
	-- then it will just add the specified func to a table of functions that should be called.
	-- When a registered event is triggered, then the registered function is called with
	-- the object as first parameter, then event, and then all the parameters for the event itself.
	-- @param event The event you want to register.
	-- @param object The object you want to register the event for.
	-- @param func The function you want executed for this object.
	function E:RegisterEventForObject(event, object, func)
		if not (event and object and func) then
			E:Print('Error. Usage: RegisterEventForObject(event, object, func)')
			return
		end

		local objs = eventTable[event]
		if not objs then
			objs = {}
			eventTable[event] = objs
			pcall(eventFrame.RegisterEvent, eventFrame, event)
		end

		local funcs = objs[object]
		if not funcs then
			objs[object] = {func}
		elseif not tContains(funcs, func) then
			tinsert(funcs, func)
		end
	end

	--- Unregisters specified function for the specified object on the specified event.
	-- Unless all parameters are supplied it will not unregister.
	-- @param event The event you want to unregister an object from.
	-- @param object The object you want to unregister a func from.
	-- @param func The function you want unregistered for the object.
	function E:UnregisterEventForObject(event, object, func)
		if not (event and object and func) then
			E:Print('Error. Usage: UnregisterEventForObject(event, object, func)')
			return
		end

		local objs = eventTable[event]
		local funcs = objs and objs[object]
		if funcs then
			for index, fnc in ipairs(funcs) do
				if func == fnc then
					tremove(funcs, index)
					break
				end
			end

			if #funcs == 0 then
				objs[object] = nil
			end

			if not next(funcs) then
				eventFrame:UnregisterEvent(event)
				eventTable[event] = nil
			end
		end
	end

	function E:UnregisterAllEventsForObject(object, func)
		if not (object and func) then
			E:Print('Error. Usage: UnregisterAllEventsForObject(object, func)')
			return
		end

		for event in pairs(eventTable) do
			if E:IsEventRegisteredForObject(event, object) then
				E:UnregisterEventForObject(event, object, func)
			end
		end
	end
end

function E:ResetAllUI()
	E:ResetMovers()

	if E.db.lowresolutionset then
		E:SetupResolution(true)
	end

	if E.db.layoutSet then
		E:SetupLayout(E.db.layoutSet, true)
	end
end

function E:ResetUI(...)
	if InCombatLockdown() then E:Print(ERR_NOT_IN_COMBAT) return end

	if ... == '' or ... == ' ' or ... == nil then
		E:StaticPopup_Show('RESETUI_CHECK')
		return
	end

	E:ResetMovers(...)
end

do
	local function errorhandler(err)
		return _G.geterrorhandler()(err)
	end

	function E:CallLoadFunc(func, ...)
		xpcall(func, errorhandler, ...)
	end
end

function E:CallLoadedModule(obj, silent, object, index)
	local name, func
	if type(obj) == 'table' then name, func = unpack(obj) else name = obj end
	local module = name and E:GetModule(name, silent)

	if not module then return end
	if func and type(func) == 'string' then
		E:CallLoadFunc(module[func], module)
	elseif func and type(func) == 'function' then
		E:CallLoadFunc(func, module)
	elseif module.Initialize then
		E:CallLoadFunc(module.Initialize, module)
	end

	if object and index then object[index] = nil end
end

function E:RegisterInitialModule(name, func)
	E.RegisteredInitialModules[#E.RegisteredInitialModules + 1] = (func and {name, func}) or name
end

function E:RegisterModule(name, func)
	if E.initialized then
		E:CallLoadedModule((func and {name, func}) or name)
	else
		E.RegisteredModules[#E.RegisteredModules + 1] = (func and {name, func}) or name
	end
end

function E:InitializeInitialModules()
	for index, object in ipairs(E.RegisteredInitialModules) do
		E:CallLoadedModule(object, true, E.RegisteredInitialModules, index)
	end
end

function E:InitializeModules()
	for index, object in ipairs(E.RegisteredModules) do
		E:CallLoadedModule(object, true, E.RegisteredModules, index)
	end
end

local function buffwatchConvert(spell)
	if spell.sizeOverride then spell.sizeOverride = nil end
	if spell.size then spell.size = nil end

	if not spell.sizeOffset then
		spell.sizeOffset = 0
	end

	if spell.styleOverride then
		spell.style = spell.styleOverride
		spell.styleOverride = nil
	elseif not spell.style then
		spell.style = 'coloredIcon'
	end
end

local ttModSwap
do -- tooltip convert
	local swap = {ALL = 'HIDE',NONE = 'SHOW'}
	ttModSwap = function(val) return swap[val] end
end

function E:DBConversions()
	--Fix issue where UIScale was incorrectly stored as string
	E.global.general.UIScale = tonumber(E.global.general.UIScale)

	--Not sure how this one happens, but prevent it in any case
	if E.global.general.UIScale <= 0 then
		E.global.general.UIScale = G.general.UIScale
	end

	--Combat & Resting Icon options update
	if E.db.unitframe.units.player.combatIcon ~= nil then
		E.db.unitframe.units.player.CombatIcon.enable = E.db.unitframe.units.player.combatIcon
		E.db.unitframe.units.player.combatIcon = nil
	end
	if E.db.unitframe.units.player.restIcon ~= nil then
		E.db.unitframe.units.player.RestIcon.enable = E.db.unitframe.units.player.restIcon
		E.db.unitframe.units.player.restIcon = nil
	end

	-- [Fader] Combat Fade options for Player
	if E.db.unitframe.units.player.combatfade ~= nil then
		local enabled = E.db.unitframe.units.player.combatfade
		E.db.unitframe.units.player.fader.enable = enabled

		if enabled then -- use the old min alpha too
			E.db.unitframe.units.player.fader.minAlpha = 0
		end

		E.db.unitframe.units.player.combatfade = nil
	end

	-- [Fader] Range check options for Units
	do
		local outsideAlpha
		if E.db.unitframe.OORAlpha ~= nil then
			outsideAlpha = E.db.unitframe.OORAlpha
			E.db.unitframe.OORAlpha = nil
		end

		for _, unit in pairs({ 'target', 'targettarget', 'targettargettarget', 'pet', 'pettarget', 'party', 'raid', 'raid40', 'raidpet', 'tank', 'assist' }) do
			if E.db.unitframe.units[unit].rangeCheck ~= nil then
				local enabled = E.db.unitframe.units[unit].rangeCheck
				E.db.unitframe.units[unit].fader.enable = enabled
				E.db.unitframe.units[unit].fader.range = enabled

				if outsideAlpha then
					E.db.unitframe.units[unit].fader.minAlpha = outsideAlpha
				end

				E.db.unitframe.units[unit].rangeCheck = nil
			end
		end
	end

	--Convert old "Buffs and Debuffs" font size option to individual options
	if E.db.auras.fontSize then
		local fontSize = E.db.auras.fontSize
		E.db.auras.buffs.countFontSize = fontSize
		E.db.auras.buffs.durationFontSize = fontSize
		E.db.auras.debuffs.countFontSize = fontSize
		E.db.auras.debuffs.durationFontSize = fontSize
		E.db.auras.fontSize = nil
	end

	--Remove stale font settings from Cooldown system for top auras
	if E.db.auras.cooldown.fonts then
		E.db.auras.cooldown.fonts = nil
	end

	--Convert Nameplate Aura Duration to new Cooldown system
	if E.db.nameplates.durationFont then
		E.db.nameplates.cooldown.fonts.font = E.db.nameplates.durationFont
		E.db.nameplates.cooldown.fonts.fontSize = E.db.nameplates.durationFontSize
		E.db.nameplates.cooldown.fonts.fontOutline = E.db.nameplates.durationFontOutline

		E.db.nameplates.durationFont = nil
		E.db.nameplates.durationFontSize = nil
		E.db.nameplates.durationFontOutline = nil
	end

	if E.db.nameplates.lowHealthThreshold > 0.8 then
		E.db.nameplates.lowHealthThreshold = 0.8
	end

	if E.db.nameplates.units.TARGET.nonTargetTransparency ~= nil then
		E.global.nameplate.filters.ElvUI_NonTarget.actions.alpha = E.db.nameplates.units.TARGET.nonTargetTransparency * 100
		E.db.nameplates.units.TARGET.nonTargetTransparency = nil
	end

	do
		for _, unit in pairs({ 'PLAYER', 'FRIENDLY_PLAYER', 'ENEMY_PLAYER', 'FRIENDLY_NPC', 'ENEMY_NPC'}) do
			if E.db.nameplates.units[unit].buffs and E.db.nameplates.units[unit].buffs.filters ~= nil then
				E.db.nameplates.units[unit].buffs.minDuration = E.db.nameplates.units[unit].buffs.filters.minDuration or P.nameplates.units[unit].buffs.minDuration
				E.db.nameplates.units[unit].buffs.maxDuration = E.db.nameplates.units[unit].buffs.filters.maxDuration or P.nameplates.units[unit].buffs.maxDuration
				E.db.nameplates.units[unit].buffs.priority = E.db.nameplates.units[unit].buffs.filters.priority or P.nameplates.units[unit].buffs.priority
				E.db.nameplates.units[unit].buffs.filters = nil
			end
			if E.db.nameplates.units[unit].debuffs and E.db.nameplates.units[unit].debuffs.filters ~= nil then
				E.db.nameplates.units[unit].debuffs.minDuration = E.db.nameplates.units[unit].debuffs.filters.minDuration or P.nameplates.units[unit].debuffs.minDuration
				E.db.nameplates.units[unit].debuffs.maxDuration = E.db.nameplates.units[unit].debuffs.filters.maxDuration or P.nameplates.units[unit].debuffs.maxDuration
				E.db.nameplates.units[unit].debuffs.priority = E.db.nameplates.units[unit].debuffs.filters.priority or P.nameplates.units[unit].debuffs.priority
				E.db.nameplates.units[unit].debuffs.filters = nil
			end
		end
	end

	if E.db.nameplates.units.TARGET.scale ~= nil then
		E.global.nameplate.filters.ElvUI_Target.actions.scale = E.db.nameplates.units.TARGET.scale
		E.db.nameplates.units.TARGET.scale = nil
	end

	--Convert cropIcon to tristate
	local cropIcon = E.db.general.cropIcon
	if type(cropIcon) == 'boolean' then
		E.db.general.cropIcon = (cropIcon and 2) or 0
	end

	--Vendor Greys option is now in bags table
	if E.db.general.vendorGrays ~= nil then
		E.db.bags.vendorGrays.enable = E.db.general.vendorGrays
		E.db.general.vendorGraysDetails = nil
		E.db.general.vendorGrays = nil
	end

	--Heal Prediction is now a table instead of a bool
	for _, unit in pairs({'player','target','pet','party','raid','raid40','raidpet'}) do
		if type(E.db.unitframe.units[unit].healPrediction) ~= 'table' then
			local enabled = E.db.unitframe.units[unit].healPrediction
			E.db.unitframe.units[unit].healPrediction = {}
			E.db.unitframe.units[unit].healPrediction.enable = enabled
		end
	end

	--Health Backdrop Multiplier
	if E.db.unitframe.colors.healthmultiplier ~= nil then
		if E.db.unitframe.colors.healthmultiplier > 0.75 then
			E.db.unitframe.colors.healthMultiplier = 0.75
		else
			E.db.unitframe.colors.healthMultiplier = E.db.unitframe.colors.healthmultiplier
		end

		E.db.unitframe.colors.healthmultiplier = nil
	end

	--Tooltip FactionColors Setting
	for i = 1, 8 do
		local oldTable = E.db.tooltip.factionColors[''..i]
		if oldTable then
			local newTable = E:CopyTable({}, P.tooltip.factionColors[i]) -- import full table
			E.db.tooltip.factionColors[i] = E:CopyTable(newTable, oldTable)
			E.db.tooltip.factionColors[''..i] = nil
		end
	end

	--v11 Nameplates Reset
	if not E.db.v11NamePlateReset and E.private.nameplates.enable then
		local styleFilters = E:CopyTable({}, E.db.nameplates.filters)
		E.db.nameplates = E:CopyTable({}, P.nameplates)
		E.db.nameplates.filters = E:CopyTable({}, styleFilters)
		NamePlates:CVarReset()
		E.db.v11NamePlateReset = true
	end

	-- Wipe some old variables off profiles
	if E.global.uiScaleInformed then E.global.uiScaleInformed = nil end
	if E.global.nameplatesResetInformed then E.global.nameplatesResetInformed = nil end
	if E.global.userInformedNewChanges1 then E.global.userInformedNewChanges1 = nil end

	-- cvar nameplate visibility stuff
	if E.db.nameplates.visibility.nameplateShowAll ~= nil then
		E.db.nameplates.visibility.showAll = E.db.nameplates.visibility.nameplateShowAll
		E.db.nameplates.visibility.nameplateShowAll = nil
	end
	if E.db.nameplates.units.FRIENDLY_NPC.showAlways ~= nil then
		E.db.nameplates.visibility.friendly.npcs = E.db.nameplates.units.FRIENDLY_NPC.showAlways
		E.db.nameplates.units.FRIENDLY_NPC.showAlways = nil
	end
	if E.db.nameplates.units.FRIENDLY_PLAYER.minions ~= nil then
		E.db.nameplates.visibility.friendly.minions = E.db.nameplates.units.FRIENDLY_PLAYER.minions
		E.db.nameplates.units.FRIENDLY_PLAYER.minions = nil
	end
	if E.db.nameplates.units.ENEMY_NPC.minors ~= nil then
		E.db.nameplates.visibility.enemy.minus = E.db.nameplates.units.ENEMY_NPC.minors
		E.db.nameplates.units.ENEMY_NPC.minors = nil
	end
	if E.db.nameplates.units.ENEMY_PLAYER.minions ~= nil or E.db.nameplates.units.ENEMY_NPC.minions ~= nil then
		E.db.nameplates.visibility.enemy.minions = E.db.nameplates.units.ENEMY_PLAYER.minions or E.db.nameplates.units.ENEMY_NPC.minions
		E.db.nameplates.units.ENEMY_PLAYER.minions = nil
		E.db.nameplates.units.ENEMY_NPC.minions = nil
	end

	-- removed override stuff from aurawatch
	for _, spells in pairs(E.global.unitframe.buffwatch) do
		for _, spell in pairs(spells) do
			buffwatchConvert(spell)
		end
	end
	for _, spell in pairs(E.db.unitframe.filters.buffwatch) do
		buffwatchConvert(spell)
	end

	-- fix aurabars colors
	local auraBarColors = E.global.unitframe.AuraBarColors
	for spell, info in pairs(auraBarColors) do
		if type(spell) == 'string' then
			local spellID = select(7, GetSpellInfo(spell))
			if spellID and not auraBarColors[spellID] then
				auraBarColors[spellID] = info
				auraBarColors[spell] = nil
				spell = spellID
			end
		end

		if type(info) == 'boolean' then
			auraBarColors[spell] = { color = { r = 1, g = 1, b = 1 }, enable = info }
		elseif type(info) == 'table' then
			if info.r or info.g or info.b then
				auraBarColors[spell] = { color = { r = info.r or 1, g = info.g or 1, b = info.b or 1 }, enable = true }
			elseif info.color then -- azil created a void hole, delete it -x-
				if info.color.color then info.color.color = nil end
				if info.color.enable then info.color.enable = nil end
				if info.color.a then info.color.a = nil end -- alpha isnt supported by this
			end
		end
	end

	if E.db.unitframe.colors.debuffHighlight.blendMode == 'MOD' then
		E.db.unitframe.colors.debuffHighlight.blendMode = P.unitframe.colors.debuffHighlight.blendMode
	end

	do -- tooltip modifier code was dumb, change it but keep the past setting
		local swap = ttModSwap(E.db.tooltip.modifierID)
		if swap then E.db.tooltip.modifierID = swap end

		swap = ttModSwap(E.db.tooltip.visibility.bags)
		if swap then E.db.tooltip.visibility.bags = swap end

		swap = ttModSwap(E.db.tooltip.visibility.unitFrames)
		if swap then E.db.tooltip.visibility.unitFrames = swap end

		swap = ttModSwap(E.db.tooltip.visibility.actionbars)
		if swap then E.db.tooltip.visibility.actionbars = swap end

		swap = ttModSwap(E.db.tooltip.visibility.combatOverride)
		if swap then E.db.tooltip.visibility.combatOverride = swap end

		-- remove the old combat variable and just use the mod since it supports show/hide states
		local hideInCombat = E.db.tooltip.visibility.combat
		if hideInCombat ~= nil then
			E.db.tooltip.visibility.combat = nil

			local override = E.db.tooltip.visibility.combatOverride
			if hideInCombat and (override ~= 'SHIFT' and override ~= 'CTRL' and override ~= 'ALT') then -- wouldve been NONE but now it would be HIDE
				E.db.tooltip.visibility.combatOverride = 'HIDE'
			end
		end
	end

	if E.global.unitframe.DebuffHighlightColors then
		E.global.unitframe.AuraHighlightColors = E:CopyTable(E.global.unitframe.AuraHighlightColors, E.global.unitframe.DebuffHighlightColors)
		E.global.unitframe.DebuffHighlightColors = nil
	end
end

function E:RefreshModulesDB()
	-- this function is specifically used to reference the new database
	-- onto the unitframe module, its useful dont delete! D:
	twipe(UnitFrames.db) --old ref, dont need so clear it
	UnitFrames.db = E.db.unitframe --new ref
end

do
	-- Shamelessly taken from AceDB-3.0 and stripped down by Simpy
	function E:CopyDefaults(dest, src)
		for k, v in pairs(src) do
			if type(v) == 'table' then
				if not rawget(dest, k) then rawset(dest, k, {}) end
				if type(dest[k]) == 'table' then E:CopyDefaults(dest[k], v) end
			elseif rawget(dest, k) == nil then
				rawset(dest, k, v)
			end
		end
	end

	function E:RemoveDefaults(db, defaults)
		setmetatable(db, nil)

		for k, v in pairs(defaults) do
			if type(v) == 'table' and type(db[k]) == 'table' then
				E:RemoveDefaults(db[k], v)
				if next(db[k]) == nil then db[k] = nil end
			elseif db[k] == defaults[k] then
				db[k] = nil
			end
		end
	end
end

function E:Initialize()
	twipe(E.db)
	twipe(E.global)
	twipe(E.private)

	E.myguid = UnitGUID('player')
	E.data = E.Libs.AceDB:New('ElvDB', E.DF, true)
	E.data.RegisterCallback(E, 'OnProfileChanged', 'StaggeredUpdateAll')
	E.data.RegisterCallback(E, 'OnProfileCopied', 'StaggeredUpdateAll')
	E.data.RegisterCallback(E, 'OnProfileReset', 'OnProfileReset')
	E.charSettings = E.Libs.AceDB:New('ElvPrivateDB', E.privateVars)
	E.charSettings.RegisterCallback(E, 'OnProfileChanged', ReloadUI)
	E.charSettings.RegisterCallback(E, 'OnProfileReset', 'OnPrivateProfileReset')
	E.private = E.charSettings.profile
	E.global = E.data.global
	E.db = E.data.profile

	E:DBConversions()
	E:UIScale()
	E:BuildPrefixValues()
	E:LoadAPI()
	E:LoadCommands()
	E:InitializeModules()
	E:RefreshModulesDB()
	E:LoadMovers()
	E:UpdateMedia()
	E:UpdateCooldownSettings('all')
	E:Tutorials()
	E.initialized = true

	if E.db.general.smoothingAmount and (E.db.general.smoothingAmount ~= 0.33) then
		E:SetSmoothingAmount(E.db.general.smoothingAmount)
	end

	if not E.private.install_complete then
		E:Install()
	end

	if E:HelloKittyFixCheck() then
		E:HelloKittyFix()
	end

	if E.db.general.kittys then
		E:CreateKittys()
		E:Delay(5, E.Print, E, L["Type /hellokitty to revert to old settings."])
	end

	if GetCVarBool('scriptProfile') then
		E:StaticPopup_Show('SCRIPT_PROFILE')
	end

	if E.db.general.loginmessage then
		local msg = format(L["LOGIN_MSG"], E.version)
		if Chat.Initialized then msg = select(2, Chat:FindURL('CHAT_MSG_DUMMY', msg)) end
		print(msg)
		print(L["LOGIN_MSG_HELP"])
	end
end
