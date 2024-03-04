local Path=require('plenary.path')
local File=require('suiteqltools.util.fileutil')
local Enrypt=require('suiteqltools.util.encrypt')
local Dialog=require('suiteqltools.util.dialog')
local Common=require('suiteqltools.util.common')

local P=function(tbl)
    return print(vim.inspect(tbl))
end

local M={}


--get the path to the file to store the tokens
--returns a plenary Path object
local getConfigFilePath=function()
    local basePath=vim.fn.stdpath('data')
    local fname='sqc'

    return Path:new(File.pathcombine(basePath,fname))
end

---Profile
----profile: string
----account: string
----token: string
----tokenSecret: string
----consumerKey: string
----consumerSecret: string

---TokenStore: Object
----activeProfile: string
----profiles: Profile[]

--Read the contents of the token store file and decript it.
--returns TokenStore[]
local getConfigFileContents=function()
    local p=getConfigFilePath()

    if not p:exists() then
        return nil
    end

    local contents=p:read()

    if #Common.trim(contents)==0 then
        return nil
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
        --print(' \nconfig file saved')
    else
        print(' \nCount not write config: '..encryptedObj.errorMessage)
    end
end

--Find the profile in the config
--if found return the profile and index, otherwise return 0,nil
--
local findProfile=function(config,profile)

    if config==nil or config.profiles==nil then
        return 0,nil
    end

    for k,v in pairs(config.profiles) do
        if v.profile==profile then
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

    local profile=vim.fn.input('Profile Name ')
    if nilOrEmpty(profile) then
        return nil
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

    return {
        profile=profile,
        account=account,
        token=token,
        tokenSecret=tokenSecret,
        consumerKey=consumerKey,
        consumerSecret=consumerSecret
    }
end

--prompt the user for tokens
--either add or update existing tokens
local setTokens=function()
    local inputs=getInputs()
    if inputs==nil then
        return
    end

    local config=getConfigFileContents()

    if config==nil then
        config={
            activeProfile= inputs.profile,
            profiles={}
        }
    end

    local idx,profileObj=findProfile(config,inputs.profile)

    if profileObj==nil then
        profileObj={}
    end

    profileObj.profile=inputs.profile
    profileObj.account=inputs.account
    profileObj.token=inputs.token
    profileObj.tokenSecret=inputs.tokenSecret
    profileObj.consumerKey=inputs.consumerKey
    profileObj.consumerSecret=inputs.consumerSecret



    if idx>0 then
        config.profiles[idx]=profileObj
    else
        table.insert(config.profiles,profileObj)
    end

    writeConfigFile(config)


end

local showProfilePicker=function(message,callback)
    local activeProfile,profileList=M.getProfileList()

    if profileList==nil then
        print('config file not found')
        return
    end

    local options={}

    for _,v in ipairs(profileList) do
        local profileName=v
        if v==activeProfile then
            profileName=profileName..' *'
        end
        local option={option_text=profileName,value=v}
        table.insert(options,option)
    end

    Dialog.option(message,options,callback)

end

--add a profile to the stored tokens
M.addProfile=function()
    setTokens()
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

    if config.activeProfile==nil then
        print('no active profile set')
        return nil
    end

    local _,activeConfig=findProfile(config,config.activeProfile)

    if activeConfig~=nil then
        return fromFoundConfig(activeConfig)
    else
        print('Profile '..config.activeProfile..' not found.')
        return nil
    end

end

M.removeProfile=function(profile)

    if(profile==nil) then
        return
    end

    local config=getConfigFileContents()

    if config==nil then
        print('no config file found')
        return
    end

    if profile==config.activeProfile then
        print('cannot remove active profile')
        return
    end

    local idx,_=findProfile(config,profile)

    if idx==0 then
        print('Profile '..profile..' not found.')
        return
    end

    table.remove(config.profiles,idx)
    writeConfigFile(config)

    print('Profile '..profile..' removed')

end

--Get a list of all profiles
--returns {string},{string[]} Active profile, profile list
M.getProfileList=function()
    local list={}

    local config=getConfigFileContents()

    if config==nil then
        return nil,nil
    end

    for _,v in ipairs(config.profiles) do
        table.insert(list,v.profile)
    end

    return config.activeProfile,list
end

--set the active profile
--if the profile does not exist, does nothing
M.setActiveProfile=function(profile)

    if profile==nil then
        return
    end

    local config=getConfigFileContents()

    if config==nil then
        print('no config file found')
        return
    end

    local _,configObj=findProfile(config,profile)

    if configObj==nil then
        print('Profile '..profile..' not found.')
        return
    end

    config.activeProfile=profile

    writeConfigFile(config)
end

M.showSelectProfilePicker=function()
    showProfilePicker('Select profile to use',M.setActiveProfile)
end

M.showDeleteProfilePicker=function()
    showProfilePicker('Select profile to delete',M.removeProfile)
end

M.getActiveProfile=function()
    local config=getConfigFileContents()
    if config==nil then
        return 'No Active Profile'
    end

    return config.activeProfile
end

return M
