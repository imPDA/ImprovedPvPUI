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
            tooltip = 'COME AND FIGHT!',
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
                {
                    type = 'checkbox',
                    name = 'Show tooltip',
                    getFunc = function() return sv.beautifulCampaignsManager.showTooltip end,
                    setFunc = function(value) sv.beautifulCampaignsManager.showTooltip = value end,
                    requiresReload = true,
                },
                {
                    type = 'checkbox',
                    name = '[EXPERIMENTAL] Show bonuses',
                    getFunc = function() return sv.beautifulCampaignsManager.showBonuses end,
                    setFunc = function(value) sv.beautifulCampaignsManager.showBonuses = value end,
                    requiresReload = true,
                },
                {
                    type = 'checkbox',
                    name = '[EXPERIMENTAL] Autotransfer',
                    getFunc = function() return sv.beautifulCampaignsManager.autotransfer end,
                    setFunc = function(value) sv.beautifulCampaignsManager.autotransfer = value end,
                    requiresReload = true,
                },
            },
        },
        {
            type = 'submenu',
            name = 'Keep Tooltip',
            -- tooltip = 'To go Cyrodiil or Imperial City',
            controls = {
                {
                    type = 'checkbox',
                    name = 'Enable',
                    getFunc = function() return sv.keepTooltip.enabled end,
                    setFunc = function(value) sv.keepTooltip.enabled = value end,
                    requiresReload = true,
                },
                {
                    type = 'checkbox',
                    name = 'Add tracker',
                    getFunc = function() return sv.keepTooltip.tracker end,
                    setFunc = function(value) sv.keepTooltip.tracker = value end,
                    requiresReload = true,
                },
                {
                    type = 'checkbox',
                    name = 'Add siege timer',
                    getFunc = function() return sv.keepTooltip.siegeTimer end,
                    setFunc = function(value) sv.keepTooltip.siegeTimer = value end,
                    requiresReload = true,
                },
                {
                    type = 'checkbox',
                    name = 'Add resources levels',
                    getFunc = function() return sv.keepTooltip.resourcesLevels end,
                    setFunc = function(value) sv.keepTooltip.resourcesLevels = value end,
                    requiresReload = true,
                },
                {
                    type = 'checkbox',
                    name = 'Update tooltip once per second',
                    getFunc = function() return sv.keepTooltip.continuousUpdate end,
                    setFunc = function(value) sv.keepTooltip.continuousUpdate = value end,
                    requiresReload = true,
                    tooltip = 'By default, tooltip updated only on MouseIn and MouseOut, enables update every second while mouse over any keep',
                },
                {
                    type = 'checkbox',
                    name = 'Show guild owner',
                    getFunc = function() return sv.keepTooltip.guildOwner end,
                    setFunc = function(value) sv.keepTooltip.guildOwner = value end,
                    requiresReload = true,
                },
                {
                    type = 'checkbox',
                    name = 'Hide resource guild owner',
                    getFunc = function() return sv.keepTooltip.hideResourceGuildOwner end,
                    setFunc = function(value) sv.keepTooltip.hideResourceGuildOwner = value end,
                    requiresReload = true,
                },
            },
        },
        {
            type = 'submenu',
            name = 'Battle Victories',
            tooltip = 'Customize Battle Victories (crossed swords on map, also known as kill locations)',
            controls = {
                {
                    type = 'checkbox',
                    name = 'Compact',
                    getFunc = function() return sv.battleVictories.compact end,
                    setFunc = function(value) sv.battleVictories.compact = value end,
                    requiresReload = true,
                },
            },
        },
        {
            type = 'submenu',
            name = 'Labels in IC Sewers',
            -- tooltip = '',
            controls = {
                {
                    type = 'checkbox',
                    name = 'Enable',
                    getFunc = function() return sv.imprialSewersLabels.enabled end,
                    setFunc = function(value) sv.imprialSewersLabels.enabled = value end,
                    requiresReload = true,
                },
                {
                    type = 'dropdown',
                    name = 'Localization',
                    tooltip = [[
Addon Default - Short EN names (without "District").

Ingame Default - Full names in the chosen language (for EN and DE only, for now).

DE (Arboretum) - Same as "Ingame Default," but "Baumgartenbezirk" is replaced with "Arboretum".
                    ]],
                    choices = {'Addon Default', 'Ingame Default', 'DE (Arboretum)'},
                    choicesValues = {'default', 'auto', 'de_special'},
                    getFunc = function() return sv.imprialSewersLabels.localization end,
                    setFunc = function(var) sv.imprialSewersLabels.localization = var end,
                    width = 'full',
                    warning = 'Will need to reload the UI',
                    requiresReload = true,
                },
                {
                    type = 'slider',
                    name = 'Text size (district names)',
                    getFunc = function() return sv.imprialSewersLabels.scale * 100 end,
                    setFunc = function(value)
                        sv.imprialSewersLabels.scale = value / 100
                        IMP_ISL_ScaleLabels(value / 100)
                    end,
                    min = 50,
                    max = 150,
                },
                {
                    type = 'slider',
                    name = 'Text height (district names)',
                    getFunc = function() return sv.imprialSewersLabels.height end,
                    setFunc = function(value)
                        sv.imprialSewersLabels.height = value
                        IMP_ISL_ChangeHeight(value)
                    end,
                    min = 100,
                    max = 1000,
                },
                {
                    type = 'checkbox',
                    name = 'Show banked Tel Vars',
                    getFunc = function() return sv.imprialSewersBankedTelvarsLabels.enabled end,
                    setFunc = function(value) sv.imprialSewersBankedTelvarsLabels.enabled = value end,
                    requiresReload = true,
                },
            },
        },
    }

    LAM:RegisterOptionControls(settingsName, optionsData)
end

function IMP_PVP_UI_InitializeSettings(...)
    addon:Initialize(...)
end