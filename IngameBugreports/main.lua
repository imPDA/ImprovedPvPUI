local EVENT_NAMESPACE = 'IngameBugreports'
local SV_NAME = 'IngameBugreportsSavedVariables'
local GUILD_ID = 849674

local LAM = LibAddonMenu2

-- ----------------------------------------------------------------------------

local addon = {}
addon.name = 'IngameBugreports'
addon.displayName = 'Ingame Bugreports'

local DEFAULTS = {
    enabled = true,
    ack = false,
}

-- ----------------------------------------------------------------------------

-- local Log = function(...) end
local Log = df

-- ----------------------------------------------------------------------------

local MailBox = _G_IMP_class()

local EXTERNAL_PROCESS = '_e'

function MailBox:__init()
    -- TOSO: can detect initial state?
    self.opened = false

    self.registry = {}

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_MAIL_CLOSE_MAILBOX, function()
        self.opened = false
        Log('MailBox closed')

        if next(self.registry) ~= nil then
            Log('MailBox was closed, but there are still processes running!')
        end
    end)

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_MAIL_OPEN_MAILBOX, function()
        self.opened = true
        Log('MailBox opened')
    end)

    self.__RequestOpenMailbox = RequestOpenMailbox
    self.__CloseMailbox = CloseMailbox

    -- ZO_PreHook(_G, 'RequestOpenMailbox', function() return self:Open(GLOBAL_PROCESS) end)
    -- ZO_PreHook(_G, 'CloseMailbox', function() return self:Close(GLOBAL_PROCESS) end)

    RequestOpenMailbox = function() self:Open(EXTERNAL_PROCESS) end
    CloseMailbox = function() self:Close(EXTERNAL_PROCESS) end
    -- TODO: probably better in my particular case...
end

function MailBox:Open(process)
    self.registry[process] = true

    self:__open()
    return true
end

function MailBox:__open()
    if self.opened then return end
    self.__RequestOpenMailbox()
end

function MailBox:Close(process)
    self.registry[process] = nil

    self:__close()
    return true
end

function MailBox:__close()
    if not self.opened then return end

    if next(self.registry) == nil then
        self.__CloseMailbox()
    end
end

local MAILBOX = MailBox()

-- ----------------------------------------------------------------------------

local function split(inputstr, sep)
    if sep == nil then
        sep = '%s'
    end

    local t = {}

    for str in string.gmatch(inputstr, '([^'..sep..']+)') do
        t[#t+1] = str
    end

    return t
end

local function trim(s)
    return s:match('^%s*(.-)%s*$')
end

local function parseTable(s)
    local result = {}

    s = s:match('^%[table:%d+%]{(.*)}$')

    if not s then return end

    local inString, currentKey, currentValue, buffer = false, nil, nil, ''
    local depth = 0

    for i = 1, #s do
        local c = s:sub(i, i)
        if c == '"' or c == "'" then
            inString = not inString
            buffer = buffer .. c
        elseif not inString then
            if c == '{' then
                depth = depth + 1
                buffer = buffer .. c
            elseif c == '}' then
                depth = depth - 1
                buffer = buffer .. c
            elseif c == '=' and depth == 0 then
                currentKey = trim(buffer)
                buffer = ''
            elseif c == ',' and depth == 0 then
                currentValue = trim(buffer)
                if currentKey and currentValue then
                    result[currentKey] = currentValue
                end
                currentKey, currentValue = nil, nil
                buffer = ''
            else
                buffer = buffer .. c
            end
        else
            buffer = buffer .. c
        end
    end

    if currentKey and buffer ~= '' then
        result[currentKey] = trim(buffer)
    end

    return result
end

local function parseLocals(localsStr)
    local variables = {}
    local currentKey, currentValue, buffer = nil, nil, ''
    local depth = 0

    for i = 1, #localsStr do
        local c = localsStr:sub(i, i)
        if c == '{' then
            depth = depth + 1
            buffer = buffer .. c
        elseif c == '}' then
            depth = depth - 1
            buffer = buffer .. c
        elseif c == '=' and depth == 0 then
            currentKey = trim(buffer)
            buffer = ''
        elseif c == ',' and depth == 0 then
            currentValue = trim(buffer)
            if currentKey and currentValue then
                variables[currentKey] = parseTable(currentValue) or currentValue
            end
            currentKey, currentValue = nil, nil
            buffer = ''
        else
            buffer = buffer .. c
        end
    end

    if currentKey and buffer ~= '' then
        currentValue = trim(buffer)
        variables[currentKey] = parseTable(currentValue) or currentValue
    end

    return variables
end

local function printTable(t, indent)
    indent = indent or 0
    for k, v in pairs(t) do
        if type(v) == 'table' then
            print(string.rep('  ', indent) .. k .. ' = {')
            printTable(v, indent + 1)
            print(string.rep('  ', indent) .. '},')
        else
            print(string.rep('  ', indent) .. k .. ' = ' .. tostring(v) .. ',')
        end
    end
end

-- ----------------------------------------------------------------------------

local Sender = _G_IMP_class()  -- TODO: heavy refactoring

local COOLDOWN_DURATION_S = 3

local NOT_READY = 1
local READY = 2

function Sender:__init(sv)
    self.queue = {}
    self.head = 1
    self.tail = 0

    self.outbox = {}

    sv.archive = sv.archive or {index = 0}
    self.archive = sv.archive

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_MAIL_SEND_SUCCESS, function(_, playerName)
        local data = self.queue[self.head-1]

        if not data then
            Log('Empty data')
            return
        end

        if data[1] ~= playerName then
            Log('Somehow these names are not equal!')
            return
        end

        local archiveIndex = self.outbox[data]

        self.archive[archiveIndex] = nil
        self.outbox[data] = nil
    end)

    for index, mail in pairs(self.archive) do
        if index ~= 'index' then
            self.outbox[mail] = index

            self.tail = self.tail + 1
            self.queue[self.tail] = mail
        end
    end

    self.state = READY

    if next(self.outbox) ~= nil then
        MAILBOX:Open('sender')
        self:__startCooldown()
    end

    --[[
    self.numFails = 0
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_MAIL_SEND_FAILED, function(_, reason)
        self.numFails = self.numFails + 1
        if reason == MAIL_SEND_RESULT_FAIL_MAILBOX_FULL then
            Log('----------')
            Log('----------')
            Log('----------')
            Log('---FULL---')
            Log('----------')
            Log('----------')
            Log('----------')
            Logout()
        end

        Log('%d fails', self.numFails)
        if self.numFails >= 10 then
            Log('----------')
            Log('----------')
            Log('----------')
            Log('-10 FAILS-')
            Log('----------')
            Log('----------')
            Log('----------')
            Logout()
        end
    end)
    --]]
end

function Sender:Send(to, subject, body)
    Log('New message to be send!')

    local data = {to, subject, body}

    local next = self.archive.index + 1
    self.archive.index = next

    self.archive[tostring(next)] = data
    self.outbox[data] = tostring(next)

    if self.state == READY then
        MAILBOX:Open('sender')
        self:__send(to, subject, body)
        self:__startCooldown()
    else
        self.tail = self.tail + 1
        self.queue[self.tail] = data
    end
end

function Sender:__startCooldown()
    self.state = NOT_READY
    EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE..'Sender', COOLDOWN_DURATION_S * 1000, function() self:__sendNextMessage() end)
end

function Sender:__endCooldown()
    EVENT_MANAGER:UnregisterForUpdate(EVENT_NAMESPACE..'Sender')
    self.state = READY
end

function Sender:__sendNextMessage()
    if self.head > self.tail then
        self:__endCooldown()
        MAILBOX:Close('sender')
    else
        self:__send(unpack(self.queue[self.head]))
        self.queue[self.head-1] = nil
        -- self.queue[self.head] = nil
        self.head = self.head + 1
    end
end

local MAX_RETRIES = 10
local retries = 0
function Sender:__send(to, subject, body)
    if retries >= MAX_RETRIES then
        retries = 0
        return
    end

    Log('Sending mail!')

    if not MAILBOX.opened then
        Log('MailBox was not opened for sending yet :(')

        zo_callLater(function() self:__send(to, subject, body) end, 50)
        retries = retries + 1

        return
    end

    SendMail(to, subject, body)

    -- TODO: acknowledge sending!
end

-- ----------------------------------------------------------------------------

local NOT_DELETED_BEFORE = {}

local Deleter = _G_IMP_class()

function Deleter:__init()
    self.queue = {}
    self.head = 1
    self.tail = 0

    self.inQueue = {}

    self.running = false

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_DELETE_MAIL_RESPONSE, function(_, mailId, success)
        local mailId_s = Id64ToString(mailId)

        if success then
            Log('[v] %s deleted', mailId_s)

            if NOT_DELETED_BEFORE[mailId_s] then
                Log('[v] %s deleted after %dms', mailId_s, GetGameTimeMilliseconds() - NOT_DELETED_BEFORE[mailId_s])
            end

            self.inQueue[mailId_s] = nil
        else
            Log('[x] %s NOT deleted', mailId_s)
            self:Delete(mailId)

            NOT_DELETED_BEFORE[mailId_s] = GetGameTimeMilliseconds()
        end
    end)
end

function Deleter:Delete(mailId)
    if mailId == nil then return end

    local mailId_s = Id64ToString(mailId)

    if self.inQueue[mailId_s] then return end
    self.inQueue[mailId_s] = true

    self.tail = self.tail + 1
    self.queue[self.tail] = mailId_s

    if not self.running then
        self:__start_loop()
    end
end

function Deleter:__update()
    if not MAILBOX.opened then return end

    if self.head > self.tail then
        return self:__stop_loop()
    end

    local mailId_s = self.queue[self.head]
    self.head = self.head + 1

    if self.inQueue[mailId_s] == nil then
        Log('Trying to queue already deleted mail! %s', mailId_s)
        return self:__update()
    end

    DeleteMail(StringToId64(mailId_s))
end

function Deleter:__start_loop()
    -- Log('Starting loop')
    if self.running then return end

    self.running = true
    MAILBOX:Open('deleter')
    EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE..'Deleter', 200, function()
        -- Log('Update')
        self:__update()
    end)
end

function Deleter:__stop_loop()
    if next(self.inQueue) ~= nil then
        local n = 0
        for mailId_s, _ in pairs(self.inQueue) do
            self.tail = self.tail + 1
            self.queue[self.tail] = mailId_s
            n = n + 1
        end
        Log('There were %d mails still in the queue', n)
        return
    end

    EVENT_MANAGER:UnregisterForUpdate(EVENT_NAMESPACE..'Deleter')
    MAILBOX:Close('deleter')
    self.head = 1
    self.tail = 0

    -- Log('inQueue size: %d', clearAndCount(self.inQueue))
    -- self.inQueue = {}

    self.running = false
    Log('Stopped loop')
end

-- ----------------------------------------------------------------------------

local Reader = _G_IMP_class()

function Reader:__init(callback)
    self.queue = {}
    self.callback = callback

    self.requestedId = nil
    self.lastRequestMs = 0

    self.head = 1
    self.tail = 0

    self.running = false

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_MAIL_READABLE, function(_, mailId)
        if not AreId64sEqual(self.requestedId, mailId) then return end

        self.head = self.head + 1
        self.callback(mailId)
    end)
end

function Reader:Read(mailId)
    self.queue[#self.queue+1] = mailId
    self.tail = self.tail + 1

    if not self.running then
        self:__start_loop()
    end
end

function Reader:__update()
    -- Log('Requested: %s %d ago', tostring(self.requested), GetGameTimeMilliseconds() - self.lastRequestMs)

    if self.requestedId and (GetGameTimeMilliseconds() - self.lastRequestMs <= 100) then return end

    if self.head > self.tail then
        return self:__stop_loop()
    end

    local mailId = self.queue[self.head]
    local queued = self:__queue_reading(mailId)
    if queued then
        self.requestedId = mailId
    end
end

function Reader:__start_loop()
    -- Log('Starting loop')
    if self.running then return end

    self.running = true
    MAILBOX:Open('reader')
    EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE..'Reader', 50, function()
        -- Log('Update')
        self:__update()
    end)
end

function Reader:__stop_loop()
    EVENT_MANAGER:UnregisterForUpdate(EVENT_NAMESPACE..'Reader')
    MAILBOX:Close('reader')
    self.running = false
    -- Log('Stopped loop')
end

function Reader:__queue_reading(mailId)
    if not MAILBOX.opened then return end

    RequestReadMail(mailId)
    self.lastRequestMs = GetGameTimeMilliseconds()

    return true
end

-- ----------------------------------------------------------------------------

local ErrorMessage = _G_IMP_class()

function ErrorMessage:__init(errorString, errorCode)
    self.errorString = errorString
    self.errorCode = errorCode  -- TODO: calculate hash on creation maybe?

    self.msg = ''
    self.stack = nil

    self:__parse()
end

function ErrorMessage:__eq(other)
    if other.__index ~= ErrorMessage then
        error(('Comparison between ErrorMessage and %s is not defined'):format(type(other)))
    end
    return self:Hash() == other:Hash()
end

function ErrorMessage:__parse()
    for line in self.errorString:gmatch('[^\r\n]+') do
        local success, result = pcall(self.__handleLine, self, line)
        if not success then
            Log(result)
        end
    end
end

local function startsWith(str, start)
    return str:find(('^%s'):format(start))
end

function ErrorMessage:__handleLine(line)
    if startsWith(line, 'stack traceback:') then
        self.stack = {}
        return
    end

    if self.stack then
        local depth = #self.stack

        if startsWith(line, '<Locals>') then
            local localsBlock = line:match('<Locals>(.-)</Locals>')

            if not localsBlock then
                error('Locals block parsing error')
            end

            self.stack[depth].rawLocals = localsBlock

            local success, result = pcall(parseLocals, localsBlock)
            if success then
                self.stack[depth].locals = result
            end
        elseif line:find('in function') then
            self.stack[depth+1] = {msg = line}
        elseif line == '(tail call): ?' then
            return  -- ignore it
        else
            error('Unknown route')
        end
    else
        self.msg = self.msg .. line  -- TODO: meh
    end
end

function ErrorMessage:GetFirstStacktraceWithAddon()
    for i = 1, #self.stack do
        local msg = self.stack[i].msg
        if startsWith(msg, 'user:/AddOns') then
            return msg, i
        end
    end
end

function ErrorMessage:GetFirstStacktraceAddonName()
    local msg, i = self:GetFirstStacktraceWithAddon()
    local path = split(msg, '/')

    -- return path[#path-1]
    return path[3]
end

local function djb2(str)
    local hash = 5381

    for i = 1, #str do
        hash = (hash * 33) + str:byte(i)
        hash = hash % 4294967296
    end

    return hash
end

function ErrorMessage:Hash()
    local filePath, funcName = self:GetFirstStacktraceWithAddon():match("^user:/([^:]+:%d+):.+function '([^']+)'")
    return djb2(filePath)
end

IMP_IngameBugreports_ErrorMessage = ErrorMessage

-- ----------------------------------------------------------------------------

function addon:CreateSettings()
    local panelData = {
        type = 'panel',
        name = addon.name,
        displayName	= addon.displayName,
        author = '@imPDA',
        feedback = 'https://www.esoui.com/forums/forumdisplay.php?f=164'
    }

    self.settingsPanel = LAM:RegisterAddonPanel(addon.name, panelData)

    local options = {}

    options[#options+1] = {
        type = 'checkbox',
        name = 'Enabled',
        getFunc = function() return self.sv.enabled end,
        setFunc = function(value) self.sv.enabled = value end,
        requiresReload = true
    }

    options[#options+1] = {
        type = 'description',
        title = 'Description',
        text = [[
This library automatically sends addon bug reports to their respective authors, helping improve addon quality and stability.

|cFF3333If you encounter an error with this addon itself, please disable it and report the issue to @imPDA in-game or on the ESOUI forums. Thank you!|r

Key features:
- Sends in-game mails containing standard bug reports (you may occasionally see "Mail sent to..." messages)
- Only monitors supported addons - |c00CC00authors opt in to add reporting for their addons|r
- Duplicate bug reports are automatically filtered - |c00CC00only one report per unique bug per week|r
- Rate-limited to |c00CC00one mail every 3 seconds|r to prevent spam
- If mail fails to send (due to combat or restrictions), the report is saved and |c00CC00retried after the next reload|r

You can disable it at any time (|cFF3333toggle OFF|r), but keeping it active helps improve addons for everyone.
|c00CC00Thank you for your support!|r
        ]],
    }

    local addons = {}
    for addonName, _ in pairs(self.registry) do
        addons[#addons+1] = ('- %s'):format(addonName)
    end

    options[#options+1] = {
        type = 'description',
        title = 'Addons using this library',
        text = table.concat(addons, '\n'),
    }

    LAM:RegisterOptionControls(addon.name, options)
end
-- ----------------------------------------------------------------------------

function addon:OnLoad(addonName)
    if self.name ~= addonName then return end
    EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_ADD_ON_LOADED)

    -- _G[SV_NAME] = _G[SV_NAME] or {}
    -- self.sv = _G[SV_NAME]
    self.sv = ZO_SavedVars:NewAccountWide(SV_NAME, 1, DEFAULTS)

    self.registry = {}
    self.blacklist = {}

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ADD_ONS_LOADED, function()
        self:Start()
    end)
end

local WARNING_DIALOG = 'IMP_InbameBugreports_Warning'
ESO_Dialogs[WARNING_DIALOG] = {
    mustChoose = true,

    title = {
        text = 'I want to let you know!',
    },

    mainText = {
        text = [[
I am testing "IngameBugreports" library which is currently |c00CC00ENABLED|r. Please take a moment to review its short description on how it works. Your feedback is greatly appreciated!

|c777777This notification will only appear once.|r
        ]]
    },

    buttons = {
        {
            text = '|c00BB00Open description|r',
            callback = function(dialog)
                LAM:OpenToPanel(dialog.data.settingsPanel)
            end
        },
        {
            text = '|c777777Skip|r',
        },
    }
}

function addon:ShowWarning()
    if self.sv.ack then return end
    self.sv.ack = true

    ZO_Dialogs_ShowDialog(WARNING_DIALOG, {settingsPanel = self.settingsPanel})
end

function addon:Start()
    if not self:ShouldStart() then
        Log('No addons in registry, aborting...')
        return
    end

    self:CreateSettings()
    self:ShowWarning()

    Log('Loading %s...', self.displayName)

    local errorsMet = self.sv['errorsMet'] or {}
    self.sv['errorsMet'] = errorsMet

    self.sender = Sender(self.sv)
    self.deleter = Deleter()
    self.reader = Reader()

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_LUA_ERROR, function(_, errorString, errorCode)
        local error = ErrorMessage(errorString, errorCode)
        local hash = error:Hash()

        local lastMetTimestamp = errorsMet[hash]
        local timestamp = GetTimeStamp()

        if lastMetTimestamp and timestamp - lastMetTimestamp <= 60 * 60 * 24 then
            Log('Already met this error recently: %s, abort...', tostring(hash))
            return
        end
        errorsMet[hash] = GetTimeStamp()

        Log('New error met: %s', tostring(hash))

        if not self:ShouldEmitFor(error) then return end

        local data = self.registry[error:GetFirstStacktraceAddonName()]

        self.sender:Send(
            data.recipient,
            ('!!IBR%d'):format(hash),
            -- ('!!IBR%d'):format(math.random(1, 1000000000)),
            data.bodySendCallback(error)
        )
    end)
end

function addon:CreateManager()
    self.manager = IMP_IngameBugreports_Manager(self.reader, self.deleter, self.sv)
end

function addon:SlapManager()  -- TODO: hyaku paasento working method trust me
    self.manager.seen = {}
    self.manager:OnMailInboxUpdate()
end

function addon:ShouldEmitFor(error)
    local firstAddonInStacktrace = error:GetFirstStacktraceAddonName()

    if self.registry[firstAddonInStacktrace] == nil then return end

    local hash = error:Hash()
    if self.blacklist[hash] then
        Log('This error in a stop list, aborting...')
        return
    end

    local remoteBlacklist = split(GetGuildDescription(GUILD_ID), '#')  -- GetGuildMotD(GUILD_ID)
    -- TODO: faster without split
    for i = 1, #remoteBlacklist do
        if tonumber(remoteBlacklist[i]) == hash then
            self.blacklist[hash] = true
            Log('This error in a stop list, aborting...')
            return
        end
    end

    return true
end

function addon:Subscribe(addonName, recipient, bodySendCallback, bodyReadCallback)
    if not addonName then return end
    if not recipient then return end
    if type(bodySendCallback) ~= 'function' then return end
    if type(bodyReadCallback) ~= 'function' then return end

    self.registry[addonName] = {
        recipient = recipient,
        bodySendCallback = bodySendCallback,
        bodyReadCallback = bodyReadCallback,
    }

    return true
end

function addon:ShouldStart()
    if not self.sv.enabled then return end
    if next(self.registry) == nil then return end
    if GetWorldName() ~= 'EU Megaserver' then return end

    return true
end

do
    local ADDON = addon
    IMP_IngameBugreports = ADDON

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ADD_ON_LOADED, function(_, ...) ADDON:OnLoad(...) end)
end

-- TODO: check author
-- EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_MAIL_SEND_FAILED, function(_, reason)
--     if reason == MAIL_SEND_RESULT_CANT_SEND_TO_SELF then
--         ...
--     end
-- end)
