local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local NSConn = require("nsconn")
local Path = require("plenary.path")
local File = require("suiteqltools.util.fileutil")
local Common = require("suiteqltools.util.common")
local Config = require("suiteqltools.config")

local M = {}

local completionCache = {}

local getDataDirectory = function()
	local basePath = vim.fn.stdpath("data")
	local dname = "suiteqlcompletion/"
	return File.pathcombine(basePath, dname)
end

local getCompletionPath = function(currentProfile)
	local dataDir = getDataDirectory()
	local fname = currentProfile .. ".json"
	return Path:new(File.pathcombine(dataDir, fname))
end

local checkFolderExists = function()
	local dataDir = getDataDirectory()
	local dataPath = Path:new(dataDir)
	if not dataPath:exists() then
		dataPath:mkdir()
	end
end

local writeCompletionData = function(completionData)
	checkFolderExists()
	local currentProfile = NSConn.getActiveProfile()
	completionCache[currentProfile] = vim.json.decode(completionData)
	local p = getCompletionPath(currentProfile)
	p:write(completionData, "w")
end

local getCompletionData = function()
	local currentProfile = NSConn.getActiveProfile()
	if completionCache[currentProfile] ~= nil then
		return completionCache[currentProfile]
	end

	local p = getCompletionPath(currentProfile)

	if not p:exists() then
		completionCache[currentProfile] = {}
		return {}
	end
	local contents = p:read()

	if #Common.trim(contents) == 0 then
		return {}
	end

	local val = vim.json.decode(contents)
	completionCache[currentProfile] = val
	return val
end

local function getTables()
	local data = getCompletionData()
	return data.tables
end

local function getFields(table)
	local data = getCompletionData()
	if data == nil or data.tableFields == nil then
		return {}
	end

	if data.tableFields[table] ~= nil then
		return data.tableFields[table]
	end
	return {}
end

local getAllText = function(buf)
	local textArray = vim.api.nvim_buf_get_text(buf, 0, 0, -1, -1, {})

	local result = ""

	for _, v in ipairs(textArray) do
		result = result .. v
	end

	return result
end

local function setCompletionData()
	if not Config.options.queryRun.completion then
		print("Completion is not enabled")
		return
	end

	local currentProfile = NSConn.getActiveProfile()
	local message = "Setting completion data for " .. currentProfile

	local popup = Popup({
		enter = true,
		focusable = true,
		position = "50%",
		size = {
			height = "70%",
			width = "70%",
		},
		border = {
			style = "rounded",
			text = {
				top = message,
			},
		},
		buf_options = {
			modifiable = true,
			readonly = false,
		},
	})
	popup:mount()

	popup:map("n", "<enter>", function(bufnr)
		local text = getAllText(popup.bufnr)
		popup:unmount()
		writeCompletionData(text)
	end, { noremap = true })

	popup:map("n", "q", function(bufnr)
		popup:unmount()
	end, { noremap = true })
	popup:on(event.BufLeave, function()
		popup:unmount()
	end)
end

M.getTables = getTables
M.getFields = getFields
M.setCompletionData = setCompletionData

return M
