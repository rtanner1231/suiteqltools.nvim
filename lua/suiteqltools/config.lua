local M = {}

local defaults = {
	sqlFormatter = {
		language = "plsql",
		tabWidth = 2,
		useTabs = false,
		keywordCase = "preserve",
		indentStyle = "standard",
		logicalOperatorNewline = "before",
		expressionWidth = 50,
		denseOperators = false,
		newLineBeforeSemicolon = false,
	},
	queryRun = {
		enabled = true,
		initialHeight = "20%",
		fullHeight = "100%",
		openFull = false,
		focusQueryOnRun = false,
		initialMode = "table",
		jsonFormatSpace = 4,
		pageSize = 10,
		editorKeymap = {
			formatQuery = "<C-s>s",
			toggleWindow = "<C-s>w",
			runQuery = "<C-s>r",
			toggleResultZoom = "<C-s>f",
			nextPage = "<C-s>n",
			previousPage = "<C-s>p",
			toggleDisplayMode = "<C-s>m",
		},
		history = false,
		historyLimit = 2000,
		completion = false,
	},
}

M.options = defaults

M.setup = function(opts)
	M.options = vim.tbl_deep_extend("force", defaults, opts)
end

return M
