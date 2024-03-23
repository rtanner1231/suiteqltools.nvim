local TablePicker=require('suiteqltools.tablepicker.tablepicker')
local FieldPicker=require('suiteqltools.tablepicker.fieldpicker')
local TablePickerCommon=require('suiteqltools.tablepicker.tablepickercommon')

local M={}



M.showTablePicker=function()
    local positionParms=TablePickerCommon.createPositionParms()
    TablePicker.showTablePicker(false,positionParms)
end

M.showFieldPicker=function()
    local positionParms=TablePickerCommon.createPositionParms()
    TablePicker.showTablePicker(true,positionParms)
end

M.showLastTableFieldPicker=function()
    local positionParms=TablePickerCommon.createPositionParms()
    if TablePickerCommon.lastTable~=nil then
        FieldPicker.showForTable(TablePickerCommon.lastTable,positionParms)
    else
        M.showFieldPicker()
    end
end

return M
