
local QueryResult={}
local QueryConfig=require('suiteqltools.config').options.queryRun
local NuiTable=require('nui.table')
local Text = require("nui.text")
local Common=require('suiteqltools.util.common')

local M={}

function QueryResult:new(bufnr)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    self.bufnr=bufnr
    self.currentMode=QueryConfig.initialMode
    self.items=nil
    self.currentJSON=nil
    self.sortDir='ASC'

    return o
end

function QueryResult:getJSON()
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

function QueryResult:render()
    vim.api.nvim_buf_set_option(self.bufnr,'modifiable',true)
    vim.api.nvim_buf_set_option(self.bufnr,'readonly',false)
    self:clear()
    if self.currentMode=='table' then
            self.dataTable:render()
        vim.api.nvim_buf_set_option(self.bufnr,'readonly',false)
        vim.api.nvim_buf_set_option(self.bufnr,'modifiable',true)
    else
        local json=self:getJSON()
        vim.api.nvim_buf_set_lines(self.bufnr,1,1,false,json)
    end
    vim.api.nvim_buf_set_option(self.bufnr,'modifiable',false)
    vim.api.nvim_buf_set_option(self.bufnr,'readonly',true)


end


function QueryResult:toggleDisplayMode()

    if self.currentMode=='table' then
        self.currentMode='json'
    else
        self.currentMode='table'
    end

    self:render()
end

function QueryResult:setItems(items)
    self.items=items
    self.currentJSON=nil
    self.dataTable=self:initTable()
end

function QueryResult:initTable()
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
        bufnr=self.bufnr,
        columns=columns,
        data=self.items
    })
end

function QueryResult:clear()
    vim.api.nvim_buf_set_lines(self.bufnr,0,-1,false,{''})
end

function QueryResult:_doSort(col)
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

function QueryResult:sort()

    if self.currentMode=='json' then
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


M.QueryResultBuf=QueryResult

return M
