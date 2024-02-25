
local M={}

local get_root=function(bufnr,filetype)
    local parser=vim.treesitter.get_parser(bufnr,filetype)
    local tree=parser:parse()[1]

    return tree:root()
end

local pos_within_range=function(pos,range)
    --print(vim.inspect(pos))
    --print(vim.inspect(range))
    if pos[1]<range[1]+1 or pos[1]>range[3]+1 then
        return false
    end

    return true

end

local getSqlNodes=function(pos,bufnr)
    pos=pos or nil
    bufnr=bufnr or vim.api.nvim_get_current_buf()

    local filetype=vim.bo.filetype

    local res,emb_suiteql=pcall(vim.treesitter.query.parse,filetype,'((template_string) @sql (#match? @sql "^`[^a-zA-z0-1]*([wW][iI][tT][hH]|[sS][eE][lL][eE][cC][tT]).*") (#offset! @sql 0 1 0 0))')

    if res==false then
        return nil
    end

    local root=get_root(bufnr,filetype)

    local nodes={}

    for id,node in emb_suiteql:iter_captures(root,bufnr,0,-1) do
        local name=emb_suiteql.captures[id]
        local range={node:range()}
        if name=='sql' and (pos==nil or pos_within_range(pos,range)) then
            table.insert(nodes,node)
        end
    end
    return nodes
end

M.getCurrentQuery=function()
    local currentWin=vim.api.nvim_get_current_win()

    local pos=vim.api.nvim_win_get_cursor(currentWin)

    return getSqlNodes(pos)

end

M.getFileQueries=function()
    return getSqlNodes()
end

return M
