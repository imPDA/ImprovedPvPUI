local dummyLogger = setmetatable({}, {
    __index = function()
        return function() end
    end
})

IMP_IngameBugreports_Logger = LibDebugLogger and LibDebugLogger('IngameBugreports') or dummyLogger
