local File=require('suiteqltools.util.fileutil')

local M={}

M.getScriptPath=function(currentFilePath,localFilePath,localPathToScript)
    
    local dirPath=File.getDirFromPath(currentFilePath)

    local pluginPath=string.gsub(dirPath,localFilePath,'')

    return File.pathcombine(pluginPath,localPathToScript)
end


local strMagic = "([%^%$%(%)%%%.%[%]%*%+%-%?])"

M.replace=function(strTxt,strOld,strNew,intNum)
  strOld = tostring(strOld or ""):gsub(strMagic,"%%%1")
  return tostring(strTxt or ""):gsub(strOld,function() return strNew end,tonumber(intNum))
end

M.splitStr=function(str,sep)
    local ret={}
    for s in string.gmatch(str,'([^'..sep..']+)') do
        table.insert(ret,s)
    end
    return ret
end
    local nextChar=function(s,i)
        if s:len()>i then
            return s:sub(i+1,i+1)
        else
            return ''
        end
    end

--Nested string interpolation makes this difficult to do with regex
--There is probably a better way to do this
--Return a list of string interpolation objects in string q
M.getStringInterpolation=function(q)
    local ret={}
    local retSet={}
    local stackDepth=0
    local startIdx=0
    local isComment=false



    for i=1,#q do
        local c=q:sub(i,i)
        if isComment==false and stackDepth==0 and c=='$' and nextChar(q,i)=='{' then
            startIdx=i
            stackDepth=1
        end
        if stackDepth>0 and i>startIdx+1 and c=='{' then
            stackDepth=stackDepth+1
        end
        if(stackDepth==0 and c=='-' and nextChar(q,i)=='-') then
            isComment=true
        end

        if isComment and c=='\n' then
            isComment=false
        end

        if stackDepth>0 and c=='}' then
            stackDepth=stackDepth-1
            if stackDepth==0 then
                local foundVal=q:sub(startIdx,i)
                if retSet[foundVal]==nil then
                    table.insert(ret,foundVal)
                    retSet[foundVal]=true
                end

            end
        end
    end
    return ret
    
end

--trim whitespace at the start and end of the passed in string
M.trim=function(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
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
        and c=${ name?" n3=='${name}'":'' }
        and n='${name}'
        --${name}=bill
        --${ids.join(',')}=3,4,5
        --${c+1}=6
    ]]
    -- local c=nextChar(q,84)
    -- print(c)
     local res=M.getStringInterpolation(q)
     print(vim.inspect(res))
end

M.stringContains=function(mainString, subString)
    return mainString:find(subString, 1, true) ~= nil
end

--test()

return M
