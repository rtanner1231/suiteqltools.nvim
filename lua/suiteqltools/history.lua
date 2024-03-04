local Path=require('plenary.path')
local File=require('suiteqltools.util.fileutil')
local Common=require('suiteqltools.util.common')
local Config=require('suiteqltools.config')

local M={}

local P=function(table)
    print(vim.inspect(table))
end

--get the full path to the history file
local getSuiteQLFilePath=function()
    local basePath=vim.fn.stdpath('data')
    local fname='suiteqlhistory.json'

    return Path:new(File.pathcombine(basePath,fname))
end


--write the history file from the history data
local writeHistoryFile=function(historyTable)
    local p=getSuiteQLFilePath()
    local jsonStr=vim.json.encode(historyTable)
    p:write(jsonStr,'w')
end

local removeConsecutiveSpaces=function(input_string)
    -- Pattern to match consecutive spaces
    local pattern = "%s+"
    
    -- Replace consecutive spaces with a single space
    local result = input_string:gsub(pattern, " ")
    
    return result
end

local getFirstChars=function(numChargs,str)
    --replace new lines with spaces
    str=Common.replace(str,'\n',' ')

    --the previous command may result in multiple consecutive spaces, remove them
    str=removeConsecutiveSpaces(str)


    if #str<=numChargs then
        return str
    end
    return str:sub(1,numChargs-3)..'...'
end

local readHistoryFile=function()
    local p=getSuiteQLFilePath()

    if not p:exists() then
        return {}
    end

    local contents=p:read()

    if #Common.trim(contents)==0 then
        return {}
    end

    return vim.json.decode(contents)
end

M.addToHistory=function(query)
    local queryOptions=Config.options.queryRun

    if not queryOptions.history then
        return
    end

    local date=vim.fn.strftime('%x %X')
    local display=getFirstChars(50,query)

    local entry={date=date,query=query,display=display}

    local historyData=readHistoryFile()

    table.insert(historyData,1,entry)

    if #historyData>queryOptions.historyLimit then
        --remove the last entry
        table.remove(historyData)
    end
    writeHistoryFile(historyData)
end

M.getHistoryData=function()
    return readHistoryFile()
end

local test=function()
    M.addToHistory('select * from something')
end

--test()

return M
