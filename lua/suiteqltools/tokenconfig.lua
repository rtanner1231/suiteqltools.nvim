local Path=require('plenary.path')
local File=require('suiteqltools.util.fileutil')
local Enrypt=require('suiteqltools.util.encrypt')


local M={}


--get the path to the file to store the tokens
--returns a plenary Path object
local getConfigFilePath=function()
    local basePath=vim.fn.stdpath('data')
    local fname='sqc'

    return Path:new(File.pathcombine(basePath,fname))
end

--trim whitespace at the start and end of the passed in string
local trim=function(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---TokenStore: Object
----account: string
----token: string
----tokenSecret: string
----consumerKey: string
----consumerSecret: string
----isDefault?: boolean
----cwd?: string

--Read the contents of the token store file and decript it.
--returns TokenStore[]
local getConfigFileContents=function()
    local p=getConfigFilePath()

    if not p:exists() then
        return {}
    end

    local contents=p:read()

    if #trim(contents)==0 then
        return {}
    end

    --decript
    local decryptedObj=Enrypt.decrypt(contents)
    -- print('before json')
    -- local a=vim.json.decode(decryptedObj.result)
    -- P(a)
    if decryptedObj.success==true then
        return vim.json.decode(decryptedObj.result)
    else
        print('Could not open token config file: '..decryptedObj.errorMessage)
        return nil
    end
end

--encrypt and write the config file
local writeConfigFile=function(config)
    local p=getConfigFilePath()
    local jsonStr=vim.json.encode(config)
    local encryptedObj=Enrypt.encrypt(jsonStr)
    if encryptedObj.success==true then
        p:write(encryptedObj.result,'w')
        print(' \nconfig file saved')
    else
        print(' \nCount not write config: '..encryptedObj.errorMessage)
    end
end


--find the default config from the list of configs
--Return the index the config was found at and the found config
--If no config is found, returns 0, nil
--@param config: TokenStore[]
--@returns number, TokenStore
local findDefault=function(config)
    for k,v in pairs(config) do
        if v.isDefault==true then
            return k,v
        end
    end

    return 0,nil
end

--find the project config from the list of configs, based on the current cwd
--Return the index the config was found at and the found config
--If no config is found, returns 0, nil
--@param config: TokenStore[]
--@returns number, TokenStore
local findLocal=function(config)
    local cwd=vim.fn.getcwd()

    for k,v in pairs(config) do
        if not v.isDefault and v.cwd==cwd then
            return k,v
        end
    end

    return 0,nil

end


--Get the token inputs from the user
local getInputs=function()

    local nilOrEmpty=function(val)
        return val==nil or val=='' or val==' '
    end

    local account=vim.fn.input('Account ')
    if nilOrEmpty(account) then
        return nil
    end
    local token=vim.fn.inputsecret('Token ')
    if nilOrEmpty(token) then
        return nil
    end
    local tokenSecret=vim.fn.inputsecret('Token Secret ')
    if nilOrEmpty(tokenSecret) then
        return nil
    end
    local consumerKey=vim.fn.inputsecret('Consumer Key ')
    if nilOrEmpty(consumerKey) then
        return nil
    end
    local consumerSecret=vim.fn.inputsecret('Consumer Secret ')
    if nilOrEmpty(consumerSecret) then
        return nil
    end

    return {account=account,
        token=token,
        tokenSecret=tokenSecret,
        consumerKey=consumerKey,
        consumerSecret=consumerSecret}
end

--prompt the user for tokens
--either add or update existing tokens
local setTokens=function(defaultValue,findFunction)
    local inputs=getInputs()
    if inputs==nil then
        return
    end

    local config=getConfigFileContents()

    if config==nil then
        config={}
    end

    local idx,configObj=findFunction(config)

    if configObj==nil then
        configObj=defaultValue
    end

    configObj.account=inputs.account
    configObj.token=inputs.token
    configObj.tokenSecret=inputs.tokenSecret
    configObj.consumerKey=inputs.consumerKey
    configObj.consumerSecret=inputs.consumerSecret

    if idx>0 then
        config[idx]=configObj
    else
        table.insert(config,configObj)
    end

    writeConfigFile(config)


end


--Set the default tokens
M.setDefaultTokens=function()
    setTokens({isDefault=true},findDefault)
end

--set the project specific tokens
M.setProjectTokens=function()
    local cwd=vim.fn.getcwd()
    setTokens({cwd=cwd},findLocal)
end

--delete the token settings file
M.resetTokens=function()
    local doDelete=vim.fn.confirm('Are you sure you want to remove all saved tokens?','&yes\n&no',2)
    if doDelete==2 then
        return
    end
    local p=getConfigFilePath()

    p:rm()
end

--returns true if the config file exists
M.areTokensSetup=function()
    local p=getConfigFilePath()
    return p:exists()
end

--Get tokens for the current project.
--Looks first for project specific tokens, if not found, looks for default
--Returns nil if no tokens found
M.getTokens=function()

    local fromFoundConfig=function(foundConfig)
        return {
            account=foundConfig.account,
            token=foundConfig.token,
            tokenSecret=foundConfig.tokenSecret,
            consumerKey=foundConfig.consumerKey,
            consumerSecret=foundConfig.consumerSecret
        }
    end

    local config=getConfigFileContents()

    if config==nil then
        return nil
    end

    local _,localConfig=findLocal(config)

    if localConfig~=nil then
        return fromFoundConfig(localConfig)
    end

    local _,defaultConfig=findDefault(config)
    if defaultConfig~=nil then
        return fromFoundConfig(defaultConfig)
    end
    return nil
end

return M
