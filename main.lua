local addon = {}
addon.name = 'ImprovedPvPUI'
addon.displayName = '|c7c42f2Imp|ceeeeee-roved PvP UI|r'
addon.version = '1.5.6'

local Log = IMP_PVP_UI_Logger('IMP_PVP_UI_MAIN')

local LKT = LibKeepTooltip

local DEFAULTS = {
	beautifulCampaignsManager = {
		enabled = false,
		showIcereach = false,
		showTooltip = false,
		showBonuses = false,
		autotransfer = false,
	},
	keepTooltip = {
		enabled = false,
		siegeTimer = false,
		resourcesLevels = false,
		continuousUpdate = false,
		guildOwner = true,
		hideResourceGuildOwner = false,
		tracker = false,
	},
	battleVictories = {
		compact = false,
	},
	imprialSewersLabels = {
		enabled = true,
		scale = 1,
		height = 450,
	},
	imprialSewersBankedTelvarsLabels = {
		enabled = true,
	}
}

function addon:OnLoad()
	Log('Loading %s v%s', self.name, self.version)

	local sv = ZO_SavedVars:NewAccountWide('IMP_PVP_UI_SV', 1, nil, DEFAULTS)

	IMP_PVP_UI_InitializeSettings(addon.name .. 'Settings', addon.displayName, sv)

	if sv.beautifulCampaignsManager.enabled then
		IMP_BCB_Initialize(sv.beautifulCampaignsManager)
	end

	if sv.keepTooltip.enabled then
		Log('Keep tooltip enabled')
		IMP_KT_Initialize()

		if sv.keepTooltip.siegeTimer then
			Log('Siege timer enabled')
			IMP_KT_SiegeTimer_Initialize()
		end

		if sv.keepTooltip.resourcesLevels then
			Log('Resources levels enabled')
			IMP_KT_ResourcesLevels_Initialize()
		end

		if sv.keepTooltip.continuousUpdate then
			Log('Continuous update enabled')
			IMP_KT_EnableContinuousTooltipUpdate()
		end

		if sv.keepTooltip.guildOwner then
			if sv.keepTooltip.hideResourceGuildOwner then
				local OldAddGuildOwnerLine = LKT:GetIngridientCallback(LKT.INGRIDIENTS.GUILD_OWNER)
				LKT:ReplaceIngridient(LKT.INGRIDIENTS.GUILD_OWNER, function(tooltip)
					if tooltip.keepType == KEEPTYPE_RESOURCE then return end
					OldAddGuildOwnerLine(tooltip)
				end)
			end
		else
			LKT:ReplaceIngridient(LKT.INGRIDIENTS.GUILD_OWNER, function() end)
		end

		if sv.keepTooltip.tracker then
			IMP_KT_EnableTracker()
		end
	end

	if sv.battleVictories.compact then
		IMP_BV_InitializeCompactTooltip()
	end

	if sv.imprialSewersLabels.enabled then
		Log('Labels enabled')
		IMP_ISL_Initialize(sv.imprialSewersLabels)
	end

	if sv.imprialSewersBankedTelvarsLabels.enabled then
		Log('Banked telvars labels enabled')
		IMP_ISBT_Initialize(sv.imprialSewersBankedTelvarsLabels)
	end

	if IMP_IngameBugreports then
		local function callback(error)
        	return error.errorString
		end

		IMP_IngameBugreports:Subscribe(self.name, 'metaclass', callback, function() end)
	end
end

local function OnAddonLoaded(_, addonName)
	if addonName ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon:OnLoad()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)