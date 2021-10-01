local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule('Skins')

local _G = _G
local unpack = unpack

function S:Blizzard_TalentUI()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.talent) then return end

	--local TalentFrame = _G.TalentFrame
	local TalentFrame = _G.PlayerTalentFrame
	S:HandleFrame(TalentFrame, true, nil, 11, -12, -32, 76)

	S:HandleCloseButton(_G.PlayerTalentFrameCloseButton, TalentFrame.backdrop)

	_G.PlayerTalentFrameCancelButton:Kill()

	for i = 1, 5 do
		S:HandleTab(_G['PlayerTalentFrameTab'..i])
	end

	_G.PlayerTalentFrameScrollFrame:StripTextures()
	_G.PlayerTalentFrameScrollFrame:CreateBackdrop('Default')

	S:HandleScrollBar(_G.PlayerTalentFrameScrollFrameScrollBar)
	_G.PlayerTalentFrameScrollFrameScrollBar:Point('TOPLEFT', _G.PlayerTalentFrameScrollFrame, 'TOPRIGHT', 10, -16)

	_G.PlayerTalentFrameSpentPoints:Point('TOP', 0, -42)
	_G.PlayerTalentFrameTalentPointsText:Point('BOTTOMRIGHT', TalentFrame, 'BOTTOMLEFT', 220, 84)

	for i = 1, _G.MAX_NUM_TALENTS do
		local talent = _G['PlayerTalentFrameTalent'..i]
		local icon = _G['PlayerTalentFrameTalent'..i..'IconTexture']
		local rank = _G['PlayerTalentFrameTalent'..i..'Rank']

		if talent then
			talent:StripTextures()
			talent:SetTemplate('Default')
			talent:StyleButton()

			icon:SetInside()
			icon:SetTexCoord(unpack(E.TexCoords))
			icon:SetDrawLayer('ARTWORK')

			rank:SetFont(E.LSM:Fetch('font', E.db['general'].font), 12, 'OUTLINE')
		end
	end
end

S:AddCallbackForAddon('Blizzard_TalentUI')
