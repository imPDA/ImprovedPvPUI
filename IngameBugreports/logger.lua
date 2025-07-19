local dummyLogger = setmetatable({}, {
    __index = function()
        return function() end
    end
})

if LibDebugLogger then
    IMP_IngameBugreports_Logger = LibDebugLogger('IngameBugreports')
    IMP_IngameBugreports_Logger:SetMinLevelOverride(LibDebugLogger.LOG_LEVEL_DEBUG)
else
    IMP_IngameBugreports_Logger = dummyLogger
end
