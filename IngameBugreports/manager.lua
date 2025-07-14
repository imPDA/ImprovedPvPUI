local L = IMP_IngameBugreports_Logger
local EVENT_NAMESPACE = '0197febc-ba1e-7dd2-95a1-63be6e0c041f'

-- ----------------------------------------------------------------------------

local function startsWith(str, start)
    return str:find(('^%s'):format(start))
end

-- ----------------------------------------------------------------------------

local Manager = _G_IMP_class()

local function isReport(subject)
    return startsWith(subject, '!!IBR')
end

local function extractSubject(mailId)
    local senderDisplayName, senderCharacterName, subject, firstItemIcon, unread, fromSystem, fromCS, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived, category = GetMailItemInfo(mailId)
    return subject
end

function Manager:__init(reader, deleter, sv)
    self.reader = reader
    self.deleter = deleter

    self.reader.callback = function(mailId_) self:__proceed(mailId_) end

    sv.reports = sv.reports or {}
    self.reports = sv.reports

    self.seen = {}

    -- if sv.settings.autoUpdate then
    if true then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_MAIL_INBOX_UPDATE, function() self:OnMailInboxUpdate() end)
    end
end

function Manager:OnMailInboxUpdate()
    for i = GetNumMailItemsByCategory(MAIL_CATEGORY_PLAYER_MAIL), 1, -1 do
        local mailId = GetMailIdByIndex(MAIL_CATEGORY_PLAYER_MAIL, i)

        local mailIdString = Id64ToString(mailId)
        if self.seen[mailIdString] then return end

        local subject = extractSubject(mailId)
        self.seen[mailIdString] = subject

        if isReport(subject) then
            self:__read(mailId)
        end
    end

    L:Debug('End of mailbox')
end

function Manager:__read(mailId)
    self.reader:Read(mailId)
end

function Manager:__proceed(mailId)
    local subject = extractSubject(mailId)
    local body = ReadMail(mailId)

    -- local mailIdString = Id64ToString(mailId)
    -- local subject = self.seen[mailIdString]

    self:__save(subject, body)

    self.deleter:Delete(mailId)
end

function Manager:__save(subject, body)
    -- TODO: compare body, locals, etc.
    if self.reports[subject] then
        self.reports[subject].counter = self.reports[subject].counter + 1
    else
        self.reports[subject] = {
            counter = 1,
            text = body,
        }
    end
end

IMP_IngameBugreports_Manager = Manager
