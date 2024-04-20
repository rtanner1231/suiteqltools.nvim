local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Config = require("suiteqltools.config")
local CompletionData = require("suiteqltools/completion/completionData")
local FieldPicker = require("suiteqltools.tablepicker.fieldpicker")
local TablePickerCommon = require("suiteqltools.tablepicker.tablepickercommon")

local M = {}

local picker = function(isFieldPicker, positionParms)
	local opts = {}

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

	-- Create the telescope picker
	return pickers
		.new(opts, {
			prompt_title = title,
			finder = finders.new_table({
				results = options,
				entry_maker = function(entry)
					return TablePickerCommon.makePickerEntry(max, entry)
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				map({ "n", "i" }, "<C-f>", function(_prompt_buf)
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					TablePickerCommon.lastTable = selection.value
					FieldPicker.showForTable(selection.value, positionParms)
				end)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					TablePickerCommon.lastTable = selection.value
					if isFieldPicker then
						FieldPicker.showForTable(selection.value, positionParms)
					else
						TablePickerCommon.writeToBufferPo(selection.value, positionParms)
					end
				end)
				return true
			end,
		})
		:find()
end

M.showTablePicker = function(isFieldPicker, positionParms)
	picker(isFieldPicker, positionParms)
end

return M
