local Split=require('nui.split')
local QueryConfig=require('suiteqltools.config').options.queryRun
local QueryResultBuf=require("suiteqltools.queryResultBuf")

local M={}

local QueryUI={}

function QueryUI:new()
    local s={}
    setmetatable(s,self)
    self.__index=self
    self.sourceWin=vim.api.nvim_get_current_win()
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
    self.queryResultBuf=QueryResultBuf.QueryResultBuf:new(self.split.bufnr)
    return s
end


function QueryUI:render()

    self.queryResultBuf:render()

end

function QueryUI:toggleDisplayMode()
    if not self.valid then
        return
    end

    self.queryResultBuf:toggleDisplayMode()

end

function QueryUI:setItems(items)
    self.queryResultBuf:setItems(items)
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


function QueryUI:sort()

    if self.valid==false then
        return
    end

    self.queryResultBuf:sort()

end



function QueryUI:show()

    local currentWin=vim.api.nvim_get_current_win()
    self.split:mount()
    --self:render()
    self.queryResultBuf:render()
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
