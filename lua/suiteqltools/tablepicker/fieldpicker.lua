local Config = require('suiteqltools.config')
local CompletionData = require('suiteqltools/completion/completionData')
local TablePickerCommon = require('suiteqltools.tablepicker.tablepickercommon')
local Picker = require("suiteqltools.pickers")

local M = {}


local picker = function(tbl, positionParms)
    if not Config.options.queryRun.completion then
        print('Completion must be enabled')
        return
    end

    local options = CompletionData.getFields(tbl)

    if #options == 0 then
        print('Completion data not found for current profile')
        return
    end

    local max = TablePickerCommon.maxInList(options)

    Picker.show_picker({
        title = tbl,
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
            TablePickerCommon.writeToBufferPo(item.id, positionParms)
        end,
        showPreview = false,
        searchValue = function(item)
            return item.id .. item.label
        end,
        justifyColumns = true

    })
end

M.showForTable = function(tbl, positionParms)
    picker(tbl, positionParms)
end


return M
