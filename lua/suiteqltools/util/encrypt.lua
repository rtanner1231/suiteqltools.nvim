local Common=require('suiteqltools.util.common')
local QueryConfig=require('suiteqltools.config').options.queryRun

local M={}

local getScriptPath=function()
    local fullPath= debug.getinfo(1).source:sub(2)
    local scriptPath=Common.getScriptPath(fullPath,'/lua/suiteqltools/util','scripts/crypto/encrypt.js')
    return scriptPath
end

local getKey=function()
    local key=os.getenv(QueryConfig.envVars.encryptKey)
    return key
end

local makeResult=function(success,result,errorMessage)
    return {success=success,result=result,errorMessage=errorMessage}
end

M.encrypt=function(value)
    local scriptPath=getScriptPath()
    local key=getKey()
    if key==nil then
        return makeResult(false,nil,'No key found at '..QueryConfig.envVars.encryptKey..' env var.')
    end

    local command='node '..scriptPath..' --type encrypt --key '..key.." --value '"..value.."'"
    local result=vim.fn.system(command)

    local parsedResult=vim.json.decode(result)
    if parsedResult.success==true then
        return makeResult(true,parsedResult.value,'')
    else
        return makeResult(false,nil,parsedResult.errorMessage)
    end
end

M.decrypt=function(value)
    local scriptPath=getScriptPath()
    local key=getKey()
    if key==nil then
        return makeResult(false,nil,'No key found at '..QueryConfig.envVars.encryptKey..' env var.')
    end

    local command='node '..scriptPath..' --type decrypt --key '..key..' --value '..value
    local result=vim.fn.system(command)
    local parsedResult=vim.json.decode(result)
    if parsedResult.success==true then
        return makeResult(true,parsedResult.value,'')
    else
        return makeResult(false,nil,parsedResult.errorMessage)
    end
end

return M
