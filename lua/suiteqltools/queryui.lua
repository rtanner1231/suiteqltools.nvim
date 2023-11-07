local Split=require('nui.split')
local Common=require('suiteqltools.util.common')
local QueryConfig=require('suiteqltools.config').options.queryRun
local NuiTable=require('nui.table')
local Text = require("nui.text")

local M={}

local QueryUI={}

function QueryUI:new()
    local s={}
    setmetatable(s,self)
    self.__index=self
    self.items=nil
    self.sourceWin=vim.api.nvim_get_current_win()
    self.currentMode=QueryConfig.initialMode
    self.currentJSON=nil
    self.sortDir='ASC'
    self.page=1
    local initialHeight
    if QueryConfig.openFull then
        initialHeight=QueryConfig.fullHeight
    else
        initialHeight=QueryConfig.initialHeight
    end
    self.split=Split({
        relative="editor",
        position="bottom",
        size=initialHeight
    })
    self.isFullScreen=false
    self.valid=true
    self.split:on("WinClosed",function()
        self.valid=false
    end)
    --self.datatable=self:initTable()
    return s
end

function QueryUI:getJSON()
    if self.currentJSON ~= nil then
        return self.currentJSON
    end

    local fullPath= debug.getinfo(1).source:sub(2)


    local scriptPath=Common.getScriptPath(fullPath,'/lua/suiteqltools','scripts/jsonformatter/formatjson.js')

    local jsonItems="'"..vim.json.encode(self.items).."'"

    local space=QueryConfig.jsonFormatSpace

    local args=' --json '..jsonItems..' --space '..space

    local command='node '..scriptPath..args


    local result=vim.fn.systemlist(command)


    return result


end

function QueryUI:_writePageText()
    local pageStr=tostring(self.page)
    print('Page: '..pageStr)
    --vim.api.nvim_buf_set_text(self.split.bufnr,0,0,0,#pageStr,{pageStr})
end

function QueryUI:render()
    vim.api.nvim_buf_set_option(self.split.bufnr,'modifiable',true)
    vim.api.nvim_buf_set_option(self.split.bufnr,'readonly',false)
    self:clear()
    if self.currentMode=='table' then
        self.dataTable:render()
        vim.api.nvim_buf_set_option(self.split.bufnr,'readonly',false)
        vim.api.nvim_buf_set_option(self.split.bufnr,'modifiable',true)
    else
        local json=self:getJSON()
        vim.api.nvim_buf_set_lines(self.split.bufnr,1,1,false,json)
    end
    self:_writePageText()
    vim.api.nvim_buf_set_option(self.split.bufnr,'modifiable',false)
    vim.api.nvim_buf_set_option(self.split.bufnr,'readonly',true)


end

function QueryUI:toggleDisplayMode()
    if not self.valid then
        return
    end

    if self.currentMode=='table' then
        self.currentMode='json'
    else
        self.currentMode='table'
    end

    self:render()
end

function QueryUI:setItems(items,page)
    self.items=items
    self.page=page
    self.currentJSON=nil
    self.dataTable=self:initTable()
end

function QueryUI:isValid()
    return self.valid
end

function QueryUI:close()
    if self.valid then
        self.valid=false
        self.split:unmount()
    end
end

function QueryUI:toggleFullScreen()
    if self.valid then
        local newHeight=''
        if self.isFullScreen then
            newHeight=QueryConfig.initialHeight
            self.isFullScreen=false
        else
            newHeight=QueryConfig.fullHeight
            self.isFullScreen=true
            vim.api.nvim_set_current_win(self.split.winid)
        end
        self.split:update_layout({
            size=newHeight
        })
    end
end

function QueryUI:clear()
    if self.valid then
        vim.api.nvim_buf_set_lines(self.split.bufnr,0,-1,false,{''})
    end
end

function QueryUI:initTable()
    local columns={}
    local colSet={}
    --If a field value is null, the rest api does not return the field
    --We must check all rows for additional fields which may be missing in some response rows
    --This will slow down the query lookup.  
    --Possibly add a columnStrategy config option to control this in the future
    for _,item in pairs(self.items) do
        for k,_ in pairs(item) do
            if colSet[k]==nil then
                table.insert(columns,{accessor_key=k,header=function(_)
                    return Text(k,"DiagnosticHint")
                end})
                colSet[k]=true
            end
        end
    end
-- print(vim.inspect(columns))
-- print(vim.inspect(self.items[1]))
-- print(vim.inspect(self.items))
    return NuiTable({
        bufnr=self.split.bufnr,
        columns=columns,
        data=self.items
    })
end

function QueryUI:_doSort(col)
    local sortFunc=function(item1,item2)
        if self.sortDir=='ASC' then
            if item1[col]==nil then
                return false
            end
            if item2[col]==nil then
                return true
            end
            return item1[col]<item2[col]
        else
            if item1[col]==nil then
                return true
            end
            if item2[col]==nil then
                return false
            end
            return item1[col]>item2[col]
        end
    end

    table.sort(self.items,sortFunc)
    if self.sortDir=='ASC' then
        self.sortDir='DESC'
    else
        self.sortDir='ASC'
    end
    local currentWin=vim.api.nvim_get_current_win()
    local currentPos=vim.api.nvim_win_get_cursor(currentWin)
    self:render()
    vim.api.nvim_win_set_cursor(currentWin,currentPos)
end

function QueryUI:sort()

    if self.valid==false or self.currentMode=='json' then
        return
    end

    local cell=self.dataTable:get_cell()
    if cell then
        local column=cell.column
        if column.accessor_key then
            self:_doSort(column.accessor_key)
        end
    end
end



function QueryUI:show()

    local currentWin=vim.api.nvim_get_current_win()
    self.split:mount()
    self:render()
    local winToFocus
    if currentWin==self.split.winid then
        winToFocus=currentWin
    elseif QueryConfig.focusQueryOnRun then
        winToFocus=self.split.winid
    else
        winToFocus=self.sourceWin
    end
    vim.api.nvim_set_current_win(winToFocus)
end

M.QueryUI=QueryUI

return M
