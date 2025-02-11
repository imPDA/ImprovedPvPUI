local addon = {}

local MISSING_ICON = '/esoui/art/icons/icon_missing.dds'
-- local ROOT_PATH = '/esoui/art/mappins/'  -- '/esoui/art/compass/'
local ROOT_PATH = 'ImprovedPvPUI/icons/'

local KEEP_ICONS = {
    [KEEPTYPE_KEEP] = ROOT_PATH .. 'ava_largekeep_neutral.dds',
    [KEEPTYPE_TOWN] = ROOT_PATH .. 'ava_town_neutral.dds',
    [KEEPTYPE_OUTPOST] = ROOT_PATH .. 'ava_outpost_neutral.dds',
}

local RESOURCE_ICONS = {
    [RESOURCETYPE_FOOD] = ROOT_PATH .. 'ava_farm_neutral.dds',
    [RESOURCETYPE_ORE] = ROOT_PATH .. 'ava_mine_neutral.dds',
    [RESOURCETYPE_WOOD] = ROOT_PATH .. 'ava_lumbermill_neutral.dds',
}

function addon.GetKeepIcon(keepId, alliance, size)
    local texture
    local keepType = GetKeepType(keepId)

    if keepType == KEEPTYPE_RESOURCE then
        local resourceType = GetKeepResourceType(keepId)
        texture = RESOURCE_ICONS[resourceType]
    else
        texture = KEEP_ICONS[keepType]
    end

    if not texture then return MISSING_ICON end
    size = size or 32

    return GetAllianceColor(alliance):Colorize(zo_iconFormatInheritColor(texture, size, size))
end

function addon.SecondsToTime(seconds)
	local minutes = math.floor(seconds / 60) % 60
	local hours = math.floor(seconds / 60 / 60)

	local remainingSeconds = seconds % 60

	if hours == 0 then
		return string.format('%d:%02d', minutes, remainingSeconds)
	else
		return string.format('%d:%02d:%02d', hours, minutes, remainingSeconds)
	end
end

IMP_PVP_UI_SHARED = addon