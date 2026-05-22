local abs = math.abs
local atan2 = math.atan2
local sqrt = math.sqrt

local EVENT_NAMESPACE = 'IMP_CB_EVENT_NAMESPACE'

-- ----------------------------------------------------------------------------

local addon = {}

function addon:Initialize()
    self.labels = {}
    self.rendered = {}

    self.lastUpdate = 0
    self.onKillLocationsUpdate = function() self:UpdateKillLocations(true) end

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, function()
        if IsInCyrodiil() then
            self:StartListening()
        else
            self:StopListening()
        end
    end)
end

function addon:Clear()
    for _, label in ipairs(self.labels) do
        label:Delete()
    end
    ZO_ClearNumericallyIndexedTable(self.labels)
    ZO_ClearNumericallyIndexedTable(self.rendered)
end

local SIZE = 30
-- local SIZE = 5
local OFFSET = 1500  -- 15m
-- local OFFSET = -500  -- -5m
local MAX_DISPLAY_DISTANCE_MANHATTAN = 25000  -- 250m
local MAX_DISPLAY_DISTANCE_SQ = 70000*70000  -- 700m
local MIN_DISPLAY_DISTANCE_SQ = 15000*15000  -- 80m
function addon:UpdateKillLocations(force)
    if GetCurrentMapId() ~= 16 then return end  -- TODO: can convert n to w, etc.

    local now = GetGameTimeSeconds()
    if not ((now - self.lastUpdate) >= 1 or force) then return end
    self.lastUpdate = now

    self:Clear()

    local _, prw_x, prw_y, prw_z = GetUnitRawWorldPosition('player')
    for i = 1, GetNumKillLocations() do
        local pinData, kn_x, kn_z = GetKillLocationPinInfo(i)
        if (kn_x and kn_z) then
            local krw_x, krw_z = kn_x * 1000000, kn_z * 1000000

            -- TODO: is manhattan distance faster than squared comparison?
            -- if abs(prw_x - krw_x) + abs(prw_z - krw_z) <= MAX_DISPLAY_DISTANCE_MANHATTAN then
            local distanceSq = (prw_x - krw_x)^2 + (prw_z - krw_z)^2
            if (distanceSq <= MAX_DISPLAY_DISTANCE_SQ) and (distanceSq >= MIN_DISPLAY_DISTANCE_SQ) then
                -- df('Distance: %d', sqrt(distanceSq)/100)
                self:DrawKillLocation(i, krw_x, prw_y + OFFSET, krw_z)
            end
        end
    end

    local duration = GetGameTimeSeconds() - now
    -- df('Close battle updated in %.1f us', duration * 1000000)
end

-- local PointToPlayer = LibImplex.System(
--     'pointToPlayer',
--     function(entity)
--         local control = _controls[entity]
--         control:Set3DRenderSpaceForward(fX, fY, fZ)
--         control:Set3DRenderSpaceRight(rX, rY, rZ)

--         entity[ 8], entity[ 9], entity[10] = fX, fY, fZ
--         entity[11], entity[12], entity[13] = rX, rY, rZ
--     end,
--     MEDIUM_PRIORITY
-- )

local alliances = {'AD', 'EP', 'DC'}
function addon:DrawKillLocation(killLocationIndex, rw_x, rw_y, rw_z)
    local kills = {}

    local total = 0
    for alliance = 1, 3 do
        local n = GetNumKillLocationAllianceKills(killLocationIndex, alliance)
        -- if n > 0 then
        --     kills[#kills+1] = ('%s %d'):format(alliances[alliance], n)
        -- end
        kills[alliance] = n
        total = total + n
    end

    if total < 3 then return end

    local text = table.concat(kills, ' - ')
    -- df('Drawing kill location `%s` at (%d, %d, %d)', text, rw_x, rw_y, rw_z)
    local label = LibImplex.Text(text, CENTER, {rw_x, rw_y, rw_z}, {0, 0, 0}, SIZE, {0, 0.75, 1, 0.8})
    -- label:Render()

    self.labels[#self.labels+1] = label
    self.rendered[#self.labels] = false
end

function addon:StartListening()
    EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE, 17, function()
        local _, prw_x, prw_y, prw_z = GetUnitRawWorldPosition('player')
        local P = LibImplex.Vector({prw_x, prw_y, prw_z})
        for i = 1, #self.labels do
            local L = LibImplex.Vector(self.labels[i].position)
            local D = (P - L):unit()
            local x, y, z = D[1], D[2], D[3]

            local yaw = atan2(x, z)
            local pitch = atan2(-y, sqrt(x*x + z*z))
            local roll = 0.0

            if self.rendered[i] then
                -- self.labels[i].position[2] = prw_y + OFFSET
                self.labels[i]:Orient({roll, yaw, pitch})
            else
                self.labels[i]:SetOrientation(roll, yaw, pitch)
                self.labels[i]:Render()
            end
        end
    end)

    EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE..'Periodical Update', 10000, function()
        self:UpdateKillLocations()
    end)

    -- self.onKillLocationsUpdate()
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_KILL_LOCATIONS_UPDATED, self.onKillLocationsUpdate)
end

function addon:StopListening()
    EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_KILL_LOCATIONS_UPDATED)
    EVENT_MANAGER:UnregisterForUpdate(EVENT_NAMESPACE)
    EVENT_MANAGER:UnregisterForUpdate(EVENT_NAMESPACE..'Periodical Update')
end

-- ----------------------------------------------------------------------------
function IMP_CB_Initialize(sv)
    addon:Initialize()
end
