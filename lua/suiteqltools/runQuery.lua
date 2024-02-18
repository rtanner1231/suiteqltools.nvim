local TokenConfig=require('suiteqltools.tokenconfig')
local Config=require('suiteqltools.config')
local NSConn=require('suiteqltools.util.nsconn')

local M={}

M.runQuery=function(query,page)
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
    local offset=(page-1)*pageSize
    local url='https://'..nsAccount..'.suitetalk.api.netsuite.com/services/rest/query/v1/suiteql?limit='..pageSize..'&offset='..offset
    local requestBody={q=query}
    local headers={Prefer='transient'}
    local result=NSConn.netsuiteRequest(url,requestBody,headers,tokens)

    local body=vim.json.decode(result.body)
    local hasMore=body.hasMore
    local total=body.totalResults

    if body.items~=nil then
        for _,v in ipairs(body.items) do
            v['links']=nil
        end
        return {
            success=true,
            items=body.items,
            hasMore=hasMore,
            total=total
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
            errorMessage=errorMessage,
            hasMore=hasMore,
            total=total
        }
    end
end

return M
