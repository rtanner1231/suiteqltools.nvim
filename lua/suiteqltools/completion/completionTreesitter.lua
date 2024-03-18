local P=function(tbl)
    print(vim.inspect(tbl))
end

local M={}

local getAllText=function()
    local buf=vim.api.nvim_get_current_buf()

    local textArray=vim.api.nvim_buf_get_text(buf,0,0,-1,-1,{})

    return textArray

end

local joinText=function(textArray)
    local result=''
    for _,v in ipairs(textArray) do
        result=result ..' '.. v
    end
    return result

end

local function removeDot(array, row, column)
    -- Check if the row index is valid
    if row <= #array and row > 0 then
        local str = array[row]
        local index = 1
        local dotIndex = nil

        -- Find the first dot before the specified column index
        while index <= column and index <= #str do
            if str:sub(index, index) == '.' then
                dotIndex = index
            end
            index = index + 1
        end

        -- If a dot was found, remove it
        if dotIndex then
            array[row] = str:sub(1, dotIndex - 1) .. str:sub(dotIndex + 1)
        end
    end

    return array
end

local extractTableAlias=function(cursor)

    local allText=getAllText()

    allText=removeDot(allText,cursor.row,cursor.col)


    local q=joinText(allText)

    local lang_tree=vim.treesitter.get_string_parser(q,'sql')
    local syntax_tree=lang_tree:parse()
    local root=syntax_tree[1]:root()

    local query=vim.treesitter.query.parse('sql',[[
        (relation (object_reference name: (identifier) @tbl) alias: (identifier)? @alias)
        ]])

    local results={}

    for _,captures,metadata in query:iter_matches(root,q) do

        local tbl=vim.treesitter.get_node_text(captures[1],q)
        local alias=nil
        if #captures>1 then
            alias=vim.treesitter.get_node_text(captures[2],q)
        end

        table.insert(results,{tbl=tbl, alias=alias})

        
    end

    return results


end

M.extractTableAlias=extractTableAlias

return M
