local TreesitterLookup=require('suiteqltools.util.treesitter_lookup')
local Common=require('suiteqltools.util.common')
local Config=require('suiteqltools.config')
local QUI=require('suiteqltools.queryui')
local RunQuery=require('suiteqltools.runQuery')

local M={}

local P=function(tbl)
    return print(vim.inspect(tbl))
end
--
--@param query: string
--@param replaceTbl: {replace: string,with: string}[]
--@returns string
local replaceMatches=function(query,replaceTbl)
    for _,v in pairs(replaceTbl) do
        query=Common.replace(query,v.replace,v.with)
    end
    return query
end

--@param Matches: string[]
--@Returns {replace: string,with: string}[]
local splitReplaceMatches=function(matches)
    local ret={ }
    for _,v in pairs(matches) do
        local splitTbl=Common.splitStr(v,'=')
        if #splitTbl>1 then
            local replace=''
            for i=1,#splitTbl-1 do
                if replace:len()>0 then
                    replace=replace..'='
                end
                replace=replace..splitTbl[i]
            end
            table.insert(ret,{replace=replace,with=splitTbl[#splitTbl]})
        end
    end
    return ret
end

local getReplaceMatches=function(query)
    local matchFunc=string.gmatch(query,'%-%-[^%$]*(%${[^=]*=.-)\n')
    local ret={}
    for v in matchFunc do
        table.insert(ret,v)
    end

    return ret
end

local replaceStringInterpolation=function(query)
    local rMatches=getReplaceMatches(query)
    local splitRepMatches=splitReplaceMatches(rMatches)
    return replaceMatches(query,splitRepMatches)
    
end

local validateQuery=function(query)
    

    -- local ret={}
    -- local retSet={}
    --
    -- local queryToTest=query..'\n'
    --
    -- --find any remaining ${...} which do not appear after a -- in a line
    -- for match in queryToTest:gmatch("[^%$\n]*%${[^}]*}.-\n") do
    --     if not match:match('%-%-[^%$]*%${[^}]*}') then
    --         for v in match:gmatch('(%${[^}]*})') do
    --             if retSet[v]==nil then
    --                 retSet[v]=true
    --                 table.insert(ret,v)
    --             end
    --         end
    --     end
    -- end
    local ret=Common.getStringInterpolation(query)

    return ret
end

local getQueryText=function()
    local nodes=TreesitterLookup.getCurrentQuery()

    if #nodes==0 then
        return nil
    end

    local bufnr=vim.api.nvim_get_current_buf()

    local node=nodes[1]

    local sql_text=vim.treesitter.get_node_text(node,bufnr)


    --remove template quotes from start and end
    local trimmed_text=string.sub(sql_text,2,string.len(sql_text)-1)

    return {node:range()},trimmed_text
end

M.currentPage=1
M.total=0
M.currentQuery=''
M.hasMore=false

local runQuery=function(query)
    --local nsAccount=os.getenv('NS_ACCOUNT')
    
    local queryResult=RunQuery.runQuery(query,M.currentPage)

    if queryResult==nil then
        return
    end

    M.hasMore=queryResult.hasMore
    M.total=queryResult.total

    if queryResult.success then
        return {
            success=true,
            items=queryResult.items
        }
    else
        return {
            success=false,
            error=queryResult.errorMessage
        }
    end



end

local currentQueryUI=nil

local renderQueryResult=function(queryResult)
    if queryResult.success==false then
        print(queryResult.errorMessage)
        return
    end

    if currentQueryUI==nil or not currentQueryUI:isValid() then
        currentQueryUI=QUI.QueryUI:new()
    end

    --currentQueryUI=QUI.QueryUI:new(queryResult.items)
    currentQueryUI:setItems(queryResult.items,M.currentPage)

    currentQueryUI:show()

    local totalPages=math.ceil(M.total/Config.options.queryRun.pageSize)

    print('Page '..M.currentPage..' of '..totalPages )
end


local addMissingStringInter=function(bufnr,range,values)
     --get last line in query
    local lastLineText=vim.fn.getline(range[3]+1)

    local indentedValues={}

    local indent=string.rep(' ',range[2])

    for _,v in ipairs(values) do
        table.insert(indentedValues,indent..v)
    end

    --get the rest of the last line in the query
    local restOfLine=vim.api.nvim_buf_get_text(bufnr,range[3],range[4]-1,range[3],#lastLineText,{})
    
    --P({range=range,restOfLine=restOfLine,lastLineText=lastLineText,len=#lastLineText})
    vim.api.nvim_buf_set_text(bufnr,range[3],range[4]-1,range[3],#lastLineText,{})


    local startRow=range[3]+1
    local endRow=startRow+#values+1
    table.insert(indentedValues,indent..restOfLine[1])

    --P({startRow=startRow,endRow=endRow,values=indentedValues})

    vim.api.nvim_buf_set_lines(bufnr,startRow,startRow,false,indentedValues)
end

M.runCurrentQuery=function()
    local range,query=getQueryText()

    if query==nil then
        print('No query under cursor')
        return
    end

    local fixedQuery=replaceStringInterpolation(query)

    --P({fixedQuery=fixedQuery})

    local remainingStringInterpolations=validateQuery(fixedQuery)

    if #remainingStringInterpolations>0 then
        local errorString='Add string interpolation comments:\n'
        local missingstringInter={}
        for _,v in pairs(remainingStringInterpolations) do
            local missingValue='--'..v..'='
            errorString=errorString..missingValue..'<value>'..'\n'
            table.insert(missingstringInter,missingValue)
        end
        print(errorString)
        local doAutoAdd=vim.fn.confirm('Autoadd?','&Yes\n&No','&yes')
        if doAutoAdd==1 then
            addMissingStringInter(0,range,missingstringInter)
        end
        return
    end

    --local q='select top 50 * from ('..fixedQuery..')'
    local q=fixedQuery
    M.currentQuery=q
    M.currentPage=1

    local result=runQuery(q)
    if result~=nil then
        renderQueryResult(result)
    end

end

M.nextPage=function()
    if currentQueryUI==nil or currentQueryUI:isValid()==false or M.hasMore==false then
        return
    end

    M.currentPage=M.currentPage+1
    local result=runQuery(M.currentQuery)
    renderQueryResult(result)
end

M.prevPage=function()
    if currentQueryUI==nil or currentQueryUI:isValid()==false or M.currentPage==1 then
        return
    end

    M.currentPage=M.currentPage-1
    local result=runQuery(M.currentQuery)
    renderQueryResult(result)
end

M.toggleFullScreen=function()
    if currentQueryUI then
        currentQueryUI:toggleFullScreen()
    end
end

M.toggleDisplayMode=function()
    if currentQueryUI then
        currentQueryUI:toggleDisplayMode()
    end
end

M.closeQuery=function()
    if currentQueryUI then
        currentQueryUI:close()
    end
end

M.sortColumn=function()
    if currentQueryUI then
        currentQueryUI:sort()
    end
end

local test=function()
    local q=[[
        select
        *
        from
        location
        where
        name='${name}'
        and
        id in (${ids.join(',')})
        and
        otherid=${c+1}
    ]]
    local a= "select * from location where name='${name}'"
    --a:gmatch("[^%$\n]*%${[^}]*}.-\n") 
    local res=validateQuery(q)
    P(res)
end

local test2=function()
    local q=[[
        select
        *
        from
        location
        where
        name='${name}'
        and
        id in (${ids.join(',')})
        and
        otherid=${c+1}
        --and c=${ccc}
        --${name}=bill
        --${ids.join(',')}=3,4,5
        --${c+1}=6
    ]]

    local rm=getReplaceMatches(q)
    local sm=splitReplaceMatches(rm)
    local q2=replaceMatches(q,sm)
    local valRes=validateQuery(q2)

    P(valRes)
end

local test3=function()
    local q=[[
        select
        *
        from
        location
        where
        name='${name}'
        and
        id in (${ids.join(',')})
        and
        otherid=${c+1}
        --and c=${ccc}
        --${name}=bill
        --${ids.join(',')}=3,4,5
        --${c+1}=6
    ]]
    local input=[[
        ${a}
        --aaa${b}
        asdf
        bbb${c}--
    ]]
    local i=1
    -- for match in input:gmatch("^[^%$]*%${[^}]*}.-\n") do
    for match in q:gmatch("[^%$\n]*%${[^}]*}.-\n") do
        --print(match)
        if not match:match('%-%-[^%$]*%${[^}]*}') then
            for v in match:gmatch('(%${[^}]*})') do
                print(v)
            end
        end
    end
end



--test()

return M
