local EVENT_NAMESPACE = 'IMP_ISL_EVENT_NAMESPACE'

local PI = math.pi

local HEIGHT = 500
local SCALE = 1

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
        ['Arboretum']   = {{4475.43, 13352 + HEIGHT, 155940.81},        {0 * PI, 0.75 * PI, 0 * PI, true}},
        ['Temple']      = {{4414.21, 13352 + HEIGHT, 154322.96},        {0 * PI, 0.25 * PI, 0 * PI, true}},
        ['Nobles']      = {{5910.60, 13352 + HEIGHT, 154189.31},        {0 * PI, 0.00 * PI, 0 * PI, true}},
        ['Elven\nGardens']={{6175.10, 13352 + HEIGHT + 80, 154701.49},   {0 * PI, 1.50 * PI, 0 * PI, true}},
        ['Memorial']    = {{6177.06, 13352 + HEIGHT, 155529.24},        {0 * PI, 1.50 * PI, 0 * PI, true}},
        ['Arena']       = {{5808.02, 13352 + HEIGHT, 156012.89},        {0 * PI, 1.00 * PI, 0 * PI, true}},
    },
    [2] = {
        ['Arboretum']   = {{166340.68, 11179 + HEIGHT, 21422.42},       {0 * PI, 0.50 * PI, 0 * PI, true}},
        ['Temple']      = {{166846.57, 11179 + HEIGHT, 20972.04},       {0 * PI, 0.00 * PI, 0 * PI, true}},
        ['Nobles']      = {{167732.30, 11179 + HEIGHT, 20981.23},       {0 * PI, 0.00 * PI, 0 * PI, true}},
        ['Elven\nGardens']={{167738.94, 11179 + HEIGHT + 80, 22792.80},  {0 * PI, 1.00 * PI, 0 * PI, true}},
        ['Memorial']    = {{166836.60, 11179 + HEIGHT, 22796.48},       {0 * PI, 1.00 * PI, 0 * PI, true}},
        ['Arena']       = {{166341.71, 11179 + HEIGHT, 22326.58},       {0 * PI, 0.50 * PI, 0 * PI, true}},
    },
    [1] = {
        ['Arboretum']   = {{273615.09, 12850 + HEIGHT, 180038.41},      {0 * PI, 0.23 * PI, 0 * PI, true}},
        ['Temple']      = {{275242.71, 12850 + HEIGHT, 179970.38},      {0 * PI, 1.74 * PI, 0 * PI, true}},
        ['Nobles']      = {{275361.16, 12850 + HEIGHT, 181472.99},      {0 * PI, 1.50 * PI, 0 * PI, true}},
        ['Elven\nGardens']={{274850.06, 12850 + HEIGHT + 80, 181737.74}, {0 * PI, 1.00 * PI, 0 * PI, true}},
        ['Memorial']    = {{274020.06, 12850 + HEIGHT, 181708.23},      {0 * PI, 1.00 * PI, 0 * PI, true}},
        ['Arena']       = {{273539.26, 12850 + HEIGHT, 181370.65},      {0 * PI, 0.50 * PI, 0 * PI, true}},
    }
}

local LABELS = {}

local function AddLabels()
    local allianceId = GetUnitAlliance('player')

    local laddersData = DISTRICT_LADDERS[allianceId]

    local labels = {}

    for keepIndex = 1, GetNumKeeps() do
        local keepId = GetKeepKeysByIndex(keepIndex)

        local districtName = KEEP_ID_TO_DISTRICT_NAME[keepId]

        if districtName then
            local keepAllianceColor = {GetAllianceColor(GetKeepAlliance(keepId, BGQUERY_LOCAL)):UnpackRGBA()}
            keepAllianceColor[4] = 0.75

            local ladderData = laddersData[districtName]

            local text = LibImplex.Text(districtName)

            text:Anchor(TOP, ladderData[1])
            text:SetSize(0.56 * SCALE)
            text:Orient(ladderData[2])
            text:SetColor(keepAllianceColor)
            -- text:SetMaxWidth(900 * SCALE + 40)

            text:Render()

            local districtMarker = LibImplex.Marker._3DStatic(
                LibImplex.Vector(text.position) + {0, 30, 0} + text.f * 2,
                text.orientation,
                'EsoUI/Art/MapPins/AvA_imperialDistrict_Neutral.dds',
                {1.5, 1.5},
                keepAllianceColor
            )
            districtMarker.control:SetDrawLevel(1000)

            local underAttackBackground
            local isUnderAttack = GetKeepUnderAttack(keepId, BGQUERY_LOCAL)
            if isUnderAttack then
                underAttackBackground = LibImplex.Marker._3DStatic(
                    districtMarker.position - text.f,
                    text.orientation,
                    'EsoUI/Art/MapPins/AvA_attackBurst_64.dds',
                    {1.5, 1.5}
                )
                underAttackBackground.control:SetDrawLevel(999)
                underAttackBackground.control:SetAlpha(0.25)
            end

            labels[#labels+1] = {text, districtMarker}

            LABELS[keepId] = {
                text = text,
                districtMarker = districtMarker,
                underAttackBackground = underAttackBackground,
            }
        end
    end

    GLOBAL_LABELS = labels
end

local ZONE_ID
local function OnPlayerActivated()
    local zoneId = GetZoneId(GetUnitZoneIndex('player'))

    if zoneId == ZONE_ID then return end
    ZONE_ID = zoneId

    if zoneId ~= 643 then
        for _, label in pairs(LABELS) do
            label.text:Delete()
            label.districtMarker:Delete()
            if label.underAttackBackground then
                label.underAttackBackground:Delete()
            end
        end
        return
    end

    AddLabels()

    -- TODO: DRY
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_KEEP_UNDER_ATTACK_CHANGED, function(_, keepId, battlegroundContext, underAttack)
        if battlegroundContext ~= BGQUERY_LOCAL then return end

        local label = LABELS[keepId]

        if underAttack then
            local underAttackBackground = LibImplex.Marker._3DStatic(
                label.districtMarker.position - label.text.f,
                label.text.orientation,
                'EsoUI/Art/MapPins/AvA_attackBurst_64.dds',
                {1.5, 1.5}
            )
            underAttackBackground.control:SetDrawLevel(999)
            underAttackBackground.control:SetAlpha(0.25)

            label.underAttackBackground = underAttackBackground
        else
            if label.underAttackBackground then
                label.underAttackBackground:Delete()
                label.underAttackBackground = nil
            end
        end
    end)

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_KEEP_ALLIANCE_OWNER_CHANGED, function(_, keepId, battlegroundContext, owningAlliance, oldOwningAlliance)
        if battlegroundContext ~= BGQUERY_LOCAL then return end

        local label = LABELS[keepId]

        local keepAllianceColor = {GetAllianceColor(owningAlliance):UnpackRGBA()}
        keepAllianceColor[4] = 0.75

        label.text:SetColor(keepAllianceColor)
        label.districtMarker.control:SetColor(unpack(keepAllianceColor))
    end)
end

-- ----------------------------------------------------------------------------

function IMP_ISL_ScaleLabels(scale)
    for _, label in pairs(LABELS) do
        label.text:SetSize(0.56 * scale)
    end
end

function IMP_ISL_Initialize(sv)
    SCALE = sv.scale or 1
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end
