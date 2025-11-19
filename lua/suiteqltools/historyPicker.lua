local History = require('suiteqltools.history')
local Editor = require('suiteqltools.editor')

local Picker = require('suiteqltools.pickers')

-- Define your options table
-- local options = {
--     {display="test1", query="select * from location",date="2023-01-01"},
--     {display="test2", query="this is query2",date="2023-01-02"},
--     {display="test3", query="this is query3",date="2023-01-03"}
-- }


local P = function(table)
    print(vim.inspect(table))
end

-- Define your extension
local M = {}


-- Function to create the picker
local picker = function(opts)
    opts = opts or {}

    local options = History.getHistoryData()

    Picker.show_picker({
        items = options,
        format = {
            { type = 'field',  value = 'date',    highlight = 'Comment' },
            { type = 'string', value = '  ' },
            { type = 'field',  value = 'display', highlight = 'Label' },
        },
        defaultAction = function(item)
            Editor.openEditorWithQuery(item.query)
        end,
        showPreview = true,
        previewFT = 'sql',
        previewValue = function(item)
            return item.query
        end,
        searchValue = function(item)
            return item.query
        end

    })
end

M.showHistoryPicker = function()
    picker()
end



local test = function()
    M.picker()
end

--test()

-- Return the module
return M
