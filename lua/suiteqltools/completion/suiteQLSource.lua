
local cmp=require('cmp')
local SuiteQLCompletion=require('suiteqltools.completion.suiteQLCompletionParse')
local Config=require('suiteqltools.config')

local source={}

source.new = function(bufnr)
  local self = setmetatable({}, { __index = source })
  self.bufnr=bufnr
  return self
end

function source:is_available()
    local curbuf=vim.api.nvim_get_current_buf()
    return curbuf==self.bufnr

end


source.get_keyword_pattern = function()
  return [[\w\+]]
end

source.get_trigger_characters = function()
  return {' ','.'}
end



  function source:complete(params, callback)

    local cursor=params.context.cursor

    local completeResult=SuiteQLCompletion.getCompletions(cursor)

    --print(vim.inspect(completeResult))

    callback(completeResult)
  end



 

local M={}

M.register=function(bufnr)
    if not Config.options.queryRun.completion then
        return
    end
    local cfg=cmp.get_config()
    cmp.register_source('SuiteQL', source.new(bufnr))
    local sources=cfg.sources
    table.insert(sources,{name='SuiteQL'})
    cmp.setup({sources=sources})
end

return M
