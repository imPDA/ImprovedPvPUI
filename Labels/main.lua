local Log = IMP_PVP_UI_Logger('IMP_ISL')

local EVENT_NAMESPACE = 'IMP_ISL_EVENT_NAMESPACE'

local PI = math.pi
local Object = LibImplex.Marker._3D
local Vector = LibImplex.Vector

-- ----------------------------------------------------------------------------

local HEIGHT = 450
local SCALE = 1

local ALLIANCE

-- this may fail one day, iteration over district indicies would be better
-- but because of duplication, indicie iteration also requires huge workaround
-- this implementation just faster and simpler at this point
local IC_DISTRICTS = {141, 142, 143, 146, 147, 148}

local SHORT_EN_NAMES = {
    [141] = 'Nobles',
    [142] = 'Memorial',
    [143] = 'Arboretum',
    [146] = 'Arena',
    [147] = 'Temple',
    [148] = 'Elven Gardens',
}

local DISTRICT_LADDERS = {
    [3] = {
        [141] = {{5910.60, 13352, 154189.31}, 0.00},
        [142] = {{6177.06, 13352, 155529.24}, 1.50},
        [143] = {{4475.43, 13352, 155940.81}, 0.75},
        [146] = {{5808.02, 13352, 156012.89}, 1.00},
        [147] = {{4414.21, 13352, 154322.96}, 0.25},
        [148] = {{6175.10, 13352, 154701.49}, 1.50},
    },
    [2] = {
        [141] = {{167732.30, 11179, 20981.23}, 0.00},
        [142] = {{166836.60, 11179, 22796.48}, 1.00},
        [143] = {{166340.68, 11179, 21422.42}, 0.50},
        [146] = {{166341.71, 11179, 22326.58}, 0.50},
        [147] = {{166846.57, 11179, 20972.04}, 0.00},
        [148] = {{167738.94, 11179, 22792.80}, 1.00},
    },
    [1] = {
        [141] = {{274020.06, 12850, 181708.23}, 1.00},
        [142] = {{275361.16, 12850, 181472.99}, 1.50},
        [143] = {{273615.09, 12850, 180038.41}, 0.23},
        [146] = {{273539.26, 12850, 181370.65}, 0.50},
        [147] = {{275242.71, 12850, 179970.38}, 1.74},
        [148] = {{274850.06, 12850, 181737.74}, 1.00},
    }
}

local ALLIANCE_COLOR = {}
do
    for allianceId = 1, 3 do
        ALLIANCE_COLOR[allianceId] = {GetAllianceColor(allianceId):UnpackRGBA()}
        ALLIANCE_COLOR[allianceId][4] = 0.75
    end
    ALLIANCE_COLOR[0] = {1, 1, 1, 0.75}
end

-- ----------------------------------------------------------------------------

local function getLocalizedDistrictNames_EN_short(keepId)
    return SHORT_EN_NAMES[keepId]
end

local function getLocalizedDistrictNames_auto(keepId)
    return zo_strformat(SI_TOOLTIP_KEEP_NAME, GetKeepName(keepId))
end

local LOCALIZATIONS = {
    ['default'] = getLocalizedDistrictNames_EN_short,
    ['auto'] = getLocalizedDistrictNames_auto,
    ['de_special'] = function(keepId)
        if keepId == 143 then return 'Arboretum' end
        return getLocalizedDistrictNames_auto(keepId)
    end,
}

local ALLOWED_LANGUAGES = {
    ['en'] = true,
    ['de'] = true,
}

local getLocalizedDistrictName = function(...) error('MUST CHANGE') end

-- ----------------------------------------------------------------------------

local LADDERS_LABELS = {}

local function DrawLadderLabel(keepId)
    local ladderData = DISTRICT_LADDERS[ALLIANCE][keepId]

    local text = LibImplex.Text(
        getLocalizedDistrictName(keepId),
        CENTER,
        Vector(ladderData[1]) + {0, HEIGHT, 0},
        {0, ladderData[2] * PI, 0, true},
        0.56 * SCALE,
        nil,
        600,  -- maxWidth
        false,
        LibImplex.Text.OBJECT_FACTORIES.Object
    )

    text:Render()

    return text
end

local function DrawDistrictIcon(text)
    local districtIcon = Object(
        text:GetRelativePointCoordinates(TOP, 0, 30, 2),
        text.orientation,
        'EsoUI/Art/MapPins/AvA_imperialDistrict_Neutral.dds',
        {1.5, 1.5}
    )
    districtIcon:SetDrawLevel(1000)

    return districtIcon
end

local function DrawUnderAttackBackground(districtIcon)
    local underAttackBackground = Object(
        districtIcon:GetRelativePointCoordinates(CENTER, 0, 0, -1),
        districtIcon.orientation,
        'EsoUI/Art/MapPins/AvA_attackBurst_64.dds',
        {1.5, 1.5}  -- TODO: districtIcon.size
    )
    underAttackBackground:SetDrawLevel(999)
    underAttackBackground:SetAlpha(0.25)

    return underAttackBackground
end

local function setLabelUnderAttack(label, isUnderAttack)
    label.underAttackBackground:SetHidden(not isUnderAttack)
end

local function setLabelColor(label, color)
    label.text:SetColor(color)
    label.districtIcon:SetColor(unpack(color))
end

local function DrawEverything()
    for i = 1, 6 do
        local keepId = IC_DISTRICTS[i]

        local text = DrawLadderLabel(keepId)
        local districtIcon = DrawDistrictIcon(text)

        local label = {
            text = text,
            districtIcon = districtIcon,
            underAttackBackground = DrawUnderAttackBackground(districtIcon),
        }
        LADDERS_LABELS[keepId] = label

        local alliance = GetKeepAlliance(keepId, BGQUERY_LOCAL)
        if alliance > 0 then
            local color = ALLIANCE_COLOR[alliance]
            setLabelColor(label, color)
        end

        local isUnderAttack = GetKeepUnderAttack(keepId, BGQUERY_LOCAL)
        setLabelUnderAttack(label, isUnderAttack)
    end
end

local function ClearEverything()
    for i, label in pairs(LADDERS_LABELS) do
        if label ~= nil then
            label.text:Delete()
            label.text = nil

            label.districtIcon:Delete()
            label.districtIcon = nil

            label.underAttackBackground:Delete()
            label.underAttackBackground = nil

            LADDERS_LABELS[i] = nil
        end
    end
end

-- ----------------------------------------------------------------------------

local function withChecks(func)
    local function inner(_, keepId, battlegroundContext, ...)
        if battlegroundContext ~= BGQUERY_LOCAL then return end

        local label = LADDERS_LABELS[keepId]
        if not label then return end

        return func(label, keepId, battlegroundContext, ...)
    end

    return inner
end

local EVENT_HANDLERS = {
    [EVENT_KEEP_UNDER_ATTACK_CHANGED] = withChecks(function(label, keepId, battlegroundContext, underAttack)
        setLabelUnderAttack(label, underAttack)
    end),
    [EVENT_KEEP_ALLIANCE_OWNER_CHANGED] = withChecks(function(label, keepId, battlegroundContext, owningAlliance, oldOwningAlliance)
        local allianceColor = ALLIANCE_COLOR[owningAlliance]
        setLabelColor(label, allianceColor)
    end),
    --[[
    [EVENT_KEEP_INITIALIZED] = withChecks(function(label, keepId, battlegroundContext)
        local alliance = GetKeepAlliance(keepId, BGQUERY_LOCAL)

        local allianceColor = ALLIANCE_COLOR[alliance]
        setLabelColor(label, allianceColor)

        local isUnderAttack = GetKeepUnderAttack(keepId, BGQUERY_LOCAL)
        setLabelUnderAttack(label, isUnderAttack)
    end)
    --]]
    [EVENT_KEEPS_INITIALIZED] = function(_)
        for keepId, label in pairs(LADDERS_LABELS) do
            if label then
                local alliance = GetKeepAlliance(keepId, BGQUERY_LOCAL)
                local allianceColor = ALLIANCE_COLOR[alliance]
                setLabelColor(label, allianceColor)

                local isUnderAttack = GetKeepUnderAttack(keepId, BGQUERY_LOCAL)
                setLabelUnderAttack(label, isUnderAttack)
            end
        end
    end
}

local function RegisterEvents()
    for event, handler in pairs(EVENT_HANDLERS) do
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, event, handler)
    end
end

local function UnregisterEvents()
    for event, _ in pairs(EVENT_HANDLERS) do
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, event)
    end
end

local IN_SEWERS
local function OnPlayerActivated()
    local inSewers = GetZoneId(GetUnitZoneIndex('player')) == 643
    if inSewers == IN_SEWERS then return end

    ALLIANCE = GetUnitAlliance('player')

    if not inSewers then
        ClearEverything()
        UnregisterEvents()
        return
    end

    DrawEverything()
    RegisterEvents()
end

-- ----------------------------------------------------------------------------

function IMP_ISL_ScaleLabels(scale)
    SCALE = scale

    for _, label in pairs(LADDERS_LABELS) do
        label.text:SetSize(0.56 * scale)

        if label.districtIcon then
            label.districtIcon:Move(label.text:GetRelativePointCoordinates(TOP, 0, 30, 2))
        end
    end
end

function IMP_ISL_ChangeHeight(newHeight)
    HEIGHT = newHeight
    ClearEverything()
    DrawEverything()
end

function IMP_ISL_Initialize(sv)
    SCALE = sv.scale or SCALE
    HEIGHT = sv.height or HEIGHT

    getLocalizedDistrictName = LOCALIZATIONS['default']
    if ALLOWED_LANGUAGES[GetCVar("language.2")] then
        Log('Language: %s, localization: %s', GetCVar("language.2"), sv.localization)
        local localizationFunc = LOCALIZATIONS[sv.localization]
        if localizationFunc then
            getLocalizedDistrictName = localizationFunc
        end
    end

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end
