local TreesitterLookup=require('suiteqltools.util.treesitter_lookup')
local Common=require('suiteqltools.util.common')
local Config=require('suiteqltools.config')
local NSConn=require('suiteqltools.util.nsconn')
local QUI=require('suiteqltools.queryui')
local TokenConfig=require('suiteqltools.tokenconfig')

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
        if #splitTbl==2 then
            table.insert(ret,{replace=splitTbl[1],with=splitTbl[2]})
        end
    end
    return ret
end

local getReplaceMatches=function(query)
    local matchFunc=string.gmatch(query,'%-%-[^%$]*(%${[^}]*}=.-)\n')
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
    

    local ret={}
    local retSet={}

    --find any remaining ${...} which do not appear after a -- in a line
    for match in query:gmatch("[^%$\n]*%${[^}]*}.-\n") do
        if not match:match('%-%-[^%$]*%${[^}]*}') then
            for v in match:gmatch('(%${[^}]*})') do
                if retSet[v]==nil then
                    retSet[v]=true
                    table.insert(ret,v)
                end
            end
        end
    end
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

    return trimmed_text
end

M.currentPage=1
M.total=0
M.currentQuery=''
M.hasMore=false

local runQuery=function(query)
    --local nsAccount=os.getenv('NS_ACCOUNT')

    if TokenConfig.areTokensSetup()==false then
        print('Tokens not found.  Use command SuiteQL SetDefaultTokens')
        return
    end

    local tokens=TokenConfig.getTokens()

    if tokens==nil then
        print('error retrieving tokens')
        return
    end

    --local nsAccount=os.getenv(Config.options.queryRun.envVars.nsAccount)
    local nsAccount=tokens.account

    nsAccount=string.gsub(nsAccount,'_','-')
    nsAccount=string.lower(nsAccount)

    local pageSize=Config.options.queryRun.pageSize
    local offset=(M.currentPage-1)*pageSize
    local url='https://'..nsAccount..'.suitetalk.api.netsuite.com/services/rest/query/v1/suiteql?limit='..pageSize..'&offset='..offset
    local requestBody={q=query}
    local headers={Prefer='transient'}
    local result=NSConn.netsuiteRequest(url,requestBody,headers,tokens)

    local body=vim.json.decode(result.body)
    M.hasMore=body.hasMore
    M.total=body.totalResults

    if body.items~=nil then
        for _,v in ipairs(body.items) do
            v['links']=nil
        end
        return {
            success=true,
            items=body.items
        }
    else
        local errorMessage=''

        if body['o:errorDetails'] then
            for _,v in ipairs(body['o:errorDetails']) do
                errorMessage=errorMessage..v['detail']
            end
        else
            errorMessage='Unknown error'
        end

        return {
            success=false,
            errorMessage=errorMessage
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




M.runCurrentQuery=function()
    local query=getQueryText()

    if query==nil then
        print('No query under cursor')
        return
    end

    local fixedQuery=replaceStringInterpolation(query)

    --P({fixedQuery=fixedQuery})

    local remainingStringInterpolations=validateQuery(fixedQuery)

    if #remainingStringInterpolations>0 then
        local errorString='Add string interpolation comments:\n'
        for _,v in pairs(remainingStringInterpolations) do
            errorString=errorString..'--'..v..'=<value>\n'
        end
        print(errorString)
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

    local query='select * from location'
    local q='select top 10 * from ('..query..')'
    local result=runQuery(q)
    renderQueryResult(result)
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



--test2()

return M
