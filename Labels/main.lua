local Log = IMP_PVP_UI_Logger('IMP_ISL')

local EVENT_NAMESPACE = 'IMP_ISL_EVENT_NAMESPACE'

local PI = math.pi
local Object = LibImplex.Marker._3DStatic
local Vector = LibImplex.Vector

local HEIGHT = 450
local SCALE = 1

local ALLIANCE

-- ----------------------------------------------------------------------------
local KEEP_ID_TO_DISTRICT_NAME = {
    [141] = 'Nobles',
    [142] = 'Memorial',
    [143] = 'Arboretum',
    [146] = 'Arena',
    [147] = 'Temple',
    [148] = 'Elven\nGardens',
}

local DISTRICT_LADDERS = {
    [3] = {
        ['Arboretum']   = {{4475.43, 13352, 155940.81},        {0, 0.75 * PI, 0, true}},
        ['Temple']      = {{4414.21, 13352, 154322.96},        {0, 0.25 * PI, 0, true}},
        ['Nobles']      = {{5910.60, 13352, 154189.31},        {0, 0.00 * PI, 0, true}},
        ['Elven\nGardens']={{6175.10, 13352, 154701.49},  {0, 1.50 * PI, 0, true}},
        ['Memorial']    = {{6177.06, 13352, 155529.24},        {0, 1.50 * PI, 0, true}},
        ['Arena']       = {{5808.02, 13352, 156012.89},        {0, 1.00 * PI, 0, true}},
    },
    [2] = {
        ['Arboretum']   = {{166340.68, 11179, 21422.42},       {0, 0.50 * PI, 0, true}},
        ['Temple']      = {{166846.57, 11179, 20972.04},       {0, 0.00 * PI, 0, true}},
        ['Nobles']      = {{167732.30, 11179, 20981.23},       {0, 0.00 * PI, 0, true}},
        ['Elven\nGardens']={{167738.94, 11179, 22792.80}, {0, 1.00 * PI, 0, true}},
        ['Memorial']    = {{166836.60, 11179, 22796.48},       {0, 1.00 * PI, 0, true}},
        ['Arena']       = {{166341.71, 11179, 22326.58},       {0, 0.50 * PI, 0, true}},
    },
    [1] = {
        ['Arboretum']   = {{273615.09, 12850, 180038.41},      {0, 0.23 * PI, 0, true}},
        ['Temple']      = {{275242.71, 12850, 179970.38},      {0, 1.74 * PI, 0, true}},
        ['Nobles']      = {{275361.16, 12850, 181472.99},      {0, 1.50 * PI, 0, true}},
        ['Elven\nGardens']={{274850.06, 12850, 181737.74},{0, 1.00 * PI, 0, true}},
        ['Memorial']    = {{274020.06, 12850, 181708.23},      {0, 1.00 * PI, 0, true}},
        ['Arena']       = {{273539.26, 12850, 181370.65},      {0, 0.50 * PI, 0, true}},
    }
}

-- ----------------------------------------------------------------------------

local LADDERS_LABELS = {}

local ALLIANCE_COLOR = {}
do
    for allianceId = 1, 3 do
        ALLIANCE_COLOR[allianceId] = {GetAllianceColor(allianceId):UnpackRGBA()}
        ALLIANCE_COLOR[allianceId][4] = 0.75
    end
    ALLIANCE_COLOR[0] = {1, 1, 1, 0.75}
end

-- ----------------------------------------------------------------------------

local function getLocalizedDistrictNameV1(keepId)
    return KEEP_ID_TO_DISTRICT_NAME[keepId]
end

local function getLocalizedDistrictNameV2(keepId)
    return zo_strformat(SI_TOOLTIP_KEEP_NAME, GetKeepName(keepId))
end

local getLocalizedDistrictName = getLocalizedDistrictNameV1

-- ----------------------------------------------------------------------------

local function DrawLadderLabel(keepId)
    -- Log('Drawing ladder label for keepId %d', keepId)

    local districtName = KEEP_ID_TO_DISTRICT_NAME[keepId]  -- TODO: refactor with full localization support

    local alliance = GetKeepAlliance(keepId, BGQUERY_LOCAL)
    local color = ALLIANCE_COLOR[alliance]
    local ladderData = DISTRICT_LADDERS[ALLIANCE][districtName]

    -- Log('Keep allianceId: %d, color: %.4f %.4f %.4f', alliance, color[1], color[2], color[3])

    local text = LibImplex.Text(
        getLocalizedDistrictName(keepId),
        CENTER,
        Vector(ladderData[1]) + {0, HEIGHT, 0},
        ladderData[2],
        0.56 * SCALE,
        color
    )

    text:Render()

    return text
end

local function DrawUnderAttackBackground(districtIcon)
    local underAttackBackground = Object(
        districtIcon:GetRelativePointCoordinates(CENTER, 0, 0, -1),
        districtIcon.orientation,
        'EsoUI/Art/MapPins/AvA_attackBurst_64.dds',
        {1.5, 1.5}  -- TODO: districtIcon.size
    )
    underAttackBackground.control:SetDrawLevel(999)
    underAttackBackground.control:SetAlpha(0.25)

    return underAttackBackground
end

local function DrawDistrictIcon(text)
    -- Log('Drawing icon')

    local districtIcon = Object(
        text:GetRelativePointCoordinates(TOP, 0, 30, 2),
        text.orientation,
        'EsoUI/Art/MapPins/AvA_imperialDistrict_Neutral.dds',
        {1.5, 1.5},
        text.color
    )
    districtIcon.control:SetDrawLevel(1000)

    -- Log(districtIcon.control)

    return districtIcon
end

local keepIdSeen = {}

local function DrawLadderLabels()
    for k, _ in pairs(keepIdSeen) do
        keepIdSeen[k] = false
    end

    local i = 0
    for keepIndex = 1, GetNumKeeps() do
        local keepId, battlegroundContext = GetKeepKeysByIndex(keepIndex)
        -- Log('index: %d, id: %d, context: %d, name: %s', keepIndex, keepId, battlegroundContext, GetKeepName(keepId))
        if battlegroundContext == BGQUERY_LOCAL then
            if not keepIdSeen[keepId] then
                keepIdSeen[keepId] = true
                local districtName = KEEP_ID_TO_DISTRICT_NAME[keepId]

                if districtName then
                    i = i + 1
                    local text = DrawLadderLabel(keepId)
                    local districtIcon = DrawDistrictIcon(text)

                    local isUnderAttack = GetKeepUnderAttack(keepId, BGQUERY_LOCAL)

                    local underAttackBackground
                    if isUnderAttack then
                        underAttackBackground = DrawUnderAttackBackground(districtIcon)
                    end

                    LADDERS_LABELS[keepId] = {
                        text = text,
                        districtIcon = districtIcon,
                        underAttackBackground = underAttackBackground,
                    }
                end
            end
        end
    end
    Log('%d labels drawn', i)
end

local function ClearLadderLabels()
    for i, label in pairs(LADDERS_LABELS) do
        if label.text then
            label.text:Delete()
            label.text = nil
        end

        if label.districtIcon then
            Log('Deleting district icon')
            label.districtIcon:Delete()
            label.districtIcon = nil
        end

        if label.underAttackBackground then
            label.underAttackBackground:Delete()
            label.underAttackBackground = nil
        end

        LADDERS_LABELS[i] = nil
    end
end

local function RegisterEvents()
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_KEEP_UNDER_ATTACK_CHANGED, function(_, keepId, battlegroundContext, underAttack)
        if battlegroundContext ~= BGQUERY_LOCAL then return end

        local label = LADDERS_LABELS[keepId]
        if not label then return end

        if label.underAttackBackground then
            label.underAttackBackground:Delete()
            label.underAttackBackground = nil
        end

        if underAttack then
            label.underAttackBackground = DrawUnderAttackBackground(label.districtIcon)
        end
    end)

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_KEEP_ALLIANCE_OWNER_CHANGED, function(_, keepId, battlegroundContext, owningAlliance, oldOwningAlliance)
        if battlegroundContext ~= BGQUERY_LOCAL then return end

        local label = LADDERS_LABELS[keepId]
        if not label then return end

        local allianceColor = ALLIANCE_COLOR[owningAlliance]

        if label.text then
            label.text:SetColor(allianceColor)
        end

        if label.districtIcon then
            label.districtIcon.control:SetColor(unpack(allianceColor))
        end

        local underAttack = GetKeepUnderAttack(keepId, BGQUERY_LOCAL)

        if label.underAttackBackground and not underAttack then
            label.underAttackBackground:Delete()
            label.underAttackBackground = nil
        end
    end)
end

local V2_LOCALIZATION = {
    -- ['en'] = true,
    ['de'] = true,
    -- ['fr'] = true,
    -- ['es'] = true,
    -- ['ru'] = true,
    -- ['jp'] = false,
    -- ['zh'] = false,
}

local IN_SEWERS
local function OnPlayerActivated()
    local inSewers = GetZoneId(GetUnitZoneIndex('player')) == 643
    if inSewers == IN_SEWERS then return end

    ALLIANCE = GetUnitAlliance('player')

    if not inSewers then
        ClearLadderLabels()

        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_KEEP_UNDER_ATTACK_CHANGED)
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_KEEP_ALLIANCE_OWNER_CHANGED)

        return
    end

    if V2_LOCALIZATION[GetCVar("language.2")] then
        getLocalizedDistrictName = getLocalizedDistrictNameV2
    end

    DrawLadderLabels()
    RegisterEvents()
end

-- ----------------------------------------------------------------------------

function IMP_ISL_ScaleLabels(scale)
    for _, label in pairs(LADDERS_LABELS) do
        label.text:SetSize(0.56 * scale)
    end
end

function IMP_ISL_ChangeHeight(newHeight)
    HEIGHT = newHeight
    ClearLadderLabels()
    DrawLadderLabels()
end

function IMP_ISL_Initialize(sv)
    SCALE = sv.scale or SCALE
    HEIGHT = sv.height or HEIGHT

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_KEEPS_INITIALIZED, function()
        Log('!!! Keeps initialized')
    end)
end
