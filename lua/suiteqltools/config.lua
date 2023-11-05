

local M={}

local defaults={
    sqlFormatter={
        language='plsql',
        tabWidth=2,
        useTabs=false,
        keywordCase='preserve',
        indentStyle='standard',
        logicalOperatorNewline='before',
        expressionWidth=50,
        denseOperators=false,
        newLineBeforeSemicolon=false
    },
    queryRun={
        enabled=true,
        initialHeight="20%",
        fullHeight="95%",
        openFull=false,
        focusQueryOnRun=false,
        initialMode='table',
        jsonFormatSpace=4,
        envVars={
            consumerKey='NS_CONSUMER_KEY',
            consumerSecret='NS_CONSUMER_SECRET',
            tokenId='NS_TOKEN',
            tokenSecret='NS_TOKEN_SECRET',
            nsAccount='NS_ACCOUNT'
        }
    }
}

M.options=defaults

M.setup=function(opts)
    M.options=vim.tbl_deep_extend('force',defaults,opts)
end

return M

