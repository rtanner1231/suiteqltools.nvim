local Editor=require('suiteqltools.editor')
local FormatSuiteQL=require('suiteqltools.formatsuiteql')

local M={}

M.runFormatCurrent=function()

    local winid=vim.api.nvim_get_current_win()

    if Editor.isWindowEditorWindow(winid) then
        Editor.formatEditorQuery()
        return
    end

    FormatSuiteQL.runFormatCurrent()
end

M.runFormatAll=function()
    FormatSuiteQL.runFormatAll()
end

return M
