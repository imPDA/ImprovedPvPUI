--#region LOGGER
function IMP_PVP_UI_Logger(name)
    local logger

    if LibDebugLogger then
        logger = LibDebugLogger:Create(name or 'IMP_PVP_UI')
        logger:SetMinLevelOverride(LibDebugLogger.LOG_LEVEL_DEBUG)
    end

    local level = LibDebugLogger.LOG_LEVEL_DEBUG
    local function inner (...)
        if logger then
            logger:Log(level, ...)
        end
    end

    return inner
end
--#endregion LOGGER