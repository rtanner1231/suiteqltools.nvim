

local File=require('suiteqltools.util.fileutil')
local Common=require('suiteqltools.util.common')
local curllib=require('plenary.curl')
local Config=require('suiteqltools.config')

local P=function(tbl)
    return print(vim.inspect(tbl))
end

local M={}

--opts:
--token
--tokenSecret
--consumerKey
--consumerSecret
--url
--method
--account
--node testcli.js -t 12345 -k 23456 -c 34567 -s 45678 -r 361134_SB1 -u http://www.google.com -m POST -p '{"test": 1}'
local getAuthHeader=function(opts)

    local body=vim.json.encode(opts.body)

    local args={'-t',opts.token,'-k',opts.tokenSecret,'-c',opts.consumerKey,'-s',opts.consumerSecret,'-r',opts.account,'-u',"'"..opts.url.."'",'-m',opts.method,'-p',"'"..body.."'"}

    local argStr=''

    for _,v in pairs(args) do
        argStr=argStr..' '..v
    end

    local fullPath= debug.getinfo(1).source:sub(2)

    -- local dirPath=File.getDirFromPath(fullPath)
    --
    -- local pluginPath=string.gsub(dirPath,'/lua/suiteqltools/util','')
    --
    -- local scriptPath=File.pathcombine(pluginPath,'scripts/oauth/oauthheader.js')

    local scriptPath=Common.getScriptPath(fullPath,'/lua/suiteqltools/util','scripts/oauth/oauthheader.js')


    local command='node '..scriptPath..argStr

    --print(command)

    local result=vim.fn.system(command)

    local resultTable=vim.json.decode(result)



    return resultTable

    --local result=io.popen('node -v')

    -- local lines = {}
    --   for line in result:lines() do
    --     lines[#lines + 1] = vim.json.decode(line)
    --   end
    --
    --
    --
    -- return lines[1]

    -- local headerJob=job:new({
    --     --command="node ./oauth/oauthheader.js",
    --     command="node -v",
    --     --args=args
    -- })
    --
    -- local result=headerJob:sync()

    --local headerTable=vim.json.decode(result)

    --return headerTable;
end

----------------------------------------------------------------------------------


--opts:
--token
--tokenSecret
--consumerKey
--consumerSecret
--url
--method
--account
--body: table
local make_request=function(opts,cust_headers)

    local body=vim.json.encode(opts.body)

    local headers=getAuthHeader(opts)

    headers=vim.tbl_deep_extend('force',headers,cust_headers)

    local res=curllib.post(opts.url,{
        headers=headers,
        body=body
    })

    return res
end

M.netsuiteRequest=function(url,body,headers)

    local envVars=Config.options.queryRun.envVars
    -- local tokenSecret=os.getenv('NS_TOKEN_SECRET')
    -- local token=os.getenv('NS_TOKEN')
    -- local consumerKey=os.getenv('NS_CONSUMER_KEY')
    -- local consumerSecret=os.getenv('NS_CONSUMER_SECRET')
    -- local nsAccount=os.getenv('NS_ACCOUNT')
    local tokenSecret=os.getenv(envVars.tokenSecret)
    local token=os.getenv(envVars.tokenId)
    local consumerKey=os.getenv(envVars.consumerKey)
    local consumerSecret=os.getenv(envVars.consumerSecret)
    local nsAccount=os.getenv(envVars.nsAccount)


    return make_request({
        tokenSecret=tokenSecret,
        token=token,
        consumerKey=consumerKey,
        consumerSecret=consumerSecret,
        url=url,
        method='POST',
        account=nsAccount,
        body=body

    },headers)
end

return M

-- local function test()
--     connect('http://www.google.com',{})
-- end
--
-- test()
