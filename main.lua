local addon = {}
addon.name = 'ImprovedPvPUI'
addon.displayName = '|c7c42f2Imp|ceeeeee-roved PvP UI|r'
addon.version = '0.1.0b1'

local Log = IMP_PVP_UI_Logger('IMP_PVP_UI_MAIN')

local DEFAULTS = {
	beautifulCampaignsManager = {
		enabled = false,
	},
}

function addon:OnLoad()
	Log('Loading %s v%s', self.name, self.version)

	local sv = ZO_SavedVars:NewAccountWide('IMP_PVP_UI_SV', 1, nil, DEFAULTS)

	IMP_PVP_UI_InitializeSettings(addon.name .. 'Settings', addon.displayName, sv)

	if sv.beautifulCampaignsManager.enabled then
		IMP_BCB_Initialize(sv.beautifulCampaignsManager)
	end
end

local function OnAddonLoaded(_, addonName)
	if addonName ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon:OnLoad()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)