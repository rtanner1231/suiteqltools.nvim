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

return M
