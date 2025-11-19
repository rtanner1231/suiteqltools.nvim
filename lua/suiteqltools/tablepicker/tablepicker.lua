local Config = require("suiteqltools.config")
local CompletionData = require("suiteqltools/completion/completionData")
local FieldPicker = require("suiteqltools.tablepicker.fieldpicker")
local TablePickerCommon = require("suiteqltools.tablepicker.tablepickercommon")
local Picker = require("suiteqltools.pickers")

local M = {}
local picker = function(isFieldPicker, positionParms)
    if not Config.options.queryRun.completion then
        print("Completion must be enabled")
        return
    end

    local options = CompletionData.getTables()

    if #options == 0 then
        print("Completion data not found for current profile")
        return
    end

    local max = TablePickerCommon.maxInList(options)

    local title = ""

    if isFieldPicker then
        title = "Field Picker"
    else
        title = "Table Picker"
    end


    Picker.show_picker({
        title = title,
        items = options,
        format = {
            {
                type = 'func',
                value = function(item)
                    local id = item.id
                    if #id > max then
                        id = id:sub(1, max - 3) .. '...'
                    end
                    return id
                end,
                highlight = 'Label'
            },
            { type = 'string', value = ' ' },
            { type = 'field',  value = 'label', highlight = 'Comment' }
        },
        defaultAction = function(item)
            TablePickerCommon.lastTable = item.id
            if isFieldPicker then
                FieldPicker.showForTable(item.id, positionParms)
            else
                TablePickerCommon.writeToBufferPo(item.id, positionParms)
            end
        end,
        customActions = { {
            name = 'OpenFieldPicker',
            action = function(item)
                TablePickerCommon.lastTable = item.id
                FieldPicker.showForTable(item.id, positionParms)
            end,
            keyMap = '<C-f>',
            closePicker = true
        } },
        showPreview = false,
        searchValue = function(item)
            return item.id .. item.label
        end,
        justifyColumns = true
    })
end

M.showTablePicker = function(isFieldPicker, positionParms)
    picker(isFieldPicker, positionParms)
end

return M
