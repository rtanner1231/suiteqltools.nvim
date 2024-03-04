
local TreesitterLookup=require('suiteqltools.util.treesitter_lookup')
local Popup=require('nui.popup')
local event = require("nui.utils.autocmd").event
local Layout=require('nui.layout')
local FormatSql=require('suiteqltools.formatsuiteql')
local QueryResultBuf=require('suiteqltools.queryResultBuf')
local RunQuery=require('suiteqltools.runQuery')
local Config=require('suiteqltools.config')
local Common=require('suiteqltools.util.common')
local TokenConfig=require('suiteqltools.tokenconfig')
local History=require('suiteqltools.history')

local P=function(tbl)
    return print(vim.inspect(tbl))
end

local M={}

local QueryEditor={}

QueryEditor.__index=QueryEditor

function QueryEditor.new()
    local s=setmetatable({},QueryEditor)
    local editorPop=Popup({
        enter=true,
        border="double",
        buf_options={
            modifiable=true,
        }
    })

    local resultPop=Popup({
        border="single",
        buf_options={
            modifiable=false
        }
    })

    local statusBar=Popup({
        border="single",
        buf_options={
            modifiable=false
        }
    })


    local layout=Layout(
        {
            position="50%",
            size={
                width="90%",
                height="90%"
            }
        },
        Layout.Box({
            Layout.Box(editorPop,{size="70%"}),
            Layout.Box(resultPop,{size="30%"}),
            Layout.Box(statusBar,{size="3"})
        },{dir="col"})
    )

    s.editorPop=editorPop
    s.resultPop=resultPop
    s.statusBar=statusBar
    s.layout=layout
    s.isMounted=false
    s.isShown=false
    s.queryResultBuf=QueryResultBuf.QueryResultBuf:new(s.resultPop.bufnr)
    s.currentPage=1
    s.hasMore=false
    s.total=0
    s.resultIsFullScreen=false
    s.currentStatus=""

    s:_init()
    
    return s
end

function QueryEditor:_init()
    self:_initEditor()

    self:_initAutoCmds()

    self:_initKeymaps()

end

function QueryEditor:_initAutoCmds()
    -- local closeFn=function(b)
    --     local cbufnr=vim.fn.bufnr()
    --     P({cbufnr=cbufnr,editorPopNr=self.editorPop.bufnr,resultPopNr=self.resultPop.bufnr,b=b})
    --     if cbufnr~=self.editorPop.bufnr and cbufnr ~= self.resultPop.bufnr then
    --         self:_hide()
    --     end
    -- end
    --
    -- self.editorPop:on(event.BufLeave,closeFn)
    -- self.resultPop:on(event.BufLeave,closeFn)
--
    local popups={self.editorPop,self.resultPop}

    for _, popup in pairs(popups) do
      popup:on("BufLeave", function()
        vim.schedule(function()
          local curr_bufnr = vim.api.nvim_get_current_buf()
          for _, p in pairs(popups) do
            if p.bufnr == curr_bufnr then
              return
            end
          end
        self:_hide()
        end)
      end)
    end
    -- local cl=function()
    --     self:_hide()
    -- end
    -- vim.api.nvim_create_autocmd("BufLeave",{buffer=self.layout.bufnr,callback=cl})
end

function QueryEditor:_initKeymaps()
    local doFormat=function()
        self:formatQuery()
    end


    local toggleWindow=function()
        self:toggleWin()
    end

    local runQuery=function()
        self:runQuery()
    end

    local toggleFullScreen=function()
        self:toggleResultFullscreen()
    end

    local nextPage=function()
        self:nextPage()
    end

    local previousPage=function()
        self:previousPage()
    end

    local toggleDisplayMode=function()
        self:toggleDisplayMode()
    end

    local configKeymap=Config.options.queryRun.editorKeymap

    --P(configKeymap)

    local keyMap={
        {key=configKeymap.formatQuery,fn=doFormat,wins= {self.editorPop}},
        {key=configKeymap.toggleWindow,fn=toggleWindow,wins = {self.editorPop,self.resultPop} },
        {key=configKeymap.runQuery,fn=runQuery,wins={self.editorPop}},
        {key=configKeymap.toggleResultZoom,fn=toggleFullScreen,wins={self.editorPop,self.resultPop}},
        {key=configKeymap.nextPage,fn=nextPage,wins={self.editorPop,self.resultPop}},
        {key=configKeymap.previousPage,fn=previousPage,wins={self.editorPop,self.resultPop}},
        {key=configKeymap.toggleDisplayMode,fn=toggleDisplayMode,wins={self.editorPop,self.resultPop}},
    }

    for _,v in ipairs(keyMap) do
        for _,w in ipairs(v.wins) do

            w:map('n',v.key,v.fn,{noremap=true})
        end
    end

end

function QueryEditor:_initEditor()
    vim.api.nvim_set_option_value('filetype','sql',{buf=self.editorPop.bufnr})
end

function QueryEditor:_focusWindow(winid)
    vim.api.nvim_set_current_win(winid)
end

function QueryEditor:toggleWin()
    local currentWin=vim.api.nvim_get_current_win()
    if currentWin==self.resultPop.winid then
        self:_focusWindow(self.editorPop.winid)
    elseif currentWin==self.editorPop.winid then
        self:_focusWindow(self.resultPop.winid)
    end
end

function QueryEditor:_hide()
    self.layout:hide()
    self.isShown=false
end

function QueryEditor:show()
    if self.mounted then
        self.layout:show()
    else
        self.layout:mount()
        self.mounted=true
    end

    self.isShown=true

    self:_setStatusText(self.currentStatus)

end

--get the winid of the editor
--@returns {int}
function QueryEditor:getEditorWindow()
    return self.editorPop.winid
end

function QueryEditor:toggle()
    if self.isShown then
        self:_hide()
    else
        self:show()
    end
end

function QueryEditor:_getEditorText()
    local lines= vim.api.nvim_buf_get_text(self.editorPop.bufnr,0,0,-1,-1,{})

    return table.concat(lines,'\n')
end

function QueryEditor:setEditorText(text)
    vim.api.nvim_buf_set_lines(self.editorPop.bufnr,0,-1,true,text)
end

function QueryEditor:_formatStatusText(text)
    local activeProfile=TokenConfig.getActiveProfile()

    local statusWidth=vim.fn.winwidth(self.statusBar.winid)

    local textWidth=#text+#activeProfile

    local spaceWidth=statusWidth-textWidth-2

    local spaces=string.rep(' ',spaceWidth)

    return text..spaces..activeProfile
end

function QueryEditor:_setStatusText(text)
    self.currentStatus=text
    local formattedText=self:_formatStatusText(text)
    vim.api.nvim_buf_set_option(self.statusBar.bufnr,'modifiable',true)
    vim.api.nvim_buf_set_option(self.statusBar.bufnr,'readonly',false)
    vim.api.nvim_buf_set_lines(self.statusBar.bufnr,0,-1,true,{formattedText})
    vim.api.nvim_buf_set_option(self.statusBar.bufnr,'modifiable',false)
    vim.api.nvim_buf_set_option(self.statusBar.bufnr,'readonly',true)
end



function QueryEditor:formatQuery()
    local qText=self:_getEditorText()

    local formattedText=FormatSql.formatQuery(qText)

    self:setEditorText(formattedText)
end

function QueryEditor:_doRunQuery()
    local qText=self:_getEditorText()
    
    local queryResult=RunQuery.runQuery(qText,self.currentPage)

    if queryResult==nil then
        return nil
    end

    self.hasMore=queryResult.hasMore
    self.total=queryResult.total
    if queryResult.success==false then
        self.queryResultBuf:setError(queryResult.errorMessage)
        self:_setStatusText('Error')
        return
    end


    self.queryResultBuf:setItems(queryResult.items)
    self.queryResultBuf:render()
    if #queryResult.items == 0 then
        self:_setStatusText('No results')
    else
        local totalPages=math.ceil(self.total/Config.options.queryRun.pageSize)

        self:_setStatusText('Page '..self.currentPage..' of '..totalPages)
    end

    History.addToHistory(qText)
end

function QueryEditor:runQuery()
    self.total=0
    self.hasMore=false
    self.currentPage=1
    self:_doRunQuery()
end

function QueryEditor:toggleResultFullscreen()
    local updateBox
    if self.resultIsFullScreen then
        -- self.editorPop:show()
        self.resultIsFullScreen=false
        updateBox=Layout.Box({
                    Layout.Box(self.editorPop,{size="70%"}),
                    Layout.Box(self.resultPop,{size="30%"}),
                    Layout.Box(self.statusBar,{size="3"})
                },{dir="col"})
        self:_focusWindow(self.editorPop.winid)
        vim.api.nvim_win_set_cursor(self.resultPop.winid,{1,0})
    else
        -- self.editorPop:hide()
        self.resultIsFullScreen=true
        updateBox=Layout.Box({
                    Layout.Box(self.editorPop,{size="10%"}),
                    Layout.Box(self.resultPop,{size="90%"}),
                    Layout.Box(self.statusBar,{size="3"})

                },{dir="col"})
        self:_focusWindow(self.resultPop.winid)

    end
    self.layout:update(updateBox)
end

function QueryEditor:nextPage()
    if self.hasMore then
        self.currentPage=self.currentPage+1
        self:_doRunQuery()
    end
end

function QueryEditor:previousPage()
    if self.currentPage>1 then
        self.currentPage=self.currentPage-1
        self:_doRunQuery()
    end
end

function QueryEditor:clearResults()
    self:_setStatusText('')
    self.queryResultBuf:clearResults()
end

--toggle between showing a table and json
function QueryEditor:toggleDisplayMode()
    self.queryResultBuf:toggleDisplayMode()
end

local getQueryText=function()
    local nodes=TreesitterLookup.getCurrentQuery()

    if nodes==nil then
        return nil
    end

    if #nodes==0 then
        return nil
    end

    local bufnr=vim.api.nvim_get_current_buf()

    local node=nodes[1]

    local sql_text=vim.treesitter.get_node_text(node,bufnr)


    --remove template quotes from start and end
    local trimmed_text=string.sub(sql_text,2,string.len(sql_text)-1)

    local splitText=Common.splitStr(trimmed_text,"\n")

    return splitText
end


local qeInstance=nil

local openQueryWithQueryTable=function(queryTable)
    if qeInstance==nil then
        qeInstance=QueryEditor.new()
    end
    qeInstance:clearResults()
    qeInstance:show()
    qeInstance:setEditorText(queryTable)
end

M.toggleQueryEditor=function()
    if qeInstance==nil then
        qeInstance=QueryEditor.new()
    end
    qeInstance:toggle()
end

M.openEditorWithQuery=function(query)
    local queryTable=Common.splitStr(query,"\n")
    openQueryWithQueryTable(queryTable)
end

M.sendCurrentQueryToEditor=function()
    local query=getQueryText()

    if query==nil then
        print('no query under cursor')
        return
    end

    openQueryWithQueryTable(query)
end


--return true if the current window is the editor window
--false otherwise
--@param {int} winid
--@returns {boolean}
M.isWindowEditorWindow=function(winid)
    if qeInstance==nil then
        return false
    end

    local editorWin=qeInstance:getEditorWindow()

    return winid==editorWin
end

--Format the current query in the editor, if the editor exists
M.formatEditorQuery=function()
    if qeInstance==nil then
        return
    end
    qeInstance:formatQuery()
end

return M
