

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local Config=require('suiteqltools.config')
local CompletionData=require('suiteqltools/completion/completionData')
local TablePickerCommon=require('suiteqltools.tablepicker.tablepickercommon')

local M={}


local picker=function(tbl,positionParms)
    local opts = {}

    if not Config.options.queryRun.completion then
        print('Completion must be enabled')
        return
    end

    local options=CompletionData.getFields(tbl)

    if #options==0 then
        print('Completion data not found for current profile')
        return
    end

    local max=TablePickerCommon.maxInList(options)
    
    -- Create the telescope picker
    return pickers.new(opts, {
        prompt_title =tbl,
        finder = finders.new_table {
            results = options,
            entry_maker = function(entry)
                return TablePickerCommon.makePickerEntry(max,entry)
            end,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr,map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
               local selection=action_state.get_selected_entry()
                TablePickerCommon.writeToBufferPo(selection.value,positionParms)
            end)
            return true
        end,
    }):find()
end

M.showForTable=function(tbl,positionParms)
    picker(tbl,positionParms)
end


return M
