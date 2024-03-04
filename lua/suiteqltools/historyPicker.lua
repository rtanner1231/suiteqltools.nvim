local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local previewers = require('telescope.previewers')
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local History=require('suiteqltools.history')
local Common=require('suiteqltools.util.common')
local Editor=require('suiteqltools.editor')

-- Define your options table
-- local options = {
--     {display="test1", query="select * from location",date="2023-01-01"},
--     {display="test2", query="this is query2",date="2023-01-02"},
--     {display="test3", query="this is query3",date="2023-01-03"}
-- }


local P=function(table)
    print(vim.inspect(table))
end

-- Define your extension
local M = {}

local splitToTable=function(str)
    return Common.splitStr(str,"\n")
end

-- Function to create the picker
local picker=function(opts)
    opts = opts or {}

    local options=History.getHistoryData()

    -- Create the telescope picker
    return pickers.new(opts, {
        prompt_title = 'SuiteQL history',
        finder = finders.new_table {
            results = options,
            entry_maker = function(entry)
                return {
                    display = entry.date..'  -  '..entry.display,
                    value=entry,
                    ordinal=entry.query
                }
            end,
        },
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer {
            define_preview = function(self, entry, status)
                local lines=splitToTable(entry.value.query)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, lines)
                vim.bo[self.state.bufnr].filetype = 'sql'
            end,
        },
        attach_mappings = function(prompt_bufnr,map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection=action_state.get_selected_entry()
                Editor.openEditorWithQuery(selection.value.query)
            end)
            return true
        end,
    }):find()
end

M.showHistoryPicker=function()
    picker()
end



local test=function()
    M.picker()
end

--test()

-- Return the module
return M
