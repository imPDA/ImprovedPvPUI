local addon = {}
IMP_GLOBAL_KEEP_TRACKER = addon
local EVENT_NAMESPACE = 'IMP_IPU_KT_NAMESPACE'

-- local SIEGES_DEFAULT_WIDTH = 48
local CONTAINER = IMP_IPU_KT_TLC

local Log = IMP_PVP_UI_Logger('KeepTracker')

local formatSeconds = IMP_PVP_UI_SHARED.SecondsToTime

-- ----------------------------------------------------------------------------

function addon:Initialize(sv)
    Log('Initialization')

    local playerAlliance = GetUnitAlliance('player')
    local zoneIndex = nil

    local keeps = {}
    local keepsLit = {}
    local capturedKeeps = {}

    self.playerAlliance = playerAlliance

    self.keeps = keeps
    self.keepsLit = keepsLit
    self.capturedKeeps = capturedKeeps

    self.timers = {}

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, function(_)
        if not IsInAvAZone() then
            self:Deactivate()
            return
        end

        local currentZoneIndex = GetUnitZoneIndex('player')
        if zoneIndex ~= currentZoneIndex then
            zoneIndex = currentZoneIndex
            self:Activate()
        end

        ZO_ClearNumericallyIndexedTable(keeps)
        for keepIndex = 1, GetNumKeeps() do
            local keepId, bgContext = GetKeepKeysByIndex(keepIndex)
            if bgContext == BGQUERY_LOCAL then
                keeps[#keeps+1] = keepId
            end
        end

        -- TODO: sort keeps

        for i = 1, #keeps do
            local keepId = keeps[i]
            local isUnderAttack = GetKeepUnderAttack(keepId, BGQUERY_LOCAL)
            local keepAlliance = GetKeepAlliance(keepId, BGQUERY_LOCAL)

            keepsLit[keepId] = isUnderAttack
            capturedKeeps[keepId] = keepAlliance == playerAlliance
        end
    end)

    local pool = ZO_ControlPool:New('IMP_IPU_KT_RowTemplate', CONTAINER)
    pool:SetCustomFactoryBehavior(function(objectBeingCreated, objectKey, pool_)
        objectBeingCreated.compositeIcon = objectBeingCreated:GetNamedChild('CompositeIcon')
        objectBeingCreated.name = objectBeingCreated:GetNamedChild('KeepName')
        objectBeingCreated.timer = objectBeingCreated:GetNamedChild('Timer')
        objectBeingCreated.background = objectBeingCreated:GetNamedChild('Background')
        objectBeingCreated.sieges = objectBeingCreated:GetNamedChild('Sieges')
    end)

    self.keepIdToControl = {}
    self.pool = pool
end

local allianceHexColor = {}
do
    for alliance = ALLIANCE_ITERATION_BEGIN, ALLIANCE_ITERATION_END do
        allianceHexColor[alliance] = GetAllianceColor(alliance):ToHex()
    end
    allianceHexColor[ALLIANCE_NONE] = GetAllianceColor(ALLIANCE_NONE):ToHex()
end

local siegesTemp = {}
local SIEGES_STRING_TEMPLATE = '|c%s%d|r'
function addon:Activate()
    Log('Activation')

    local keeps = self.keeps
    local keepsLit = self.keepsLit
    local playerAlliance = self.playerAlliance
    local timers = self.timers

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_KEEP_UNDER_ATTACK_CHANGED, function(_, keepId, battlegroundContext, underAttack)
        if battlegroundContext ~= BGQUERY_LOCAL then return end

        keepsLit[keepId] = underAttack
    end)

    EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE, 1000, function()
        local previousControl
        local reanchorNext = false

        local now = GetGameTimeSeconds()

        -- TODO: generate list of keepIds when campaign changed?
        for i = 1, #keeps do
            local keepId = keeps[i]

            local shouldBeListed = false

            if keepsLit[keepId] then
                shouldBeListed = true
            else
                local numSieges = GetNumSieges(keepId, BGQUERY_LOCAL, playerAlliance)
                if numSieges > 0 then
                    shouldBeListed = true
                end
            end

            local control = self.keepIdToControl[keepId]
            if shouldBeListed then
                -- should exist but does not - create, set icon, name and color (static); always update timer
                if not control then
                    timers[keepId] = now
                    control = self:CreateKeepRow(keepId)
                    self:AnchorKeepRow(control, previousControl, CONTAINER)
                    reanchorNext = true
                elseif reanchorNext then
                    self:AnchorKeepRow(control, previousControl, CONTAINER)
                    reanchorNext = false
                end

                previousControl = control

                control.timer:SetText(formatSeconds(now - timers[keepId]))

                ZO_ClearNumericallyIndexedTable(siegesTemp)
                for alliance = ALLIANCE_ITERATION_BEGIN, ALLIANCE_ITERATION_END do
                    local numSieges = GetNumSieges(keepId, BGQUERY_LOCAL, alliance)  -- TODO: second call for num sieges? 

                    if numSieges > 0 then
                        siegesTemp[#siegesTemp+1] = SIEGES_STRING_TEMPLATE:format(allianceHexColor[alliance], numSieges)
                    end
                end

                control.sieges:SetText(table.concat(siegesTemp, ' / '))
            else
                -- should not exist but exists - delete
                if control then
                    control:ReleaseObject()
                    self.keepIdToControl[keepId] = nil
                    reanchorNext = true
                end
            end
        end
    end)
end

function addon:Deactivate()
    return
end

-- local siegesTemp = {}
-- local allianceHexColor = {}
-- do
--     for alliance = ALLIANCE_ITERATION_BEGIN, ALLIANCE_ITERATION_END do
--         allianceHexColor[alliance] = GetAllianceColor(alliance):ToHex()
--     end
--     allianceHexColor[ALLIANCE_NONE] = GetAllianceColor(ALLIANCE_NONE):ToHex()
-- end


-- function addon:UpdateUI()
--     local previousControl
--     local reanchorNext = false

--     local keeps = self.keeps
--     local keepsLit = self.keepsLit
--     local timers = self.timers
--     local now = GetGameTimeSeconds()

--     for i = 1, #keeps do
--         local keepId = keeps[i]

--         if self.masterList[keepId] then
--             local control, key = self.keepIdToControl[keepId], nil

--             if not control then
--                 control = self:CreateKeepRow(keepId)
--                 self:AnchorKeepRow(control, previousControl, CONTAINER)
--                 reanchorNext = true
--             elseif reanchorNext then
--                 self:AnchorKeepRow(control, previousControl, CONTAINER)
--                 reanchorNext = false
--             end

--             previousControl = control

--             local timer = control.timer
--             timer:SetText(formatSeconds(now - timers[keepId]))

--             --[[
--             for alliance = ALLIANCE_ITERATION_BEGIN, ALLIANCE_ITERATION_END do
--                 local siegesControl = control.sieges[alliance]
--                 local sieges = GetNumSieges(keepId, BGQUERY_LOCAL, alliance)
--                 if sieges == 0 then
--                     siegesControl:SetWidth(0)
--                 else
--                     siegesControl:SetWidth(SIEGES_DEFAULT_WIDTH)
--                     siegesControl:SetText(sieges)
--                 end
--             end
--             --]]

--             ZO_ClearNumericallyIndexedTable(siegesTemp)
--             for alliance = ALLIANCE_ITERATION_BEGIN, ALLIANCE_ITERATION_END do
--                 local numSieges = GetNumSieges(keepId, BGQUERY_LOCAL, alliance)  -- TODO: second call for num sieges? 

--                 if numSieges > 0 then
--                     siegesTemp[#siegesTemp+1] = SIEGES_STRING_TEMPLATE:format(allianceHexColor[alliance], numSieges)
--                 end
--             end

--             control.sieges:SetText(table.concat(siegesTemp, ' / '))
--         end
--     end
-- end

function addon:CreateKeepRow(keepId)
    Log('No control for %s yet, creating', GetKeepName(keepId))

    local control, key = self.pool:AcquireObject()
    ZO_PooledObject.OnPooledObjectFactory(control, self.pool, key)
    self.keepIdToControl[keepId] = control

    local keepName = GetKeepName(keepId)
    local keepAlliance = GetKeepAlliance(keepId, BGQUERY_LOCAL)

    local r, g, b, a = GetAllianceColor(keepAlliance):UnpackRGBA()

    IMP_PVP_UI_SHARED.SetCompositeKeepTexture(control.compositeIcon, keepId, self.keepsLit[keepId], r, g, b, a)

    local name = control.name
    name:SetText(zo_strformat(SI_TOOLTIP_KEEP_NAME, keepName))
    name:SetColor(r, g, b, a)

    -- control.background:SetColor(r, g, b, 0.5)
    control.background:SetColor(0, 0, 0, 0.3)

    return control
end

function addon:AnchorKeepRow(control, previousControl, container)
    control:ClearAnchors()  -- TODO: can avoid clearing? Modfiy anchor instead?
    if previousControl then
        control:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT)
    else
        control:SetAnchor(TOPLEFT, container)
    end
end

-- ----------------------------------------------------------------------------

function IMP_KeepTracker_Initialize(sv)
	addon:Initialize(sv)
end
