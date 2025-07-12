local Log = df

-- ----------------------------------------------------------------------------

local dirty = false
local scrollListControl = nil

local function LayoutRow(rowControl, data, scrollList)
    local report = IngameBugreportsSavedVariables.reports[data.reportName]
    local errorString = report.text
    local msg = IMP_IngameBugreports_ErrorMessage(errorString)

    local addonName = msg:GetFirstStacktraceAddonName()
    local location = msg:GetFirstStacktraceWithAddon()

    GetControl(rowControl, 'Index'):SetText(data.index)
    GetControl(rowControl, 'AddonName'):SetText(addonName)
    GetControl(rowControl, 'Error'):SetText(location)

    rowControl:SetHandler('OnMouseEnter', function() ZO_Tooltips_ShowTextTooltip(rowControl, RIGHT, errorString) end)
    rowControl:SetHandler('OnMouseExit', function() ZO_Tooltips_HideTextTooltip() end)
end

local function UpdateScrollListControl(force)
    dirty = true

    if scrollListControl:IsHidden() then return end

	local dataList = ZO_ScrollList_GetDataList(scrollListControl)
    ZO_ScrollList_Clear(scrollListControl)

    local reports = IngameBugreportsSavedVariables.reports

    local i = 1
    for reportName, _ in pairs(reports) do
        local value = {
            index = i,
            reportName = reportName,
        }
        dataList[i] = ZO_ScrollList_CreateDataEntry(1, value)
        i = i + 1
    end

    Log('Size of data list: %d', #dataList)
    -- table.sort(dataList, function(a,b) return a.data.index < b.data.index end)

    ZO_ScrollList_Commit(scrollListControl)
    dirty = false
end

function IMP_IngameBugreports_UI_OnShow()
    if dirty then UpdateScrollListControl() end
end

function IMP_IngameBugreports_UI_OnInitialized(control)
    scrollListControl = control:GetNamedChild('Listing'):GetNamedChild('ScrollableList')
    ZO_ScrollList_AddDataType(scrollListControl, 1, 'IMP_IngameBugreports_Listing_Row', 32, LayoutRow)

    -- local selectTemplate = 'ZO_ThinListHighlight'
	-- local selectCallback = nil
	-- ZO_ScrollList_EnableSelection(control, selectTemplate, selectCallback)

    dirty = true

    SLASH_COMMANDS['/imp_bugreports'] = function() IMP_IngameBugreports_TLC:SetHidden(false) end
end
