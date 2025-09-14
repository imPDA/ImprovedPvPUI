local PI = math.pi
local Object = LibImplex.Marker._3DStatic

local EVENT_NAMESPACE = 'IMP_ISBT_EVENT_NAMESPACE'
local ALLIANCE

-- ----------------------------------------------------------------------------

local function comma_value(n) -- credit http://richard.warburton.it
	local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
	return left .. num:reverse():gsub('(%d%d%d)','%1,'):reverse() .. right
end

-- ----------------------------------------------------------------------------

local BANKS = {
    [3] = {{5264, 13167+355+40, 153583}, {0, 0.00 * PI, 0, true}},
    [2] = {{167277, 11058+355, 24284}, {0, 1.00 * PI, 0, true}},
    [1] = {{270504, 12694+355, 178253}, {0, -0.23 * PI, 0, true}},
}

local TEL_VAR_STONES_LABEL
local TEL_VAR_STONES_ICON

local function DrawTelVarStonesIcon()
    local position = TEL_VAR_STONES_LABEL:GetRelativePointCoordinates(BOTTOMRIGHT, 30, 35+8, 2)

    if TEL_VAR_STONES_ICON then
        TEL_VAR_STONES_ICON:Move(position)
    else
        TEL_VAR_STONES_ICON = Object(
            position,
            TEL_VAR_STONES_LABEL.orientation,
            '/esoui/art/hud/telvar_meter_currency.dds',
            {0.7, 0.7}
        )
    end
end

local function DrawTelVarStonesLabel(telVarStonesAmount)
    local bankData = BANKS[ALLIANCE]

    local value = comma_value(tostring(telVarStonesAmount))

    if TEL_VAR_STONES_LABEL then
        TEL_VAR_STONES_LABEL.text = value
        TEL_VAR_STONES_LABEL:Render()
    else
        TEL_VAR_STONES_LABEL = LibImplex.Text(
            value,
            TOP,
            bankData[1],
            bankData[2],
            1,
            {93 / 255, 163 / 255, 1}
        )
        TEL_VAR_STONES_LABEL:Render()
    end

    DrawTelVarStonesIcon()
end

local function ClearTelVarStonesLabel()
    if TEL_VAR_STONES_LABEL then
        TEL_VAR_STONES_LABEL:Delete()
        TEL_VAR_STONES_LABEL = nil
    end

    if TEL_VAR_STONES_ICON then
        TEL_VAR_STONES_ICON:Delete()
        TEL_VAR_STONES_ICON = nil
    end
end

local IN_SEWERS
local function OnPlayerActivated()
    local inSewers = GetZoneId(GetUnitZoneIndex('player')) == 643
    if inSewers == IN_SEWERS then return end

    ALLIANCE = GetUnitAlliance('player')

    if not inSewers then
        ClearTelVarStonesLabel()

        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_BANKED_CURRENCY_UPDATE)

        return
    end

    DrawTelVarStonesLabel(GetCurrencyAmount(CURT_TELVAR_STONES, CURRENCY_LOCATION_BANK))

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_BANKED_CURRENCY_UPDATE, function(_, currency, newValue, oldValue)
        if currency ~= CURT_TELVAR_STONES then return end
        DrawTelVarStonesLabel(newValue)
    end)
end

function IMP_ISBT_Initialize(sv)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end
