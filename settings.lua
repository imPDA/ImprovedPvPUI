local addon = {}

local LAM = LibAddonMenu2

function addon:Initialize(settingsName, settingsDisplayName, sv)
    local panelData = {
        type = 'panel',
        name = settingsDisplayName,
        author = '@impda',
    }

    local panel = LAM:RegisterAddonPanel(settingsName, panelData)

    local optionsData = {
        {
            type = 'submenu',
            name = 'Beautiful Campaigns Manager',
            tooltip = 'To go Cyrodiil or Imperial City',
            controls = {
                {
                    type = 'checkbox',
                    name = 'Enable',
                    getFunc = function() return sv.beautifulCampaignsManager.enabled end,
                    setFunc = function(value) sv.beautifulCampaignsManager.enabled = value end,
                    requiresReload = true,
                },
                {
                    type = 'checkbox',
                    name = 'Always show Icereach',
                    getFunc = function() return sv.beautifulCampaignsManager.showIcereach end,
                    setFunc = function(value) sv.beautifulCampaignsManager.showIcereach = value end,
                    requiresReload = true,
                    tooltip = 'Icereach is "below 50" campaign and will be hidden for characters level 50 and above. Turn ON to show it all the time insted.'
                },
            },
        },
    }

    LAM:RegisterOptionControls(settingsName, optionsData)
end

function IMP_PVP_UI_InitializeSettings(...)
    addon:Initialize(...)
end