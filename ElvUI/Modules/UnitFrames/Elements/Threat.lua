local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule('UnitFrames');

local unpack = unpack
local CreateFrame = CreateFrame

function UF:Construct_Threat(frame)
	local threat = CreateFrame("Frame", nil, frame)

	--Main ThreatGlow
	threat.MainGlow = frame:CreateShadow(nil, true)
	threat.MainGlow:SetParent(frame)
	threat.MainGlow:Hide()

	--Secondary ThreatGlow, for power frame when using power offset
	threat.PowerGlow = frame:CreateShadow(nil, true)
	threat.PowerGlow:SetParent(frame)
	threat.PowerGlow:SetFrameStrata('BACKGROUND')
	threat.PowerGlow:Hide()

	threat.TextureIcon = threat:CreateTexture(nil, 'OVERLAY')
	threat.TextureIcon:Size(8)
	threat.TextureIcon:SetTexture(E.media.blankTex)
	threat.TextureIcon:Hide()

	threat.PostUpdate = self.UpdateThreat
	return threat
end

function UF:Configure_Threat(frame)
	local threat = frame.ThreatIndicator
	if not threat then return end

	local threatStyle = frame.db and frame.db.threatStyle
	if threatStyle and threatStyle ~= 'NONE' then
		if not frame:IsElementEnabled('ThreatIndicator') then
			frame:EnableElement('ThreatIndicator')
		end

		if threatStyle == "GLOW" then
			threat:SetFrameStrata('BACKGROUND')
			threat.MainGlow:SetFrameStrata('BACKGROUND')
			threat.MainGlow:ClearAllPoints()

			if frame.USE_POWERBAR_OFFSET then
				threat.MainGlow:Point("TOPLEFT", frame.Health.backdrop, "TOPLEFT", -frame.SHADOW_SPACING - frame.SPACING, frame.SHADOW_SPACING + frame.SPACING + (frame.USE_CLASSBAR and (frame.USE_MINI_CLASSBAR and 0 or frame.CLASSBAR_HEIGHT) or 0))
				threat.MainGlow:Point("BOTTOMRIGHT", frame.Health.backdrop, "BOTTOMRIGHT", frame.SHADOW_SPACING + frame.SPACING, -frame.SHADOW_SPACING - frame.SPACING)

				threat.PowerGlow:ClearAllPoints()
				threat.PowerGlow:Point("TOPLEFT", frame.Power.backdrop, "TOPLEFT", -frame.SHADOW_SPACING - frame.SPACING, frame.SHADOW_SPACING + frame.SPACING)
				threat.PowerGlow:Point("BOTTOMRIGHT", frame.Power.backdrop, "BOTTOMRIGHT", frame.SHADOW_SPACING + frame.SPACING, -frame.SHADOW_SPACING - frame.SPACING)
			else
				threat.MainGlow:Point("TOPLEFT", -frame.SHADOW_SPACING, frame.SHADOW_SPACING-(frame.USE_MINI_CLASSBAR and frame.CLASSBAR_YOFFSET or 0))

				if frame.USE_MINI_POWERBAR then
					threat.MainGlow:Point("BOTTOMLEFT", -frame.SHADOW_SPACING, -frame.SHADOW_SPACING + (frame.POWERBAR_HEIGHT/2))
					threat.MainGlow:Point("BOTTOMRIGHT", frame.SHADOW_SPACING, -frame.SHADOW_SPACING + (frame.POWERBAR_HEIGHT/2))
				else
					threat.MainGlow:Point("BOTTOMLEFT", -frame.SHADOW_SPACING, -frame.SHADOW_SPACING)
					threat.MainGlow:Point("BOTTOMRIGHT", frame.SHADOW_SPACING, -frame.SHADOW_SPACING)
				end
			end
		elseif threatStyle:match('^ICON') then
			threat:SetFrameStrata('LOW')
			threat:SetFrameLevel(75) --Inset power uses 50, we want it to appear above that

			local point = threatStyle:gsub("ICON", "")
			threat.TextureIcon:ClearAllPoints()
			threat.TextureIcon:Point(point, frame.Health, point)
		elseif threatStyle == "HEALTHBORDER" and frame.InfoPanel then
			frame.InfoPanel:SetFrameLevel(frame.Health:GetFrameLevel() - 3)
		elseif threatStyle == "INFOPANELBORDER" and frame.InfoPanel then
			frame.InfoPanel:SetFrameLevel(frame.Health:GetFrameLevel() + 3)
		end
	elseif frame:IsElementEnabled('ThreatIndicator') then
		frame:DisableElement('ThreatIndicator')
	end
end

function UF:ThreatBorderColor(backdrop, lock, r, g, b)
	backdrop:SetBackdropBorderColor(r, g, b)
	backdrop.ignoreBorderColors = lock
end

do
	local classPowers = {
		DRUID = 'AdditionalPower',
	}

	local myClassPower = classPowers[E.myclass]
	function UF:ThreatClassBarBorderColor(parent, status, r, g, b)
		local classPower = myClassPower and parent[myClassPower]
		if classPower then UF:ThreatBorderColor(classPower.backdrop, status, r, g, b) end
		if parent.ClassPower then UF:ThreatBorderColor(parent.ClassPower.backdrop, status, r, g, b) end
		if parent.AlternativePower then UF:ThreatBorderColor(parent.AlternativePower.backdrop, status, r, g, b) end
	end
end

function UF:ThreatHandler(threat, parent, threatStyle, status, r, g, b)
	if threatStyle == 'GLOW' then
		if status then
			threat.MainGlow:Show()
			threat.MainGlow:SetBackdropBorderColor(r, g, b)

			if parent.USE_POWERBAR_OFFSET then
				threat.PowerGlow:Show()
				threat.PowerGlow:SetBackdropBorderColor(r, g, b)
			end
		else
			threat.MainGlow:Hide()
			threat.PowerGlow:Hide()
		end
	elseif threatStyle == 'BORDERS' then
		if parent.InfoPanel then UF:ThreatBorderColor(parent.InfoPanel.backdrop, status, r, g, b) end
		if parent.Power then UF:ThreatBorderColor(parent.Power.backdrop, status, r, g, b) end
		UF:ThreatBorderColor(parent.Health.backdrop, status, r, g, b)
		UF:ThreatClassBarBorderColor(parent, status, r, g, b)
	elseif threatStyle == 'HEALTHBORDER' then
		UF:ThreatBorderColor(parent.Health.backdrop, status, r, g, b)
	elseif threatStyle == 'INFOPANELBORDER' then
		if parent.InfoPanel then UF:ThreatBorderColor(parent.InfoPanel.backdrop, status, r, g, b) end
	elseif threatStyle ~= 'NONE' and threat.TextureIcon then
		if status then
			threat.TextureIcon:Show()
			threat.TextureIcon:SetVertexColor(r, g, b)
		else
			threat.TextureIcon:Hide()
		end
	end
end

function UF:UpdateThreat(unit, status, r, g, b)
	local parent = self:GetParent()
	local db = parent.db and parent.db.threatStyle
	local badunit = not unit or parent.unit ~= unit

	if not badunit and status and status > 1 then
		UF:ThreatHandler(self, parent, db, status, r, g, b)
	else
		UF:ThreatHandler(self, parent, db, nil, unpack(E.media.unitframeBorderColor))
	end
end
