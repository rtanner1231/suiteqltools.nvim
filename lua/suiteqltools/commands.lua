local FormatSuiteQL=require('suiteqltools.formatsuiteql')
local RunSuiteQL=require('suiteqltools.runSuiteQL')

local M={}

M.command_list={
    {value="FormatQuery", callback=FormatSuiteQL.runFormatCurrent},
    {value="FormatFile",callback=FormatSuiteQL.runFormatAll},
    {value="RunCurrentQuery",callback=RunSuiteQL.runCurrentQuery},
    {value="ToggleQueryFullScreen", callback=RunSuiteQL.toggleFullScreen},
    {value="ToggleQueryMode", callback=RunSuiteQL.toggleDisplayMode},
    {value="CloseQuery", callback=RunSuiteQL.closeQuery},
    {value="SortColumn", callback=RunSuiteQL.sortColumn},
    {value="NextPage", callback=RunSuiteQL.nextPage},
    {value="PrevPage", callback=RunSuiteQL.prevPage},
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
