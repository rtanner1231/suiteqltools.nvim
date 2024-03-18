local cmp=require('cmp')
local completionData=require('suiteqltools.completion.completionData')
local Common=require('suiteqltools.util.common')
local CompletionTreesitter=require('suiteqltools.completion.completionTreesitter')

local M={}

local P=function(tbl)
    print(vim.inspect(tbl))
end




--For the give table or alias, find the table name
--@param {string} currentTableAlias - The table or alias name under the cursor
--@param {{tbl: string, alias: string}[]} - queryTableAliases - The table aliases from the query
--@returns {string}
local findTableFromTableAlias=function(currentTableAlias,queryTableAliases)
    for _,v in ipairs(queryTableAliases) do
        if currentTableAlias==v.tbl or currentTableAlias==v.alias then
            return v.tbl
        end
    end
    return nil
end

local getTextBeforeCursor=function(line,col)

    local buf=vim.api.nvim_get_current_buf()

    local textArray=vim.api.nvim_buf_get_text(buf,0,0,line,col,{})

    return textArray
end


--Get the table or alias for the field
--@param {string[]} s - Array of lines of text before the cursor
--@returns {string} The table or alias name
local getTableOrAlias=function(s)
   local currentLine=s[#s]
   currentLine=Common.rTrim(currentLine)
   local result=''
   for c=#currentLine, 1, -1 do
    local char=string.sub(currentLine,c,c)
    if char ~= '.' then
      if string.match(char,"[%s,=]") then
        return result
      end
      result=char .. result
    end
   end
    return result
end

local getChars=function(textArray,chars)



    local result=''
    local count=0
    local foundChar=false
    local whitespace=0

    for t=#textArray, 1, -1 do
        local text=textArray[t]
        for c=#text, 1, -1 do
            local char=string.sub(text,c,c)
            if foundChar or not string.match(char,"%s") then
                result=char .. result
                foundChar=true
                count=count+1
                if count==chars then
                    return result, whitespace
                end
            else
                whitespace=whitespace+1
            end
        end
    end
    return result,whitespace
end

--Convert an array of string values into an array of completion items
local arrayTocompletionItems=function(arr)
    local result={}

    for _,v in ipairs(arr) do
        local ele={label=v,kind=cmp.lsp.CompletionItemKind.Value,detail='string'}
        table.insert(result,ele)
    end
    return result
end

local getTableCompletions=function()
    local tables=completionData.getTables()

    return arrayTocompletionItems(tables)
end

local getFieldCompletions=function(textArray,cursor)
    local tableAlias=getTableOrAlias(textArray)

    if tableAlias=='' or tableAlias==nil then
        return {}
    end

    local queryTableAlias=CompletionTreesitter.extractTableAlias(cursor)

    --P(queryTableAlias)

    if #queryTableAlias==0 then
        return {}
    end

    local resolvedTable=findTableFromTableAlias(tableAlias,queryTableAlias)

    if resolvedTable==nil then
        return {}
    end

    local fields=completionData.getFields(resolvedTable)

    return arrayTocompletionItems(fields)


end

local getCompletions=function(cursor)
    local col=cursor.col
    local row=cursor.line
    local textArray=getTextBeforeCursor(row,col)

    local chars,_=getChars(textArray,4)
    if chars:lower()=='from' or chars:lower()=='join' then
        return getTableCompletions()
    end

    local fieldChars,fieldWhitepace=getChars(textArray,1)

    if fieldWhitepace<=1 and fieldChars=='.' then
        return getFieldCompletions(textArray,cursor)
    end

    return {}

end

M.getCompletions=getCompletions

return M
