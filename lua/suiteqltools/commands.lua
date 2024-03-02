local FormatSuiteQL=require('suiteqltools.formatcommands')
local RunSuiteQL=require('suiteqltools.runSuiteQL')
local TokenConfig=require('suiteqltools.tokenconfig')
local QueryEditor=require('suiteqltools.editor')

local M={}

M.command_list={
    {value="FormatQuery", callback=FormatSuiteQL.runFormatCurrent},
    {value="FormatFile",callback=FormatSuiteQL.runFormatAll},
    --{value="RunCurrentQuery",callback=RunSuiteQL.runCurrentQuery},
    --{value="ToggleQueryFullScreen", callback=RunSuiteQL.toggleFullScreen},
    --{value="ToggleQueryMode", callback=RunSuiteQL.toggleDisplayMode},
    --{value="CloseQuery", callback=RunSuiteQL.closeQuery},
    --{value="SortColumn", callback=RunSuiteQL.sortColumn},
    --{value="NextPage", callback=RunSuiteQL.nextPage},
    --{value="PrevPage", callback=RunSuiteQL.prevPage},
    {value="AddProfile", callback=TokenConfig.addProfile},
    {value="SelectProfile",callback=TokenConfig.showSelectProfilePicker},
    {value="DeleteProfile",callback=TokenConfig.showDeleteProfilePicker},
    {value="ResetTokens", callback=TokenConfig.resetTokens},
    {value="ToggleEditor", callback=QueryEditor.toggleQueryEditor},
    {value="EditQuery", callback=QueryEditor.sendCurrentQueryToEditor}
}

M.runCommand=function(command)
    for _,v in pairs(M.command_list) do
        if v.value==command then
            v.callback()
            return
        end
    end
end

return M
